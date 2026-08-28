import 'dart:io';

import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/deck.dart';
import 'package:anchor_learning/services/privacy/local_data_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('anchor-learning_backup_test_');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  DatabaseHelper helperAt(String fileName) {
    return DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(temporaryDirectory.path, fileName),
    );
  }

  LocalDataBackupService serviceFor(DatabaseHelper helper) {
    return LocalDataBackupService(
      databaseHelper: helper,
      temporaryDirectoryLoader: () async => temporaryDirectory,
      clock: () => DateTime.utc(2026, 7, 16, 12, 30),
    );
  }

  test('creates a validated SQLite snapshot without closing the live database',
      () async {
    final helper = helperAt('live.db');
    addTearDown(helper.close);
    await helper.insertDeck(_deck('deck-live', 'Live data'));
    final service = serviceFor(helper);

    final artifact = await service.createBackup();
    expect(artifact.fileName, startsWith('anchor-learning-backup-v23-'));
    expect(artifact.validation.schemaVersion, DatabaseHelper.schemaVersion);
    expect(artifact.validation.foreignKeyViolationCount, 0);
    expect(await File(artifact.filePath).exists(), isTrue);
    expect((await helper.getAllDecks()).single.id, 'deck-live');

    final snapshotHelper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
      databasePath: artifact.filePath,
    );
    expect((await snapshotHelper.getAllDecks()).single.id, 'deck-live');
    await snapshotHelper.close();

    final workingDirectory = File(artifact.filePath).parent;
    await artifact.dispose();
    expect(await workingDirectory.exists(), isFalse);
  });

  test('restores a supported older backup and runs database migrations',
      () async {
    final liveHelper = helperAt('live.db');
    addTearDown(liveHelper.close);
    await liveHelper.insertDeck(_deck('deck-old', 'Old live data'));

    final candidateHelper = helperAt('candidate.db');
    await candidateHelper.insertDeck(_deck('deck-new', 'Restored data'));
    await candidateHelper.close();
    final candidateDatabase = await databaseFactoryFfi.openDatabase(
      p.join(temporaryDirectory.path, 'candidate.db'),
    );
    await candidateDatabase.execute('DROP TABLE product_events');
    await candidateDatabase.setVersion(22);
    await candidateDatabase.close();

    final result = await serviceFor(liveHelper).restoreBackup(
      p.join(temporaryDirectory.path, 'candidate.db'),
    );

    expect(result.candidateValidation.schemaVersion, 22);
    expect(result.restoredValidation.schemaVersion, 23);
    expect(result.migrationApplied, isTrue);
    expect((await liveHelper.getAllDecks()).single.id, 'deck-new');
    final tables = await (await liveHelper.database).rawQuery(
      "SELECT name FROM sqlite_master WHERE name = 'product_events'",
    );
    expect(tables, hasLength(1));
  });

  test('rejects a non-SQLite file without changing live data', () async {
    final helper = helperAt('live.db');
    addTearDown(helper.close);
    await helper.insertDeck(_deck('deck-keep', 'Keep me'));
    final invalidFile = File(p.join(temporaryDirectory.path, 'invalid.db'));
    await invalidFile.writeAsString('not a sqlite database');

    await expectLater(
      serviceFor(helper).restoreBackup(invalidFile.path),
      throwsA(
        isA<LocalDataBackupException>().having(
          (error) => error.code,
          'code',
          LocalDataBackupErrorCode.invalidFile,
        ),
      ),
    );
    expect((await helper.getAllDecks()).single.id, 'deck-keep');
  });

  test('rolls back automatically when post-migration validation fails',
      () async {
    final liveHelper = helperAt('live.db');
    addTearDown(liveHelper.close);
    await liveHelper.insertDeck(_deck('deck-original', 'Original data'));

    final candidateHelper = helperAt('candidate.db');
    await candidateHelper.insertDeck(_deck('deck-candidate', 'Candidate data'));
    await candidateHelper.close();
    final candidateDatabase = await databaseFactoryFfi.openDatabase(
      p.join(temporaryDirectory.path, 'candidate.db'),
    );
    await candidateDatabase.execute(
      'DROP TABLE knowledge_point_prerequisites',
    );
    await candidateDatabase.setVersion(22);
    await candidateDatabase.close();

    await expectLater(
      serviceFor(liveHelper).restoreBackup(
        p.join(temporaryDirectory.path, 'candidate.db'),
      ),
      throwsA(
        isA<LocalDataBackupException>()
            .having(
              (error) => error.code,
              'code',
              LocalDataBackupErrorCode.restoreFailure,
            )
            .having(
              (error) => error.rollbackSucceeded,
              'rollbackSucceeded',
              isTrue,
            ),
      ),
    );
    expect((await liveHelper.getAllDecks()).single.id, 'deck-original');
  });
}

Deck _deck(String id, String title) {
  final now = DateTime.utc(2026, 7, 16, 12);
  return Deck(id: id, title: title, createdAt: now, updatedAt: now);
}
