import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dlg_q/services/release/private_alpha_model_acceptance_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const apkHash =
      '424087275110a499d37613b09f354c53325b0b8128195f573f8a522402eb1608';
  final evaluatedAt = DateTime.utc(2026, 7, 17, 12);

  test('accepts one fresh controlled primary with exact five-of-five evidence',
      () {
    final verification =
        const PrivateAlphaModelAcceptanceEvidenceVerifier().verify(
      evidence: PrivateAlphaReleaseDayAcceptanceEvidence(
        fallbackOffered: false,
        profiles: [
          _profile(
            role: 'primary',
            completedAt: evaluatedAt.subtract(const Duration(hours: 2)),
            apkHash: apkHash,
          ),
        ],
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, isEmpty);
  });

  test('requires an independent fallback when it is offered', () {
    const verifier = PrivateAlphaModelAcceptanceEvidenceVerifier();
    final primary = _profile(
      role: 'primary',
      completedAt: evaluatedAt,
      apkHash: apkHash,
    );
    final missing = verifier.verify(
      evidence: PrivateAlphaReleaseDayAcceptanceEvidence(
        fallbackOffered: true,
        profiles: [primary],
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );
    expect(
      missing.blockers,
      contains('release_day_acceptance_fallback_required'),
    );

    final duplicate = verifier.verify(
      evidence: PrivateAlphaReleaseDayAcceptanceEvidence(
        fallbackOffered: true,
        profiles: [
          primary,
          _profile(
            role: 'fallback',
            completedAt: evaluatedAt,
            apkHash: apkHash,
          ),
        ],
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );
    expect(
      duplicate.blockers,
      contains('release_day_acceptance_profiles_not_independent'),
    );
  });

  test('blocks stale, cross-APK, shared and incomplete acceptance evidence',
      () {
    final profile = _profile(
      role: 'primary',
      completedAt: evaluatedAt.subtract(const Duration(hours: 25)),
      apkHash: List.filled(64, '0').join(),
      credentialScope: PrivateAlphaCredentialScope.sharedPublic,
      cases: const {
        'structuredJson': 'passed',
        'chinesePoem': 'failed',
      },
    );

    final verification =
        const PrivateAlphaModelAcceptanceEvidenceVerifier().verify(
      evidence: PrivateAlphaReleaseDayAcceptanceEvidence(
        fallbackOffered: false,
        profiles: [profile],
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, [
      'release_day_acceptance_primary_stale',
      'release_day_acceptance_primary_apk_mismatch',
      'release_day_acceptance_primary_credential_uncontrolled',
      'release_day_acceptance_primary_five_of_five_required',
    ]);
  });

  test('blocks unsafe endpoints and a forged profile fingerprint', () {
    final profile = _profile(
      role: 'primary',
      completedAt: evaluatedAt,
      apkHash: apkHash,
      endpoint: 'https://user@relay.example/v1?token=hidden',
      fingerprint: List.filled(64, 'f').join(),
    );

    final verification =
        const PrivateAlphaModelAcceptanceEvidenceVerifier().verify(
      evidence: PrivateAlphaReleaseDayAcceptanceEvidence(
        fallbackOffered: false,
        profiles: [profile],
      ),
      expectedApkSha256: apkHash,
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, [
      'release_day_acceptance_primary_endpoint_invalid',
      'release_day_acceptance_primary_fingerprint_mismatch',
    ]);
    expect(verification.blockers.join(' '), isNot(contains('hidden')));
    expect(verification.blockers.join(' '), isNot(contains('user@')));
  });

  test('parser rejects missing or malformed acceptance evidence', () {
    expect(
      () => PrivateAlphaReleaseDayAcceptanceEvidence.fromJson(const {}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PrivateAlphaModelProfileEvidence.fromJson(const {
        'role': 'primary',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}

PrivateAlphaModelProfileEvidence _profile({
  required String role,
  required DateTime completedAt,
  required String apkHash,
  String providerId = 'custom',
  String endpoint = 'https://relay.example/v1',
  String model = 'grok-4.5',
  String protocol = 'responses',
  String? fingerprint,
  PrivateAlphaCredentialScope credentialScope =
      PrivateAlphaCredentialScope.controlled,
  Map<String, String> cases = const {
    'structuredJson': 'passed',
    'chinesePoem': 'passed',
    'dartCoding': 'passed',
    'claimGrounding': 'passed',
    'evidenceRefusal': 'passed',
  },
}) {
  final signature =
      '$providerId|${_canonicalForTest(endpoint)}|$model|$protocol';
  return PrivateAlphaModelProfileEvidence(
    role: role,
    providerId: providerId,
    endpoint: endpoint,
    model: model,
    protocol: protocol,
    fingerprint:
        fingerprint ?? sha256.convert(utf8.encode(signature)).toString(),
    completedAt: completedAt,
    apkSha256: apkHash,
    credentialScope: credentialScope,
    cases: cases,
  );
}

String _canonicalForTest(String value) {
  final uri = Uri.parse(value.replaceFirst(RegExp(r'/+$'), ''));
  return Uri(
    scheme: uri.scheme.toLowerCase(),
    host: uri.host.toLowerCase(),
    port: uri.hasPort ? uri.port : null,
    path: uri.path.replaceFirst(RegExp(r'/+$'), ''),
  ).toString();
}
