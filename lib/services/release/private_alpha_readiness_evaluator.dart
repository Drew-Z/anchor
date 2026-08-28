import 'private_alpha_cohort_evidence.dart';
import 'private_alpha_controlled_credential_evidence.dart';
import 'private_alpha_model_acceptance_evidence.dart';
import 'private_alpha_operator_pack_evidence.dart';
import 'private_alpha_physical_device_evidence.dart';
import 'private_alpha_privacy_scan.dart';
import 'private_alpha_readiness.dart';
import 'private_alpha_release_consistency.dart';
import 'private_alpha_release_evidence.dart';

class PrivateAlphaReadinessEvaluator {
  const PrivateAlphaReadinessEvaluator();

  Future<PrivateAlphaReadinessReport> evaluate({
    required Map<String, dynamic> json,
    required String repositoryRoot,
    required DateTime evaluatedAt,
  }) async {
    final evidence = PrivateAlphaReadinessEvidence.fromJson(json);
    final releaseEvidence = PrivateAlphaReleaseEvidence.fromJson(json);
    final releaseVerification =
        await const PrivateAlphaReleaseEvidenceVerifier().verify(
      evidence: releaseEvidence,
      repositoryRoot: repositoryRoot,
      evaluatedAt: evaluatedAt,
    );
    final privacyEvidence = PrivateAlphaPrivacyScanEvidence.fromJson(json);
    final privacyScan = await const PrivateAlphaPrivacyScanner().scan(
      repositoryRoot: repositoryRoot,
      evidence: privacyEvidence,
    );

    PrivateAlphaReleaseDayAcceptanceEvidence? acceptanceEvidence;
    final modelAcceptanceBlockers = <String>[];
    if (evidence.releaseDayAcceptancePassed) {
      acceptanceEvidence =
          PrivateAlphaReleaseDayAcceptanceEvidence.fromJson(json);
      modelAcceptanceBlockers.addAll(
        const PrivateAlphaModelAcceptanceEvidenceVerifier()
            .verify(
              evidence: acceptanceEvidence,
              expectedApkSha256: releaseEvidence.androidBuild.sha256,
              evaluatedAt: evaluatedAt,
            )
            .blockers,
      );
    }

    PrivateAlphaControlledCredentialEvidence? credentialEvidence;
    final controlledCredentialBlockers = <String>[];
    if (evidence.controlledCredentialAvailable) {
      credentialEvidence =
          PrivateAlphaControlledCredentialEvidence.fromJson(json);
      controlledCredentialBlockers.addAll(
        const PrivateAlphaControlledCredentialEvidenceVerifier()
            .verify(
              evidence: credentialEvidence,
              acceptanceEvidence: acceptanceEvidence,
            )
            .blockers,
      );
    }

    PrivateAlphaOperatorPackEvidence? operatorEvidence;
    final operatorPackBlockers = <String>[];
    if (evidence.dataProcessingOwnerAssigned) {
      operatorEvidence = PrivateAlphaOperatorPackEvidence.fromJson(json);
      operatorPackBlockers.addAll(
        (await const PrivateAlphaOperatorPackVerifier().verify(
          evidence: operatorEvidence,
          repositoryRoot: repositoryRoot,
        ))
            .blockers,
      );
    }

    final physicalDeviceBlockers = <String>[];
    if (evidence.physicalDevicePassed) {
      final physicalEvidence =
          PrivateAlphaPhysicalDeviceEvidence.fromJson(json);
      physicalDeviceBlockers.addAll(
        const PrivateAlphaPhysicalDeviceEvidenceVerifier()
            .verify(
              evidence: physicalEvidence,
              expectedApkSha256: releaseEvidence.androidBuild.sha256,
              evaluatedAt: evaluatedAt,
            )
            .blockers,
      );
    }

    PrivateAlphaCohortEvidence? cohortEvidence;
    final cohortBlockers = <String>[];
    if (evidence.cohortCompleted) {
      cohortEvidence = PrivateAlphaCohortEvidence.fromJson(json);
      cohortBlockers.addAll(
        const PrivateAlphaCohortEvidenceVerifier()
            .verify(
              evidence: cohortEvidence,
              expectedApkSha256: releaseEvidence.androidBuild.sha256,
              acceptanceEvidence: acceptanceEvidence,
              evaluatedAt: evaluatedAt,
            )
            .blockers,
      );
    }

    final consistencyBlockers = <String>[];
    if (acceptanceEvidence != null &&
        credentialEvidence != null &&
        operatorEvidence != null &&
        cohortEvidence != null) {
      consistencyBlockers.addAll(
        const PrivateAlphaReleaseConsistencyVerifier()
            .verify(
              acceptanceEvidence: acceptanceEvidence,
              credentialEvidence: credentialEvidence,
              operatorEvidence: operatorEvidence,
              cohortEvidence: cohortEvidence,
            )
            .blockers,
      );
    }

    return const PrivateAlphaReadinessService().evaluate(
      evidence,
      additionalBlockers: [
        ...releaseVerification.blockers,
        ...privacyScan.blockers,
        ...modelAcceptanceBlockers,
        ...controlledCredentialBlockers,
        ...operatorPackBlockers,
        ...physicalDeviceBlockers,
        ...cohortBlockers,
        ...consistencyBlockers,
      ],
    );
  }
}
