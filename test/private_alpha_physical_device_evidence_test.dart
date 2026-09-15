import 'package:anchor_learning/services/release/private_alpha_physical_device_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const apkHash =
      '424087275110a499d37613b09f354c53325b0b8128195f573f8a522402eb1608';
  final evaluatedAt = DateTime.utc(2026, 7, 17, 12);

  test('accepts a fresh executed Arm64 physical-device smoke report', () {
    final verification =
        const PrivateAlphaPhysicalDeviceEvidenceVerifier().verify(
      evidence: _evidence(
        completedAt: evaluatedAt.subtract(const Duration(hours: 2)),
        apkHash: apkHash,
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, isEmpty);
  });

  test('rejects emulator, non-Arm64, unsupported API and READY reports', () {
    final verification =
        const PrivateAlphaPhysicalDeviceEvidenceVerifier().verify(
      evidence: _evidence(
        completedAt: evaluatedAt,
        apkHash: apkHash,
        status: 'READY',
        deviceKind: 'emulator',
        abi: 'x86_64',
        apiLevel: 36,
        requested: false,
        attempted: false,
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, [
      'physical_device_evidence_not_passed',
      'physical_device_required',
      'physical_device_arm64_required',
      'physical_device_api_24_to_35_required',
      'physical_device_execution_required',
    ]);
  });

  test('holds the Tier B physical ceiling at API 35 by release policy', () {
    // Flutter 3.44 supports API 36 and the Tier A emulator target runs API 36,
    // but the Tier B physical range stops at 35 until physical API 36
    // acceptance exists. Widening this is a release-owned decision; see the
    // supported-device matrix in docs/private-alpha-release-checklist.md.
    const verifier = PrivateAlphaPhysicalDeviceEvidenceVerifier();
    for (final apiLevel in const [24, 35]) {
      final verification = verifier.verify(
        evidence: _evidence(
          completedAt: evaluatedAt.subtract(const Duration(hours: 2)),
          apkHash: apkHash,
          apiLevel: apiLevel,
        ),
        expectedApkSha256: apkHash,
        evaluatedAt: evaluatedAt,
      );

      expect(verification.blockers, isEmpty, reason: 'API $apiLevel');
    }

    for (final apiLevel in const [23, 36]) {
      final verification = verifier.verify(
        evidence: _evidence(
          completedAt: evaluatedAt.subtract(const Duration(hours: 2)),
          apkHash: apkHash,
          apiLevel: apiLevel,
        ),
        expectedApkSha256: apkHash,
        evaluatedAt: evaluatedAt,
      );

      expect(
        verification.blockers,
        ['physical_device_api_24_to_35_required'],
        reason: 'API $apiLevel',
      );
    }
  });

  test('rejects failed smoke fields without exposing device identity', () {
    final verification =
        const PrivateAlphaPhysicalDeviceEvidenceVerifier().verify(
      evidence: _evidence(
        completedAt: evaluatedAt,
        apkHash: apkHash,
        installSucceeded: false,
        coldStartSucceeded: false,
        processAlive: false,
        logErrorMatches: 2,
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, ['physical_device_smoke_failed']);
  });

  test('rejects stale, future and cross-APK evidence', () {
    const verifier = PrivateAlphaPhysicalDeviceEvidenceVerifier();
    final stale = verifier.verify(
      evidence: _evidence(
        completedAt: evaluatedAt.subtract(const Duration(hours: 25)),
        apkHash: List.filled(64, '0').join(),
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );
    expect(stale.blockers, [
      'physical_device_apk_mismatch',
      'physical_device_evidence_stale',
    ]);

    final future = verifier.verify(
      evidence: _evidence(
        completedAt: evaluatedAt.add(const Duration(minutes: 1)),
        apkHash: apkHash,
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );
    expect(future.blockers, ['physical_device_evidence_stale']);
  });

  test('parses the existing preflight JSON shape inside evidence', () {
    final evidence = PrivateAlphaPhysicalDeviceEvidence.fromJson({
      'physical_device_evidence': {
        'completed_at': '2026-07-17T10:00:00Z',
        'report': {
          'status': 'PASSED',
          'apk': {'sha256': apkHash},
          'device': {
            'kind': 'physical',
            'abi': 'arm64-v8a',
            'api_level': 35,
          },
          'execution': {
            'requested': true,
            'attempted': true,
            'install_succeeded': true,
            'cold_start_succeeded': true,
            'process_alive': true,
            'log_error_matches': 0,
          },
        },
      },
    });

    expect(evidence.status, 'PASSED');
    expect(evidence.deviceKind, 'physical');
    expect(evidence.apiLevel, 35);
    expect(
      () => PrivateAlphaPhysicalDeviceEvidence.fromJson(const {}),
      throwsA(isA<FormatException>()),
    );
  });
}

PrivateAlphaPhysicalDeviceEvidence _evidence({
  required DateTime completedAt,
  required String apkHash,
  String status = 'PASSED',
  String deviceKind = 'physical',
  String abi = 'arm64-v8a',
  int apiLevel = 35,
  bool requested = true,
  bool attempted = true,
  bool installSucceeded = true,
  bool coldStartSucceeded = true,
  bool processAlive = true,
  int logErrorMatches = 0,
}) {
  return PrivateAlphaPhysicalDeviceEvidence(
    completedAt: completedAt,
    status: status,
    apkSha256: apkHash,
    deviceKind: deviceKind,
    abi: abi,
    apiLevel: apiLevel,
    executionRequested: requested,
    executionAttempted: attempted,
    installSucceeded: installSucceeded,
    coldStartSucceeded: coldStartSucceeded,
    processAlive: processAlive,
    logErrorMatches: logErrorMatches,
  );
}
