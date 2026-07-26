import 'private_alpha_cohort_evidence.dart';
import 'private_alpha_controlled_credential_evidence.dart';
import 'private_alpha_model_acceptance_evidence.dart';
import 'private_alpha_operator_pack_evidence.dart';

class PrivateAlphaReleaseConsistencyVerification {
  final List<String> blockers;

  const PrivateAlphaReleaseConsistencyVerification(this.blockers);
}

class PrivateAlphaReleaseConsistencyVerifier {
  const PrivateAlphaReleaseConsistencyVerifier();

  PrivateAlphaReleaseConsistencyVerification verify({
    required PrivateAlphaReleaseDayAcceptanceEvidence acceptanceEvidence,
    required PrivateAlphaControlledCredentialEvidence credentialEvidence,
    required PrivateAlphaOperatorPackEvidence operatorEvidence,
    required PrivateAlphaCohortEvidence cohortEvidence,
  }) {
    final blockers = <String>[];
    if (cohortEvidence.decision != PrivateAlphaCohortDecision.go) {
      blockers.add('release_consistency_cohort_decision_not_go');
    }
    if (cohortEvidence.operatorRecordLocator !=
        operatorEvidence.externalRecordLocator) {
      blockers.add('release_consistency_operator_locator_mismatch');
    }

    final acceptedProfiles = {
      for (final profile in acceptanceEvidence.profiles)
        profile.fingerprint: profile.credentialScope,
    };
    final credentialBindings = {
      for (final binding in credentialEvidence.bindings)
        binding.profileFingerprint: binding.scope,
    };
    for (final participant in cohortEvidence.participants) {
      final acceptedScope = acceptedProfiles[participant.profileFingerprint];
      if (acceptedScope == null ||
          acceptedScope != participant.credentialScope) {
        blockers.add('release_consistency_profile_binding_mismatch');
      }
      final credentialScope =
          credentialBindings[participant.profileFingerprint];
      if (credentialScope == null ||
          credentialScope != participant.credentialScope) {
        blockers.add('release_consistency_scope_mismatch');
      }
    }
    return PrivateAlphaReleaseConsistencyVerification(
      List.unmodifiable(blockers.toSet()),
    );
  }
}
