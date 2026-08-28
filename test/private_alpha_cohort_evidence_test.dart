import 'package:anchor_learning/services/release/private_alpha_cohort_evidence.dart';
import 'package:anchor_learning/services/release/private_alpha_model_acceptance_evidence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const apkHash =
      '424087275110a499d37613b09f354c53325b0b8128195f573f8a522402eb1608';
  const fingerprint =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  final evaluatedAt = DateTime.utc(2026, 8, 1);

  test('accepts a fixed anonymous A01-A10 cohort bound to release evidence',
      () {
    final verification = const PrivateAlphaCohortEvidenceVerifier().verify(
      evidence: _cohort(apkHash: apkHash, fingerprint: fingerprint),
      expectedApkSha256: apkHash,
      acceptanceEvidence: _acceptance(fingerprint),
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, isEmpty);
  });

  test('blocks denominator, participant, track, and consent drift', () {
    final participants = _participants();
    participants[0] = _participant(
      code: 'A01',
      track: PrivateAlphaCohortTrack.selfServe,
    );
    participants[1] = _participant(
      code: 'S01',
      consent: PrivateAlphaCohortConsent.declined,
      invitation: PrivateAlphaCohortInvitation.complete,
    );
    final verification = const PrivateAlphaCohortEvidenceVerifier().verify(
      evidence: _cohort(
        apkHash: apkHash,
        fingerprint: fingerprint,
        denominator: 9,
        participants: participants,
      ),
      expectedApkSha256: apkHash,
      acceptanceEvidence: _acceptance(fingerprint),
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, contains('cohort_denominator_invalid'));
    expect(verification.blockers, contains('cohort_participant_set_invalid'));
    expect(verification.blockers, contains('cohort_a01_track_invalid'));
    expect(verification.blockers, contains('cohort_s01_consent_invalid'));
  });

  test(
      'blocks old APK, profile drift, missing release-day binding and time drift',
      () {
    const verifier = PrivateAlphaCohortEvidenceVerifier();
    final evidence = _cohort(
      apkHash: List.filled(64, 'b').join(),
      fingerprint: fingerprint,
      frozenAt: evaluatedAt.add(const Duration(days: 1)),
      decisionAt: evaluatedAt.subtract(const Duration(days: 1)),
    );
    final verification = verifier.verify(
      evidence: evidence,
      expectedApkSha256: apkHash,
      acceptanceEvidence: _acceptance(List.filled(64, 'c').join()),
      evaluatedAt: evaluatedAt,
    );
    final missingAcceptance = verifier.verify(
      evidence: evidence,
      expectedApkSha256: apkHash,
      acceptanceEvidence: null,
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, contains('cohort_apk_mismatch'));
    expect(verification.blockers, contains('cohort_profile_binding_mismatch'));
    expect(verification.blockers, contains('cohort_timeline_invalid'));
    expect(
      missingAcceptance.blockers,
      contains('cohort_release_day_binding_required'),
    );
  });

  test('blocks activation, formal phase, learning, and opaque-reference gaps',
      () {
    final participants = _participants();
    participants[0] = _participant(
      code: 'A01',
      d0GroundedTurnCompleted: false,
      d14Status: PrivateAlphaCohortPhaseStatus.absent,
      learningClaimStatus: PrivateAlphaLearningClaimStatus.supported,
      d0Reference: 'person@example.com',
    );
    final verification = const PrivateAlphaCohortEvidenceVerifier().verify(
      evidence: _cohort(
        apkHash: apkHash,
        fingerprint: fingerprint,
        participants: participants,
        reportReference: 'C:\\private\\report.json',
      ),
      expectedApkSha256: apkHash,
      acceptanceEvidence: _acceptance(fingerprint),
      evaluatedAt: evaluatedAt,
    );

    expect(verification.blockers, contains('cohort_record_reference_invalid'));
    expect(
        verification.blockers, contains('cohort_a01_phase_reference_invalid'));
    expect(verification.blockers, contains('cohort_a01_d0_activation_missing'));
    expect(
        verification.blockers, contains('cohort_a01_formal_phase_incomplete'));
    expect(
        verification.blockers, contains('cohort_a01_learning_outcome_invalid'));
    expect(verification.blockers.join(' '), isNot(contains('example.com')));
    expect(verification.blockers.join(' '), isNot(contains('private')));
  });

  test('parser rejects missing or malformed cohort evidence', () {
    expect(
      () => PrivateAlphaCohortEvidence.fromJson(const {}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PrivateAlphaCohortEvidence.fromJson(const {
        'cohort_evidence': {
          'profile_fingerprints': 'not-a-list',
          'participants': [],
        },
      }),
      throwsA(isA<FormatException>()),
    );
  });
}

PrivateAlphaCohortEvidence _cohort({
  required String apkHash,
  required String fingerprint,
  int denominator = 10,
  List<PrivateAlphaCohortParticipantEvidence>? participants,
  DateTime? frozenAt,
  DateTime? decisionAt,
  String reportReference = 'REPORT-ALPHA-001',
}) {
  return PrivateAlphaCohortEvidence(
    freezeReference: 'COHORT-ALPHA-001',
    frozenAt: frozenAt ?? DateTime.utc(2026, 7, 18),
    formalDenominator: denominator,
    apkSha256: apkHash,
    profileFingerprints: {fingerprint},
    participants: participants ?? _participants(),
    decision: PrivateAlphaCohortDecision.noGo,
    decisionAt: decisionAt ?? DateTime.utc(2026, 7, 31),
    reportReference: reportReference,
    operatorRecordLocator: 'OPS-ALPHA-001',
  );
}

List<PrivateAlphaCohortParticipantEvidence> _participants() => [
      for (var index = 1; index <= 10; index++)
        _participant(
          code: 'A${index.toString().padLeft(2, '0')}',
          track: index <= 5
              ? PrivateAlphaCohortTrack.observed
              : PrivateAlphaCohortTrack.selfServe,
        ),
    ];

PrivateAlphaCohortParticipantEvidence _participant({
  required String code,
  PrivateAlphaCohortTrack track = PrivateAlphaCohortTrack.observed,
  PrivateAlphaCohortConsent consent = PrivateAlphaCohortConsent.accepted,
  PrivateAlphaCohortInvitation invitation =
      PrivateAlphaCohortInvitation.complete,
  bool d0GroundedTurnCompleted = true,
  PrivateAlphaCohortPhaseStatus d14Status =
      PrivateAlphaCohortPhaseStatus.completed,
  PrivateAlphaLearningClaimStatus learningClaimStatus =
      PrivateAlphaLearningClaimStatus.supported,
  String d0Reference = 'EV-D0-001',
}) {
  return PrivateAlphaCohortParticipantEvidence(
    code: code,
    track: track,
    consent: consent,
    invitation: invitation,
    profileFingerprint:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    credentialScope: PrivateAlphaCredentialScope.controlled,
    d0Status: PrivateAlphaCohortPhaseStatus.completed,
    d0GroundedTurnCompleted: d0GroundedTurnCompleted,
    d0EvidenceReference: d0Reference,
    d7Status: PrivateAlphaCohortPhaseStatus.completed,
    d7GroundedTurnCompleted: true,
    d7EvidenceReference: 'EV-D7-$code',
    d14Status: d14Status,
    learningClaimStatus: learningClaimStatus,
    d14EvidenceReference: 'EV-D14-$code',
  );
}

PrivateAlphaReleaseDayAcceptanceEvidence _acceptance(String fingerprint) {
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
        apkSha256: List.filled(64, 'd').join(),
        credentialScope: PrivateAlphaCredentialScope.controlled,
        cases: const {},
      ),
    ],
  );
}
