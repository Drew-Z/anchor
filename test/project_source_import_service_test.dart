import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:anchor_learning/services/ingestion/project_source_import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ProjectSourceImportService', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'anchor-learning-project-import-',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('scans a directory with deterministic provenance and exclusions',
        () async {
      await _writeFile(
          tempDirectory, 'README.md', '# Demo\r\nLearning app\r\n');
      await _writeFile(
        tempDirectory,
        'lib/main.dart',
        'void main() {\n  print("demo");\n}\n',
      );
      await _writeFile(tempDirectory, 'lib/model.g.dart', 'generated');
      await _writeFile(tempDirectory, 'build/output.txt', 'generated');
      await _writeFile(tempDirectory, '.env', 'API_KEY=secret');
      await _writeBytes(tempDirectory, 'assets/logo.png', [0, 1, 2, 3]);
      await _writeFile(tempDirectory, 'notes.rtf', 'unsupported');
      await _writeFile(
        tempDirectory,
        'docs/large.md',
        'x' * 65,
      );

      const gitHash = '0123456789abcdef0123456789abcdef01234567';
      await _writeFile(tempDirectory, '.git/HEAD', 'ref: refs/heads/main\n');
      await _writeFile(tempDirectory, '.git/refs/heads/main', '$gitHash\n');

      const service = ProjectSourceImportService(
        policy: ProjectSourceImportPolicy(maxFileBytes: 64),
      );
      final snapshot = await service.scanDirectory(tempDirectory.path);

      expect(snapshot.kind, ProjectSourceImportKind.directory);
      expect(
        snapshot.files.map((file) => file.relativePath),
        orderedEquals(['README.md', 'lib/main.dart']),
      );
      expect(snapshot.files.first.content, '# Demo\nLearning app\n');
      expect(snapshot.files.first.lineCount, 2);
      expect(snapshot.files.first.contentHash, hasLength(64));
      expect(
        snapshot.revision,
        startsWith('git:$gitHash;snapshot:'),
      );

      final exclusions = {
        for (final exclusion in snapshot.exclusions)
          exclusion.relativePath: exclusion.reason,
      };
      expect(
        exclusions['lib/model.g.dart'],
        ProjectSourceExclusionReason.generated,
      );
      expect(
        exclusions['build/output.txt'],
        ProjectSourceExclusionReason.generated,
      );
      expect(
        exclusions['.env'],
        ProjectSourceExclusionReason.sensitive,
      );
      expect(
        exclusions['assets/logo.png'],
        ProjectSourceExclusionReason.unsupported,
      );
      expect(
        exclusions['notes.rtf'],
        ProjectSourceExclusionReason.unsupported,
      );
      expect(
        exclusions['docs/large.md'],
        ProjectSourceExclusionReason.tooLarge,
      );
    });

    test('scans ZIP content, strips one common root, and rejects unsafe paths',
        () async {
      final archive = Archive()
        ..add(ArchiveFile.string('demo-main/README.md', '# Demo\n'))
        ..add(ArchiveFile.string(
          'demo-main/lib/app.dart',
          'class App {}\n',
        ))
        ..add(ArchiveFile.string(
          'demo-main/node_modules/pkg/index.js',
          'generated',
        ))
        ..add(ArchiveFile.string('demo-main/.env.local', 'TOKEN=secret'))
        ..add(ArchiveFile.string('../escape.dart', 'unsafe'));
      final zipBytes = ZipEncoder().encodeBytes(archive);

      const service = ProjectSourceImportService();
      final snapshot = await service.scanZipBytes(
        archiveName: 'demo.zip',
        bytes: zipBytes,
      );

      expect(snapshot.kind, ProjectSourceImportKind.zip);
      expect(snapshot.displayName, 'demo');
      expect(
        snapshot.files.map((file) => file.relativePath),
        orderedEquals(['README.md', 'lib/app.dart']),
      );
      expect(snapshot.files.last.locator, 'lib/app.dart:1-1');
      expect(
          snapshot.revision, matches(RegExp(r'^zip:[0-9a-f]{64};snapshot:')));

      final exclusions = {
        for (final exclusion in snapshot.exclusions)
          exclusion.relativePath: exclusion.reason,
      };
      expect(
        exclusions['node_modules/pkg/index.js'],
        ProjectSourceExclusionReason.generated,
      );
      expect(
        exclusions['.env.local'],
        ProjectSourceExclusionReason.sensitive,
      );
      expect(
        exclusions['../escape.dart'],
        ProjectSourceExclusionReason.unsafePath,
      );
    });

    test('scans virtual directory entries with the shared safety policy',
        () async {
      const service = ProjectSourceImportService(
        policy: ProjectSourceImportPolicy(maxFileBytes: 8),
      );
      final snapshot = await service.scanDirectoryEntries(
        displayName: ' SAF Demo ',
        sourceUri: 'content://tree/demo',
        entries: [
          _memoryEntry('lib/app.dart', 'app\r\n'),
          _memoryEntry('.env', 'SECRET=x'),
          _memoryEntry('../escape.md', 'unsafe'),
          _memoryEntry('lib/app.dart', 'duplicate'),
          ProjectSourceInputFile(
            relativePath: 'docs/unknown-size.md',
            byteLength: 0,
            readBytes: () async => Uint8List.fromList('123456789'.codeUnits),
          ),
        ],
      );

      expect(snapshot.displayName, 'SAF Demo');
      expect(snapshot.sourceUri, 'content://tree/demo');
      expect(snapshot.revision, matches(RegExp(r'^snapshot:[0-9a-f]{64}$')));
      expect(snapshot.files.single.relativePath, 'lib/app.dart');
      expect(snapshot.files.single.content, 'app\n');

      final reasons =
          snapshot.exclusions.map((exclusion) => exclusion.reason).toList();
      expect(reasons, contains(ProjectSourceExclusionReason.sensitive));
      expect(
        reasons.where(
            (reason) => reason == ProjectSourceExclusionReason.unsafePath),
        hasLength(2),
      );
      expect(reasons, contains(ProjectSourceExclusionReason.tooLarge));
    });

    test('maps a native read limit failure to a too-large exclusion', () async {
      const service = ProjectSourceImportService();
      final snapshot = await service.scanDirectoryEntries(
        displayName: 'Demo',
        sourceUri: 'content://tree/demo',
        entries: [
          ProjectSourceInputFile(
            relativePath: 'lib/app.dart',
            byteLength: 0,
            readBytes: () async =>
                throw const ProjectSourceReadLimitException(512 * 1024),
          ),
        ],
      );

      expect(snapshot.files, isEmpty);
      expect(
        snapshot.exclusions.single.reason,
        ProjectSourceExclusionReason.tooLarge,
      );
    });

    test('enforces candidate count and total size limits', () async {
      await _writeFile(tempDirectory, 'a.md', '1234');
      await _writeFile(tempDirectory, 'b.md', '5678');
      await _writeFile(tempDirectory, 'c.md', '90');

      const service = ProjectSourceImportService(
        policy: ProjectSourceImportPolicy(
          maxFileBytes: 16,
          maxTotalBytes: 6,
          maxFiles: 2,
        ),
      );
      final snapshot = await service.scanDirectory(tempDirectory.path);

      expect(snapshot.files.map((file) => file.relativePath), ['a.md', 'c.md']);
      expect(snapshot.includedBytes, 6);
      expect(
        snapshot.exclusions.single.relativePath,
        'b.md',
      );
      expect(
        snapshot.exclusions.single.reason,
        ProjectSourceExclusionReason.totalSizeLimit,
      );
    });

    test('builds deterministic chunks with structured line provenance',
        () async {
      await _writeFile(
        tempDirectory,
        'lib/app.dart',
        'line 1\nline 2\nline 3\nline 4\nline 5\n',
      );

      const service = ProjectSourceImportService();
      final snapshot = await service.scanDirectory(tempDirectory.path);
      final chunks = service.buildSourceChunks(
        snapshot: snapshot,
        selectedPaths: {'lib/app.dart'},
        sourceId: 'source-1',
        createdAt: DateTime(2026, 7, 14),
        maxLinesPerChunk: 2,
      );

      expect(chunks, hasLength(3));
      expect(chunks.first.locator, 'lib/app.dart:1-2');
      expect(chunks.first.relativePath, 'lib/app.dart');
      expect(chunks.first.startLine, 1);
      expect(chunks.first.endLine, 2);
      expect(chunks.first.content, 'line 1\nline 2');
      expect(chunks.first.contentHash, hasLength(64));
      expect(chunks.last.locator, 'lib/app.dart:5-5');
    });

    test('assigns unique chunk identity and provenance across files', () async {
      await _writeFile(tempDirectory, 'README.md', '# Demo\n\nOverview\n');
      await _writeFile(tempDirectory, 'lib/app.dart', 'void main() {}\n');

      const service = ProjectSourceImportService();
      final snapshot = await service.scanDirectory(tempDirectory.path);
      final chunks = service.buildSourceChunks(
        snapshot: snapshot,
        selectedPaths: {'README.md', 'lib/app.dart'},
        sourceId: 'source-1',
        createdAt: DateTime(2026, 7, 14),
      );

      expect(chunks.map((chunk) => chunk.id), [
        'source-1_chunk_0',
        'source-1_chunk_1',
      ]);
      expect(chunks.map((chunk) => chunk.chunkIndex), [0, 1]);
      expect(
        chunks.map((chunk) => chunk.relativePath),
        ['README.md', 'lib/app.dart'],
      );
    });
  });
}

ProjectSourceInputFile _memoryEntry(String relativePath, String content) {
  final bytes = Uint8List.fromList(content.codeUnits);
  return ProjectSourceInputFile(
    relativePath: relativePath,
    byteLength: bytes.length,
    readBytes: () async => bytes,
  );
}

Future<void> _writeFile(
  Directory root,
  String relativePath,
  String content,
) async {
  final file = File(p.join(root.path, p.joinAll(relativePath.split('/'))));
  await file.create(recursive: true);
  await file.writeAsString(content);
}

Future<void> _writeBytes(
  Directory root,
  String relativePath,
  List<int> bytes,
) async {
  final file = File(p.join(root.path, p.joinAll(relativePath.split('/'))));
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
}
