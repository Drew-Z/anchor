import 'package:dlg_q/services/release/private_alpha_controlled_credential_evidence.dart';
import 'package:dlg_q/services/release/private_alpha_model_acceptance_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fingerprint =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('accepts policy-complete evidence bound to the accepted profile', () {
    final verification =
        const PrivateAlphaControlledCredentialEvidenceVerifier().verify(
      evidence: PrivateAlphaControlledCredentialEvidence(
        bindings: [_binding(fingerprint: fingerprint)],
      ),
      acceptanceEvidence: _acceptance(fingerprint),
    );
    expect(verification.blockers, isEmpty);
  });

  test('blocks shared, identifying, quota, revocation, and policy gaps', () {
    final verification =
        const PrivateAlphaControlledCredentialEvidenceVerifier().verify(
      evidence: PrivateAlphaControlledCredentialEvidence(
        bindings: [
          _binding(
            fingerprint: fingerprint,
            scope: PrivateAlphaCredentialScope.sharedPublic,
            reference: 'person@example.com',
            controlsDeclared: false,
          ),
        ],
      ),
      acceptanceEvidence: _acceptance(
        fingerprint,
        scope: PrivateAlphaCredentialScope.sharedPublic,
      ),
    );
    expect(verification.blockers, [
      'controlled_credential_primary_scope_uncontrolled',
      'controlled_credential_primary_reference_invalid',
      'controlled_credential_primary_quota_control_required',
      'controlled_credential_primary_revocation_control_required',
      'controlled_credential_primary_data_policy_required',
    ]);
    expect(verification.blockers.join(' '), isNot(contains('example.com')));
  });

  test('requires an exact release-day profile and scope binding', () {
    const verifier = PrivateAlphaControlledCredentialEvidenceVerifier();
    final evidence = PrivateAlphaControlledCredentialEvidence(
      bindings: [_binding(fingerprint: fingerprint)],
    );
    expect(
      verifier.verify(evidence: evidence).blockers,
      ['controlled_credential_release_day_binding_required'],
    );
    expect(
      verifier
          .verify(
            evidence: evidence,
            acceptanceEvidence: _acceptance(List.filled(64, 'b').join()),
          )
          .blockers,
      ['controlled_credential_primary_profile_mismatch'],
    );
  });

  test('requires one independent binding per offered profile', () {
    final verification =
        const PrivateAlphaControlledCredentialEvidenceVerifier().verify(
      evidence: PrivateAlphaControlledCredentialEvidence(
        bindings: [
          _binding(fingerprint: fingerprint),
          _binding(fingerprint: fingerprint),
        ],
      ),
      acceptanceEvidence: _acceptance(fingerprint),
    );
    expect(
      verification.blockers,
      contains('controlled_credential_references_not_independent'),
    );
    expect(
      verification.blockers,
      contains('controlled_credential_primary_binding_required'),
    );
  });

  test('parser requires the complete non-secret credential contract', () {
    expect(
      () => PrivateAlphaControlledCredentialEvidence.fromJson(const {}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PrivateAlphaControlledCredentialEvidence.fromJson(const {
        'controlled_credential': {
          'bindings': [
            {'role': 'primary'}
          ],
        },
      }),
      throwsA(isA<FormatException>()),
    );
  });
}

PrivateAlphaCredentialBindingEvidence _binding({
  required String fingerprint,
  PrivateAlphaCredentialScope scope = PrivateAlphaCredentialScope.controlled,
  String reference = 'CRED-PRIMARY-001',
  bool controlsDeclared = true,
}) {
  return PrivateAlphaCredentialBindingEvidence(
    role: 'primary',
    scope: scope,
    credentialReference: reference,
    profileFingerprint: fingerprint,
    quotaOwnerDeclared: controlsDeclared,
    quotaLimitKnown: controlsDeclared,
    revocationSupported: controlsDeclared,
    revocationOwnerDeclared: controlsDeclared,
    retentionPolicyDeclared: controlsDeclared,
    dataHandlingPolicyDeclared: controlsDeclared,
  );
}

PrivateAlphaReleaseDayAcceptanceEvidence _acceptance(
  String fingerprint, {
  PrivateAlphaCredentialScope scope = PrivateAlphaCredentialScope.controlled,
}) {
  return PrivateAlphaReleaseDayAcceptanceEvidence(
    fallbackOffered: false,
    profiles: [
      PrivateAlphaModelProfileEvidence(
        role: 'primary',
        providerId: 'custom',
        endpoint: 'https://relay.example/v1',
        model: 'grok-4.5',
        protocol: 'responses',
        fingerprint: fingerprint,
        completedAt: DateTime.utc(2026, 7, 17),
        apkSha256: List.filled(64, 'c').join(),
        credentialScope: scope,
        cases: const {},
      ),
    ],
  );
}
