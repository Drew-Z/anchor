import 'private_alpha_model_acceptance_evidence.dart';

enum PrivateAlphaCohortTrack { observed, selfServe }

enum PrivateAlphaCohortConsent { accepted, declined, withdrawn }

enum PrivateAlphaCohortInvitation { complete, declined, withdrawn }

enum PrivateAlphaCohortPhaseStatus { completed, blocked, absent, withdrawn }

enum PrivateAlphaLearningClaimStatus { supported, unsupported, unclear, none }

enum PrivateAlphaCohortDecision { go, conditionalGo, noGo }

class PrivateAlphaCohortParticipantEvidence {
  final String code;
  final PrivateAlphaCohortTrack track;
  final PrivateAlphaCohortConsent consent;
  final PrivateAlphaCohortInvitation invitation;
  final String profileFingerprint;
  final PrivateAlphaCredentialScope credentialScope;
  final PrivateAlphaCohortPhaseStatus d0Status;
  final bool d0GroundedTurnCompleted;
  final String d0EvidenceReference;
  final PrivateAlphaCohortPhaseStatus d7Status;
  final bool d7GroundedTurnCompleted;
  final String d7EvidenceReference;
  final PrivateAlphaCohortPhaseStatus d14Status;
  final PrivateAlphaLearningClaimStatus learningClaimStatus;
  final String d14EvidenceReference;

  const PrivateAlphaCohortParticipantEvidence({
    required this.code,
    required this.track,
    required this.consent,
    required this.invitation,
    required this.profileFingerprint,
    required this.credentialScope,
    required this.d0Status,
    required this.d0GroundedTurnCompleted,
    required this.d0EvidenceReference,
    required this.d7Status,
    required this.d7GroundedTurnCompleted,
    required this.d7EvidenceReference,
    required this.d14Status,
    required this.learningClaimStatus,
    required this.d14EvidenceReference,
  });

  factory PrivateAlphaCohortParticipantEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    return PrivateAlphaCohortParticipantEvidence(
      code: _requiredString(json, 'code').toUpperCase(),
      track: _requiredEnum(
        json,
        'track',
        PrivateAlphaCohortTrack.values,
      ),
      consent: _requiredEnum(
        json,
        'consent',
        PrivateAlphaCohortConsent.values,
      ),
      invitation: _requiredEnum(
        json,
        'invitation',
        PrivateAlphaCohortInvitation.values,
      ),
      profileFingerprint: _requiredHash(json, 'profile_fingerprint'),
      credentialScope: _requiredEnum(
        json,
        'credential_scope',
        PrivateAlphaCredentialScope.values,
      ),
      d0Status: _requiredEnum(
        json,
        'd0_status',
        PrivateAlphaCohortPhaseStatus.values,
      ),
      d0GroundedTurnCompleted:
          _requiredBool(json, 'd0_grounded_turn_completed'),
      d0EvidenceReference: _requiredString(json, 'd0_evidence_reference'),
      d7Status: _requiredEnum(
        json,
        'd7_status',
        PrivateAlphaCohortPhaseStatus.values,
      ),
      d7GroundedTurnCompleted:
          _requiredBool(json, 'd7_grounded_turn_completed'),
      d7EvidenceReference: _requiredString(json, 'd7_evidence_reference'),
      d14Status: _requiredEnum(
        json,
        'd14_status',
        PrivateAlphaCohortPhaseStatus.values,
      ),
      learningClaimStatus: _requiredEnum(
        json,
        'learning_claim_status',
        PrivateAlphaLearningClaimStatus.values,
      ),
      d14EvidenceReference: _requiredString(json, 'd14_evidence_reference'),
    );
  }
}

class PrivateAlphaCohortEvidence {
  static final formalParticipantCodes = {
    for (var index = 1; index <= 10; index++)
      'A${index.toString().padLeft(2, '0')}',
  };

  final String freezeReference;
  final DateTime frozenAt;
  final int formalDenominator;
  final String apkSha256;
  final Set<String> profileFingerprints;
  final List<PrivateAlphaCohortParticipantEvidence> participants;
  final PrivateAlphaCohortDecision decision;
  final DateTime decisionAt;
  final String reportReference;
  final String operatorRecordLocator;

  const PrivateAlphaCohortEvidence({
    required this.freezeReference,
    required this.frozenAt,
    required this.formalDenominator,
    required this.apkSha256,
    required this.profileFingerprints,
    required this.participants,
    required this.decision,
    required this.decisionAt,
    required this.reportReference,
    required this.operatorRecordLocator,
  });

  factory PrivateAlphaCohortEvidence.fromJson(Map<String, dynamic> json) {
    final value = json['cohort_evidence'];
    if (value is! Map<String, dynamic>) {
      throw const FormatException('cohort_evidence must be a JSON object.');
    }
    final rawFingerprints = value['profile_fingerprints'];
    final rawParticipants = value['participants'];
    if (rawFingerprints is! List || rawParticipants is! List) {
      throw const FormatException(
        'cohort_evidence requires profile_fingerprints and participants arrays.',
      );
    }
    return PrivateAlphaCohortEvidence(
      freezeReference: _requiredString(value, 'freeze_reference'),
      frozenAt: _requiredDate(value, 'frozen_at'),
      formalDenominator: _requiredInt(value, 'formal_denominator'),
      apkSha256: _requiredHash(value, 'apk_sha256'),
      profileFingerprints: Set.unmodifiable(
        rawFingerprints.map((item) {
          if (item is! String || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(item)) {
            throw const FormatException(
              'profile_fingerprints must contain SHA-256 values.',
            );
          }
          return item.toLowerCase();
        }),
      ),
      participants: List.unmodifiable(
        rawParticipants.map((item) {
          if (item is! Map) {
            throw const FormatException(
              'cohort_evidence participants must be JSON objects.',
            );
          }
          return PrivateAlphaCohortParticipantEvidence.fromJson(
            Map<String, dynamic>.from(item),
          );
        }),
      ),
      decision: _requiredEnum(
        value,
        'decision',
        PrivateAlphaCohortDecision.values,
      ),
      decisionAt: _requiredDate(value, 'decision_at'),
      reportReference: _requiredString(value, 'report_reference'),
      operatorRecordLocator: _requiredString(value, 'operator_record_locator'),
    );
  }
}

class PrivateAlphaCohortVerification {
  final List<String> blockers;

  const PrivateAlphaCohortVerification(this.blockers);
}

class PrivateAlphaCohortEvidenceVerifier {
  const PrivateAlphaCohortEvidenceVerifier();

  PrivateAlphaCohortVerification verify({
    required PrivateAlphaCohortEvidence evidence,
    required String expectedApkSha256,
    required PrivateAlphaReleaseDayAcceptanceEvidence? acceptanceEvidence,
    required DateTime evaluatedAt,
  }) {
    final blockers = <String>[];
    if (evidence.formalDenominator != 10) {
      blockers.add('cohort_denominator_invalid');
    }
    final codes = evidence.participants.map((item) => item.code).toList();
    if (codes.length != 10 ||
        codes.toSet().length != codes.length ||
        codes
            .toSet()
            .difference(PrivateAlphaCohortEvidence.formalParticipantCodes)
            .isNotEmpty ||
        PrivateAlphaCohortEvidence.formalParticipantCodes
            .difference(codes.toSet())
            .isNotEmpty) {
      blockers.add('cohort_participant_set_invalid');
    }
    if (evidence.apkSha256 != expectedApkSha256.toLowerCase()) {
      blockers.add('cohort_apk_mismatch');
    }
    if (acceptanceEvidence == null) {
      blockers.add('cohort_release_day_binding_required');
    } else {
      final acceptedFingerprints = acceptanceEvidence.profiles
          .map((profile) => profile.fingerprint)
          .toSet();
      if (evidence.profileFingerprints.length != acceptedFingerprints.length ||
          evidence.profileFingerprints
              .difference(acceptedFingerprints)
              .isNotEmpty ||
          acceptedFingerprints
              .difference(evidence.profileFingerprints)
              .isNotEmpty) {
        blockers.add('cohort_profile_binding_mismatch');
      }
    }
    if (!_isReference(evidence.freezeReference, 'COHORT') ||
        !_isReference(evidence.reportReference, 'REPORT')) {
      blockers.add('cohort_record_reference_invalid');
    }
    if (evidence.frozenAt.isAfter(evaluatedAt.toUtc()) ||
        evidence.decisionAt.isAfter(evaluatedAt.toUtc()) ||
        evidence.decisionAt.isBefore(evidence.frozenAt)) {
      blockers.add('cohort_timeline_invalid');
    }

    for (final participant in evidence.participants) {
      final prefix = 'cohort_${participant.code.toLowerCase()}';
      final expectedTrack = RegExp(r'^A0[1-5]$').hasMatch(participant.code)
          ? PrivateAlphaCohortTrack.observed
          : PrivateAlphaCohortTrack.selfServe;
      if (participant.track != expectedTrack) {
        blockers.add('${prefix}_track_invalid');
      }
      final invitationMatchesConsent = participant.consent ==
              PrivateAlphaCohortConsent.accepted
          ? participant.invitation == PrivateAlphaCohortInvitation.complete
          : participant.consent == PrivateAlphaCohortConsent.declined
              ? participant.invitation == PrivateAlphaCohortInvitation.declined
              : participant.invitation ==
                  PrivateAlphaCohortInvitation.withdrawn;
      if (!invitationMatchesConsent) {
        blockers.add('${prefix}_consent_invalid');
      }
      if (!_isReference(participant.d0EvidenceReference, 'EV') ||
          !_isReference(participant.d7EvidenceReference, 'EV') ||
          !_isReference(participant.d14EvidenceReference, 'EV')) {
        blockers.add('${prefix}_phase_reference_invalid');
      }
      if (participant.d0Status == PrivateAlphaCohortPhaseStatus.completed &&
          !participant.d0GroundedTurnCompleted) {
        blockers.add('${prefix}_d0_activation_missing');
      }
      if (participant.d7Status == PrivateAlphaCohortPhaseStatus.completed &&
          !participant.d7GroundedTurnCompleted) {
        blockers.add('${prefix}_d7_closure_missing');
      }
      if (participant.consent == PrivateAlphaCohortConsent.accepted &&
          (participant.d0Status == PrivateAlphaCohortPhaseStatus.absent ||
              participant.d0Status == PrivateAlphaCohortPhaseStatus.withdrawn ||
              participant.d14Status == PrivateAlphaCohortPhaseStatus.absent ||
              participant.d14Status ==
                  PrivateAlphaCohortPhaseStatus.withdrawn)) {
        blockers.add('${prefix}_formal_phase_incomplete');
      }
      final hasLearningOutcome =
          participant.d14Status == PrivateAlphaCohortPhaseStatus.completed;
      if (hasLearningOutcome ==
          (participant.learningClaimStatus ==
              PrivateAlphaLearningClaimStatus.none)) {
        blockers.add('${prefix}_learning_outcome_invalid');
      }
    }
    return PrivateAlphaCohortVerification(
      List.unmodifiable(blockers.toSet()),
    );
  }

  bool _isReference(String value, String prefix) =>
      RegExp('^$prefix-[A-Z0-9-]{3,64}\$').hasMatch(value);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value.trim();
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final parsed = DateTime.tryParse(_requiredString(json, key));
  if (parsed == null) throw FormatException('$key must be ISO-8601.');
  return parsed.toUtc();
}

String _requiredHash(Map<String, dynamic> json, String key) {
  final value = _requiredString(json, key).toLowerCase();
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw FormatException('$key must contain 64 hexadecimal characters.');
  }
  return value;
}

T _requiredEnum<T extends Enum>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
) {
  final name = _requiredString(json, key);
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('$key contains an unsupported value.');
}
