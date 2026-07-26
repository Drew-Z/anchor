import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dlg_q/services/release/private_alpha_release_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('verifies a passing gate against the actual APK identity', () async {
    final root = await Directory.systemTemp.createTemp('duoduo-release-');
    addTearDown(() => root.delete(recursive: true));
    final apk = File(p.join(root.path, 'build', 'app.apk'));
    await apk.parent.create(recursive: true);
    const bytes = [1, 2, 3, 4, 5];
    await apk.writeAsBytes(bytes);
    final evidence = _evidence(
      apkPath: p.join('build', 'app.apk'),
      bytes: bytes.length,
      hash: sha256.convert(bytes).toString(),
    );

    final verification =
        await const PrivateAlphaReleaseEvidenceVerifier().verify(
      evidence: evidence,
      repositoryRoot: root.path,
    );

    expect(verification.passed, isTrue);
    expect(verification.blockers, isEmpty);
  });

  test('holds when the APK is missing or its identity drifts', () async {
    final root = await Directory.systemTemp.createTemp('duoduo-release-');
    addTearDown(() => root.delete(recursive: true));
    final missing = await const PrivateAlphaReleaseEvidenceVerifier().verify(
      evidence: _evidence(
        apkPath: p.join('build', 'missing.apk'),
        bytes: 5,
        hash: List.filled(64, '0').join(),
      ),
      repositoryRoot: root.path,
    );
    expect(missing.blockers, contains('android_build_apk_missing'));

    final apk = File(p.join(root.path, 'build', 'app.apk'));
    await apk.parent.create(recursive: true);
    await apk.writeAsBytes(const [1, 2, 3]);
    final drifted = await const PrivateAlphaReleaseEvidenceVerifier().verify(
      evidence: _evidence(
        apkPath: p.join('build', 'app.apk'),
        bytes: 99,
        hash: List.filled(64, '0').join(),
      ),
      repositoryRoot: root.path,
    );
    expect(drifted.blockers, [
      'android_build_bytes_mismatch',
      'android_build_sha256_mismatch',
    ]);
  });

  test('rejects unsafe paths and incomplete automated evidence', () async {
    final root = await Directory.systemTemp.createTemp('duoduo-release-');
    addTearDown(() => root.delete(recursive: true));
    final verification =
        await const PrivateAlphaReleaseEvidenceVerifier().verify(
      evidence: _evidence(
        apkPath: p.join('..', 'outside.apk'),
        bytes: 1,
        hash: List.filled(64, '0').join(),
        testsPassed: 0,
        arm64Only: false,
      ),
      repositoryRoot: root.path,
    );
    expect(verification.blockers, [
      'automated_gate_evidence_invalid',
      'android_build_evidence_invalid',
      'android_build_path_outside_repository',
    ]);
  });

  test('schema parser rejects malformed release evidence', () {
    expect(
      () => PrivateAlphaReleaseEvidence.fromJson(const {}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PrivateAlphaAndroidBuildEvidence.fromJson(const {
        'apk_path': 'build/app.apk',
        'bytes': 1,
        'sha256': 'not-a-hash',
        'arm64_only': true,
        'v2_signed': true,
      }),
      throwsA(isA<FormatException>()),
    );
    for (final path in const [
      'C:/private/app.apk',
      r'C:\private\app.apk',
      '/tmp/app.apk',
      'file:///tmp/app.apk',
      'https://example.com/app.apk',
      'data:text/plain,app.apk',
    ]) {
      expect(
        () => PrivateAlphaAndroidBuildEvidence.fromJson({
          'apk_path': path,
          'bytes': 1,
          'sha256': List.filled(64, '0').join(),
          'arm64_only': true,
          'v2_signed': true,
        }),
        throwsA(isA<FormatException>()),
        reason: path,
      );
    }
  });
}

PrivateAlphaReleaseEvidence _evidence({
  required String apkPath,
  required int bytes,
  required String hash,
  int testsPassed = 262,
  bool arm64Only = true,
}) {
  return PrivateAlphaReleaseEvidence(
    schemaVersion: 2,
    automatedGate: PrivateAlphaAutomatedGateEvidence(
      completedAt: DateTime.utc(2026, 7, 17),
      testsPassed: testsPassed,
      analyzerErrors: 0,
      analyzerWarnings: 0,
      formatPassed: true,
      diffCheckPassed: true,
    ),
    androidBuild: PrivateAlphaAndroidBuildEvidence(
      apkPath: apkPath,
      bytes: bytes,
      sha256: hash,
      arm64Only: arm64Only,
      v2Signed: true,
    ),
  );
}
