import 'package:anchor_learning/services/release/private_alpha_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PrivateAlphaReadinessService();

  test('holds with stable blockers for current external release gaps', () {
    final report = service.evaluate(
      const PrivateAlphaReadinessEvidence(
        automatedGatePassed: true,
        androidBuildVerified: true,
        physicalDevicePassed: false,
        controlledCredentialAvailable: false,
        dataProcessingOwnerAssigned: false,
        releaseDayAcceptancePassed: false,
        cohortCompleted: false,
      ),
    );

    expect(report.status, PrivateAlphaReadinessStatus.hold);
    expect(report.blockers, [
      'physical_device_pending',
      'controlled_credential_required',
      'data_processing_owner_required',
      'release_day_acceptance_pending',
      'cohort_pending',
    ]);
    expect(report.toJson()['status'], 'HOLD');
  });

  test('go requires evidence for every release gate', () {
    final report = service.evaluate(
      const PrivateAlphaReadinessEvidence(
        automatedGatePassed: true,
        androidBuildVerified: true,
        physicalDevicePassed: true,
        controlledCredentialAvailable: true,
        dataProcessingOwnerAssigned: true,
        releaseDayAcceptancePassed: true,
        cohortCompleted: true,
      ),
    );

    expect(report.status, PrivateAlphaReadinessStatus.go);
    expect(report.blockers, isEmpty);
    expect(report.toMarkdown(), contains('Status: `GO`'));
  });

  test('rejects missing and non-boolean evidence fields', () {
    expect(
      () => PrivateAlphaReadinessEvidence.fromJson(const {}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PrivateAlphaReadinessEvidence.fromJson(const {
        'automated_gate_passed': 'yes',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
