import 'dart:io';

import 'package:anchor_learning/services/release/private_alpha_privacy_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('clean artifacts pass without findings', () async {
    final root = await Directory.systemTemp.createTemp('anchor-learning-scan-');
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'release.json')).writeAsString(
      '{"status":"HOLD","endpoint":"https://example.com/v1"}',
    );

    final result = await const PrivateAlphaPrivacyScanner().scan(
      repositoryRoot: root.path,
      evidence: const PrivateAlphaPrivacyScanEvidence(
        paths: ['release.json'],
      ),
    );

    expect(result.passed, isTrue);
    expect(result.findings, isEmpty);
  });

  test('reports categories and relative paths without retaining secrets',
      () async {
    final root = await Directory.systemTemp.createTemp('anchor-learning-scan-');
    addTearDown(() => root.delete(recursive: true));
    final token = List.filled(36, 'x').join();
    final jwtPart = List.filled(16, 'a').join();
    final secret = 'sk-$token';
    final content = [
      secret,
      'Authorization: Bearer $token',
      'https://relay.example/v1?token=$token',
      r'C:\Users\person\private\project.dart',
      'eyJ$jwtPart.$jwtPart.$jwtPart',
    ].join('\n');
    await File(p.join(root.path, 'support.txt')).writeAsString(content);

    final result = await const PrivateAlphaPrivacyScanner().scan(
      repositoryRoot: root.path,
      evidence: const PrivateAlphaPrivacyScanEvidence(
        paths: ['support.txt'],
      ),
    );

    expect(
      result.findings.map((finding) => finding.category).toSet(),
      {
        PrivateAlphaPrivacyFindingCategory.apiKey,
        PrivateAlphaPrivacyFindingCategory.authorization,
        PrivateAlphaPrivacyFindingCategory.credentialQuery,
        PrivateAlphaPrivacyFindingCategory.privateAbsolutePath,
        PrivateAlphaPrivacyFindingCategory.jwt,
      },
    );
    expect(
        result.findings
            .every((finding) => finding.relativePath == 'support.txt'),
        isTrue);
    expect(result.blockers.join(' '), isNot(contains(secret)));
    expect(result.blockers.join(' '), isNot(contains(token)));
    expect(result.blockers.join(' '), isNot(contains(root.path)));
  });

  test('deduplicates repeated matches and flags sensitive file names',
      () async {
    final root = await Directory.systemTemp.createTemp('anchor-learning-scan-');
    addTearDown(() => root.delete(recursive: true));
    final token = List.filled(30, 'z').join();
    await File(p.join(root.path, 'repeated.txt')).writeAsString(
      'sk-$token\nsk-$token',
    );
    await File(p.join(root.path, '.env')).writeAsString('SAFE=placeholder');

    final result = await const PrivateAlphaPrivacyScanner().scan(
      repositoryRoot: root.path,
      evidence: const PrivateAlphaPrivacyScanEvidence(
        paths: ['repeated.txt', '.env'],
      ),
    );

    expect(
      result.findings
          .where((finding) =>
              finding.category == PrivateAlphaPrivacyFindingCategory.apiKey)
          .length,
      1,
    );
    expect(
      result.findings,
      contains(
        isA<PrivateAlphaPrivacyFinding>()
            .having(
              (finding) => finding.category,
              'category',
              PrivateAlphaPrivacyFindingCategory.sensitiveFile,
            )
            .having((finding) => finding.relativePath, 'path', '.env'),
      ),
    );
  });

  test('contains path failures without exposing resolved absolute paths',
      () async {
    final root = await Directory.systemTemp.createTemp('anchor-learning-scan-');
    addTearDown(() => root.delete(recursive: true));

    final result = await const PrivateAlphaPrivacyScanner().scan(
      repositoryRoot: root.path,
      evidence: const PrivateAlphaPrivacyScanEvidence(
        paths: ['../outside.txt', 'missing.txt'],
      ),
    );

    expect(result.blockers, [
      'privacy_scan_pathOutsideRepository:../outside.txt',
      'privacy_scan_unreadable:missing.txt',
    ]);
    expect(result.blockers.join(' '), isNot(contains(root.path)));
  });

  test('parser requires explicit repository-relative artifact paths', () {
    expect(
      () => PrivateAlphaPrivacyScanEvidence.fromJson(const {}),
      throwsA(isA<FormatException>()),
    );
    for (final path in const [
      'C:/private/export.json',
      r'C:\private\export.json',
      '/tmp/export.json',
      'file:///tmp/export.json',
    ]) {
      expect(
        () => PrivateAlphaPrivacyScanEvidence.fromJson({
          'privacy_scan': {
            'paths': [path],
          },
        }),
        throwsA(isA<FormatException>()),
        reason: path,
      );
    }
  });
}
