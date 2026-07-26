import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/services/ingestion/programming_source_import_service.dart';

void main() {
  const service = ProgrammingSourceImportService();

  group('ProgrammingSourceImportService', () {
    test('requires auditable provenance for preferred evidence', () {
      final validation = service.validate(
        const ProgrammingSourceImportDraft(
          title: 'Python data model',
          content: 'Objects are Python abstractions for data.',
          trustLevel: SourceTrustLevel.officialDoc,
        ),
      );

      expect(validation.isValid, isFalse);
      expect(validation.errors, contains('官方文档或源码必须填写规范来源 URL'));
      expect(validation.errors, contains('官方文档或源码必须填写发布者或仓库所有者'));
      expect(
        validation.errors,
        contains('官方文档或源码必须填写文档版本、tag 或 commit revision'),
      );
    });

    test('rejects a non-canonical preferred source URL', () {
      final validation = service.validate(
        const ProgrammingSourceImportDraft(
          title: 'Local copy',
          content: 'class Example {}',
          trustLevel: SourceTrustLevel.sourceCode,
          uri: 'README.md',
          publisher: 'example/repository',
          revision: 'abc123',
        ),
      );

      expect(validation.isValid, isFalse);
      expect(
        validation.errors,
        contains('规范来源 URL 必须是完整的 http 或 https 地址'),
      );
    });

    test('builds a versioned SHA-256 snapshot with line provenance', () {
      final retrievedAt = DateTime.utc(2026, 7, 15, 4, 30);
      final snapshot = service.buildSnapshot(
        draft: const ProgrammingSourceImportDraft(
          title: 'Python 3.14.6 documentation',
          content:
              'Python 3.14.6 documentation\r\nObjects are abstractions.\r\n',
          trustLevel: SourceTrustLevel.officialDoc,
          uri: 'https://docs.python.org/3/',
          publisher: 'Python Software Foundation',
          revision: '3.14.6',
          licenseExpression: 'PSF-2.0',
        ),
        sourceId: 'python-docs',
        retrievedAt: retrievedAt,
      );

      expect(snapshot.source.type, SourceType.officialDoc);
      expect(snapshot.source.publisher, 'Python Software Foundation');
      expect(snapshot.source.revision, '3.14.6');
      expect(snapshot.source.licenseExpression, 'PSF-2.0');
      expect(snapshot.source.retrievedAt, retrievedAt);
      expect(snapshot.source.contentHash, hasLength(64));
      expect(snapshot.chunks, hasLength(1));
      expect(snapshot.chunks.single.locator, 'snapshot:L1-L2');
      expect(snapshot.chunks.single.startLine, 1);
      expect(snapshot.chunks.single.endLine, 2);
      expect(snapshot.chunks.single.contentHash, hasLength(64));
    });

    test('keeps license unknown explicit without blocking a user note', () {
      final snapshot = service.buildSnapshot(
        draft: const ProgrammingSourceImportDraft(
          title: 'My event loop notes',
          content: 'The event loop processes queued work.',
          trustLevel: SourceTrustLevel.userNote,
        ),
        sourceId: 'note',
        retrievedAt: DateTime.utc(2026, 7, 15),
      );

      expect(snapshot.source.licenseExpression, isNull);
      expect(snapshot.source.trustLevel, SourceTrustLevel.userNote);
      expect(snapshot.source.contentHash, hasLength(64));
    });
  });
}
