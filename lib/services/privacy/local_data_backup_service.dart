import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/database/database_helper.dart';

enum LocalDataBackupErrorCode {
  invalidFile('invalid_file'),
  unsupportedSchema('unsupported_schema'),
  integrityFailure('integrity_failure'),
  missingTables('missing_tables'),
  restoreFailure('restore_failure');

  final String value;

  const LocalDataBackupErrorCode(this.value);
}

class LocalDataBackupException implements Exception {
  final LocalDataBackupErrorCode code;
  final String message;
  final Object? cause;
  final bool? rollbackSucceeded;

  const LocalDataBackupException({
    required this.code,
    required this.message,
    this.cause,
    this.rollbackSucceeded,
  });

  @override
  String toString() => message;
}

class LocalDataBackupValidation {
  final int schemaVersion;
  final int fileSizeBytes;
  final int foreignKeyViolationCount;
  final Set<String> tableNames;

  const LocalDataBackupValidation({
    required this.schemaVersion,
    required this.fileSizeBytes,
    required this.foreignKeyViolationCount,
    required this.tableNames,
  });
}

class LocalDataBackupArtifact {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final LocalDataBackupValidation validation;
  final Directory _workingDirectory;

  const LocalDataBackupArtifact({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.validation,
    required Directory workingDirectory,
  }) : _workingDirectory = workingDirectory;

  Future<Uint8List> readBytes() => File(filePath).readAsBytes();

  Future<void> dispose() async {
    if (await _workingDirectory.exists()) {
      await _workingDirectory.delete(recursive: true);
    }
  }
}

class LocalDataRestoreResult {
  final LocalDataBackupValidation candidateValidation;
  final LocalDataBackupValidation restoredValidation;
  final bool migrationApplied;

  const LocalDataRestoreResult({
    required this.candidateValidation,
    required this.restoredValidation,
    required this.migrationApplied,
  });
}

typedef TemporaryDirectoryLoader = Future<Directory> Function();

class LocalDataBackupService {
  static const int minimumSupportedSchemaVersion = 12;
  static const int maximumBackupBytes = 512 * 1024 * 1024;

  static const Set<String> _baselineRequiredTables = {
    'decks',
    'questions',
    'study_records',
    'user_stats',
    'sources',
    'source_chunks',
    'knowledge_points',
    'knowledge_point_sources',
    'learning_sessions',
    'interview_turns',
    'learning_agent_states',
    'learning_agent_trace_events',
  };

  static const Set<String> _currentRequiredTables = {
    ..._baselineRequiredTables,
    'knowledge_point_prerequisites',
    'tutor_turns',
    'programming_exercises',
    'programming_exercise_attempts',
    'programming_review_actions',
    'product_events',
  };

  final DatabaseHelper _databaseHelper;
  final TemporaryDirectoryLoader _temporaryDirectoryLoader;
  final DateTime Function() _clock;
  int _operationSequence = 0;

  LocalDataBackupService({
    required DatabaseHelper databaseHelper,
    TemporaryDirectoryLoader? temporaryDirectoryLoader,
    DateTime Function()? clock,
  })  : _databaseHelper = databaseHelper,
        _temporaryDirectoryLoader =
            temporaryDirectoryLoader ?? getTemporaryDirectory,
        _clock = clock ?? DateTime.now;

  Future<LocalDataBackupArtifact> createBackup() async {
    await _requireFileBackedDatabasePath();
    final database = await _databaseHelper.database;
    final createdAt = _clock().toUtc();
    final workingDirectory = await _createWorkingDirectory('backup');
    final fileName = 'anchor-learning-backup-v${DatabaseHelper.schemaVersion}-'
        '${_compactTimestamp(createdAt)}.db';
    final snapshotPath = p.join(workingDirectory.path, fileName);

    try {
      await _vacuumInto(database, snapshotPath);
      final validation = await validateBackup(snapshotPath);
      if (validation.schemaVersion != DatabaseHelper.schemaVersion) {
        throw const LocalDataBackupException(
          code: LocalDataBackupErrorCode.unsupportedSchema,
          message: '备份快照版本异常，请稍后重试。',
        );
      }
      return LocalDataBackupArtifact(
        fileName: fileName,
        filePath: snapshotPath,
        createdAt: createdAt,
        validation: validation,
        workingDirectory: workingDirectory,
      );
    } catch (_) {
      await _deleteDirectoryBestEffort(workingDirectory);
      rethrow;
    }
  }

  Future<LocalDataBackupValidation> validateBackup(String filePath) async {
    final file = File(filePath);
    final fileSize = await _validateFileEnvelope(file);
    Database? database;
    try {
      database = await _databaseHelper.effectiveDatabaseFactory.openDatabase(
        file.path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      return await _validateOpenDatabase(
        database,
        fileSizeBytes: fileSize,
        requiredTables: _baselineRequiredTables,
        minimumSchemaVersion: minimumSupportedSchemaVersion,
        maximumSchemaVersion: DatabaseHelper.schemaVersion,
      );
    } on LocalDataBackupException {
      rethrow;
    } catch (error) {
      throw LocalDataBackupException(
        code: LocalDataBackupErrorCode.invalidFile,
        message: '无法读取该备份文件。',
        cause: error,
      );
    } finally {
      await database?.close();
    }
  }

  Future<LocalDataRestoreResult> restoreBackup(String sourcePath) async {
    final databasePath = await _requireFileBackedDatabasePath();
    final workingDirectory = await _createWorkingDirectory('restore');
    final stagedPath = p.join(workingDirectory.path, 'candidate.db');
    final rollbackPath = p.join(workingDirectory.path, 'rollback.db');
    var replacementStarted = false;

    try {
      await File(sourcePath).copy(stagedPath);
      final candidateValidation = await validateBackup(stagedPath);

      final currentDatabase = await _databaseHelper.database;
      try {
        await _vacuumInto(currentDatabase, rollbackPath);
      } catch (error) {
        throw LocalDataBackupException(
          code: LocalDataBackupErrorCode.restoreFailure,
          message: '无法创建恢复前快照，原数据未修改。',
          cause: error,
          rollbackSucceeded: true,
        );
      }

      await _databaseHelper.close();
      await _deleteSidecarFiles(databasePath);
      replacementStarted = true;
      await File(stagedPath).copy(databasePath);

      final restoredDatabase = await _databaseHelper.database;
      final restoredFileSize = await File(databasePath).length();
      final restoredValidation = await _validateOpenDatabase(
        restoredDatabase,
        fileSizeBytes: restoredFileSize,
        requiredTables: _currentRequiredTables,
        minimumSchemaVersion: DatabaseHelper.schemaVersion,
        maximumSchemaVersion: DatabaseHelper.schemaVersion,
      );
      return LocalDataRestoreResult(
        candidateValidation: candidateValidation,
        restoredValidation: restoredValidation,
        migrationApplied:
            candidateValidation.schemaVersion != DatabaseHelper.schemaVersion,
      );
    } on LocalDataBackupException catch (error) {
      if (!replacementStarted ||
          error.code != LocalDataBackupErrorCode.restoreFailure) {
        if (!replacementStarted) rethrow;
      }
      final rollbackSucceeded = replacementStarted
          ? await _rollback(databasePath, rollbackPath)
          : true;
      throw LocalDataBackupException(
        code: LocalDataBackupErrorCode.restoreFailure,
        message: rollbackSucceeded ? '恢复失败，已自动恢复原有数据。' : '恢复失败，且无法自动恢复原有数据。',
        cause: error,
        rollbackSucceeded: rollbackSucceeded,
      );
    } catch (error) {
      final rollbackSucceeded = replacementStarted
          ? await _rollback(databasePath, rollbackPath)
          : true;
      throw LocalDataBackupException(
        code: LocalDataBackupErrorCode.restoreFailure,
        message: rollbackSucceeded ? '恢复失败，已自动恢复原有数据。' : '恢复失败，且无法自动恢复原有数据。',
        cause: error,
        rollbackSucceeded: rollbackSucceeded,
      );
    } finally {
      await _deleteDirectoryBestEffort(workingDirectory);
    }
  }

  Future<int> _validateFileEnvelope(File file) async {
    if (!await file.exists()) {
      throw const LocalDataBackupException(
        code: LocalDataBackupErrorCode.invalidFile,
        message: '备份文件不存在。',
      );
    }
    final fileSize = await file.length();
    if (fileSize < 16 || fileSize > maximumBackupBytes) {
      throw const LocalDataBackupException(
        code: LocalDataBackupErrorCode.invalidFile,
        message: '备份文件为空、过大或格式不完整。',
      );
    }

    final handle = await file.open();
    try {
      final header = await handle.read(16);
      final expected = Uint8List.fromList(utf8.encode('SQLite format 3\u0000'));
      if (!_bytesEqual(header, expected)) {
        throw const LocalDataBackupException(
          code: LocalDataBackupErrorCode.invalidFile,
          message: '所选文件不是 SQLite 备份。',
        );
      }
    } finally {
      await handle.close();
    }
    return fileSize;
  }

  Future<LocalDataBackupValidation> _validateOpenDatabase(
    Database database, {
    required int fileSizeBytes,
    required Set<String> requiredTables,
    required int minimumSchemaVersion,
    required int maximumSchemaVersion,
  }) async {
    final schemaRows = await database.rawQuery('PRAGMA user_version');
    final schemaVersion = _firstInt(schemaRows);
    if (schemaVersion < minimumSchemaVersion ||
        schemaVersion > maximumSchemaVersion) {
      throw LocalDataBackupException(
        code: LocalDataBackupErrorCode.unsupportedSchema,
        message: '不支持数据库版本 $schemaVersion。支持范围为 '
            '$minimumSchemaVersion-$maximumSchemaVersion。',
      );
    }

    final integrityRows = await database.rawQuery('PRAGMA integrity_check');
    final integrityMessages = integrityRows
        .expand((row) => row.values)
        .map((value) => value.toString().toLowerCase())
        .toList(growable: false);
    if (integrityMessages.length != 1 || integrityMessages.single != 'ok') {
      throw const LocalDataBackupException(
        code: LocalDataBackupErrorCode.integrityFailure,
        message: '备份数据库完整性检查未通过。',
      );
    }

    final tableRows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = tableRows
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();
    final missingTables = requiredTables.difference(tableNames).toList()
      ..sort();
    if (missingTables.isNotEmpty) {
      throw LocalDataBackupException(
        code: LocalDataBackupErrorCode.missingTables,
        message: '备份缺少必要数据表: ${missingTables.join(', ')}。',
      );
    }

    final foreignKeyRows = await database.rawQuery('PRAGMA foreign_key_check');
    return LocalDataBackupValidation(
      schemaVersion: schemaVersion,
      fileSizeBytes: fileSizeBytes,
      foreignKeyViolationCount: foreignKeyRows.length,
      tableNames: Set.unmodifiable(tableNames),
    );
  }

  Future<void> _vacuumInto(Database database, String destinationPath) async {
    final destination = File(destinationPath);
    if (await destination.exists()) await destination.delete();
    await database.execute(
      'VACUUM INTO ${_sqlStringLiteral(destination.absolute.path)}',
    );
  }

  Future<bool> _rollback(String databasePath, String rollbackPath) async {
    try {
      await _databaseHelper.close();
      await _deleteSidecarFiles(databasePath);
      await File(rollbackPath).copy(databasePath);
      final database = await _databaseHelper.database;
      final fileSize = await File(databasePath).length();
      await _validateOpenDatabase(
        database,
        fileSizeBytes: fileSize,
        requiredTables: _currentRequiredTables,
        minimumSchemaVersion: DatabaseHelper.schemaVersion,
        maximumSchemaVersion: DatabaseHelper.schemaVersion,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> _requireFileBackedDatabasePath() async {
    final databasePath = await _databaseHelper.resolvedDatabasePath;
    if (databasePath == inMemoryDatabasePath || databasePath == ':memory:') {
      throw const LocalDataBackupException(
        code: LocalDataBackupErrorCode.restoreFailure,
        message: '内存数据库不支持备份与恢复。',
      );
    }
    await _databaseHelper.database;
    return databasePath;
  }

  Future<Directory> _createWorkingDirectory(String operation) async {
    final root = await _temporaryDirectoryLoader();
    final sequence = _operationSequence++;
    final name = 'anchor-learning_${operation}_'
        '${_clock().toUtc().microsecondsSinceEpoch}_$sequence';
    return Directory(p.join(root.path, name)).create(recursive: true);
  }

  Future<void> _deleteSidecarFiles(String databasePath) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('$databasePath$suffix');
      if (await sidecar.exists()) await sidecar.delete();
    }
  }

  Future<void> _deleteDirectoryBestEffort(Directory directory) async {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {
      // Temporary cleanup must not hide the backup or restore result.
    }
  }

  static int _firstInt(List<Map<String, Object?>> rows) {
    if (rows.isEmpty || rows.first.values.isEmpty) return 0;
    return int.tryParse(rows.first.values.first.toString()) ?? 0;
  }

  static bool _bytesEqual(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static String _sqlStringLiteral(String value) =>
      "'${value.replaceAll("'", "''")}'";

  static String _compactTimestamp(DateTime value) {
    String two(int part) => part.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}-'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}Z';
  }
}
