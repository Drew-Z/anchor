import 'package:dlg_q/services/release/private_alpha_cohort_evidence.dart';
import 'package:dlg_q/services/release/private_alpha_controlled_credential_evidence.dart';
import 'package:dlg_q/services/release/private_alpha_model_acceptance_evidence.dart';
import 'package:dlg_q/services/release/private_alpha_operator_pack_evidence.dart';
import 'package:dlg_q/services/release/private_alpha_release_consistency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fingerprint =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('accepts one closed release identity across all external evidence', () {
    final verification = const PrivateAlphaReleaseConsistencyVerifier().verify(
      acceptanceEvidence: _acceptance(fingerprint),
      credentialEvidence: _credential(fingerprint),
      operatorEvidence: _operator(),
      cohortEvidence: _cohort(fingerprint: fingerprint),
    );

    expect(verification.blockers, isEmpty);
  });

  test('blocks a NO-GO or conditional cohort decision', () {
    for (final decision in [
      PrivateAlphaCohortDecision.noGo,
      PrivateAlphaCohortDecision.conditionalGo,
    ]) {
      final verification =
          const PrivateAlphaReleaseConsistencyVerifier().verify(
        acceptanceEvidence: _acceptance(fingerprint),
        credentialEvidence: _credential(fingerprint),
        operatorEvidence: _operator(),
        cohortEvidence: _cohort(
          fingerprint: fingerprint,
          decision: decision,
        ),
      );
      expect(
        verification.blockers,
        contains('release_consistency_cohort_decision_not_go'),
      );
    }
  });

  test('blocks unrelated operator, profile, and credential records', () {
    final verification = const PrivateAlphaReleaseConsistencyVerifier().verify(
      acceptanceEvidence: _acceptance(List.filled(64, 'b').join()),
      credentialEvidence: _credential(List.filled(64, 'c').join()),
      operatorEvidence: _operator(locator: 'OPS-OTHER-001'),
      cohortEvidence: _cohort(fingerprint: fingerprint),
    );

    expect(verification.blockers, [
      'release_consistency_operator_locator_mismatch',
      'release_consistency_profile_binding_mismatch',
      'release_consistency_scope_mismatch',
    ]);
  });

  test('blocks participant credential scope drift without exposing identity',
      () {
    final verification = const PrivateAlphaReleaseConsistencyVerifier().verify(
      acceptanceEvidence: _acceptance(fingerprint),
      credentialEvidence: _credential(fingerprint),
      operatorEvidence: _operator(),
      cohortEvidence: _cohort(
        fingerprint: fingerprint,
        scope: PrivateAlphaCredentialScope.participantOwned,
      ),
    );

    expect(verification.blockers, [
      'release_consistency_profile_binding_mismatch',
      'release_consistency_scope_mismatch',
    ]);
    expect(verification.blockers.join(' '), isNot(contains('A01')));
  });
}

PrivateAlphaReleaseDayAcceptanceEvidence _acceptance(String fingerprint) =>
    PrivateAlphaReleaseDayAcceptanceEvidence(
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
          apkSha256: List.filled(64, 'd').join(),
          credentialScope: PrivateAlphaCredentialScope.controlled,
          cases: const {},
        ),
      ],
    );

PrivateAlphaControlledCredentialEvidence _credential(String fingerprint) =>
    PrivateAlphaControlledCredentialEvidence(
      bindings: [
        PrivateAlphaCredentialBindingEvidence(
          role: 'primary',
          scope: PrivateAlphaCredentialScope.controlled,
          credentialReference: 'CRED-PRIMARY-001',
          profileFingerprint: fingerprint,
          quotaOwnerDeclared: true,
          quotaLimitKnown: true,
          revocationSupported: true,
          revocationOwnerDeclared: true,
          retentionPolicyDeclared: true,
          dataHandlingPolicyDeclared: true,
        ),
      ],
    );

PrivateAlphaOperatorPackEvidence _operator({
  String locator = 'OPS-ALPHA-001',
}) =>
    PrivateAlphaOperatorPackEvidence(
      roleCodes: PrivateAlphaOperatorPackEvidence.requiredRoleCodes,
      externalRecordLocator: locator,
      accessRestricted: true,
      retentionPolicyDeclared: true,
      deletionProcedureDeclared: true,
      incidentResponseDeclared: true,
    );

PrivateAlphaCohortEvidence _cohort({
  required String fingerprint,
  PrivateAlphaCredentialScope scope = PrivateAlphaCredentialScope.controlled,
  PrivateAlphaCohortDecision decision = PrivateAlphaCohortDecision.go,
}) =>
    PrivateAlphaCohortEvidence(
      freezeReference: 'COHORT-ALPHA-001',
      frozenAt: DateTime.utc(2026, 7, 18),
      formalDenominator: 10,
      apkSha256: List.filled(64, 'd').join(),
      profileFingerprints: {fingerprint},
      participants: [
        for (var index = 1; index <= 10; index++)
          PrivateAlphaCohortParticipantEvidence(
            code: 'A${index.toString().padLeft(2, '0')}',
            track: index <= 5
                ? PrivateAlphaCohortTrack.observed
                : PrivateAlphaCohortTrack.selfServe,
            consent: PrivateAlphaCohortConsent.accepted,
            invitation: PrivateAlphaCohortInvitation.complete,
            profileFingerprint: fingerprint,
            credentialScope: scope,
            d0Status: PrivateAlphaCohortPhaseStatus.completed,
            d0GroundedTurnCompleted: true,
            d0EvidenceReference: 'EV-D0-$index',
            d7Status: PrivateAlphaCohortPhaseStatus.completed,
            d7GroundedTurnCompleted: true,
            d7EvidenceReference: 'EV-D7-$index',
            d14Status: PrivateAlphaCohortPhaseStatus.completed,
            learningClaimStatus: PrivateAlphaLearningClaimStatus.supported,
            d14EvidenceReference: 'EV-D14-$index',
          ),
      ],
      decision: decision,
      decisionAt: DateTime.utc(2026, 7, 31),
      reportReference: 'REPORT-ALPHA-001',
      operatorRecordLocator: 'OPS-ALPHA-001',
    );
