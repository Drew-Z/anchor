enum PrivateAlphaReadinessStatus { go, hold }

class PrivateAlphaReadinessEvidence {
  final bool automatedGatePassed;
  final bool androidBuildVerified;
  final bool physicalDevicePassed;
  final bool controlledCredentialAvailable;
  final bool dataProcessingOwnerAssigned;
  final bool releaseDayAcceptancePassed;
  final bool cohortCompleted;

  const PrivateAlphaReadinessEvidence({
    required this.automatedGatePassed,
    required this.androidBuildVerified,
    required this.physicalDevicePassed,
    required this.controlledCredentialAvailable,
    required this.dataProcessingOwnerAssigned,
    required this.releaseDayAcceptancePassed,
    required this.cohortCompleted,
  });

  factory PrivateAlphaReadinessEvidence.fromJson(Map<String, dynamic> json) {
    bool readBool(String key) {
      final value = json[key];
      if (value is! bool) {
        throw FormatException('$key must be a boolean.');
      }
      return value;
    }

    return PrivateAlphaReadinessEvidence(
      automatedGatePassed: readBool('automated_gate_passed'),
      androidBuildVerified: readBool('android_build_verified'),
      physicalDevicePassed: readBool('physical_device_passed'),
      controlledCredentialAvailable:
          readBool('controlled_credential_available'),
      dataProcessingOwnerAssigned: readBool('data_processing_owner_assigned'),
      releaseDayAcceptancePassed: readBool('release_day_acceptance_passed'),
      cohortCompleted: readBool('cohort_completed'),
    );
  }
}

class PrivateAlphaReadinessReport {
  final PrivateAlphaReadinessStatus status;
  final List<String> blockers;

  const PrivateAlphaReadinessReport({
    required this.status,
    required this.blockers,
  });

  Map<String, dynamic> toJson() => {
        'status': status.name.toUpperCase(),
        'blockers': blockers,
      };

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Private Alpha Readiness')
      ..writeln()
      ..writeln('Status: `${status.name.toUpperCase()}`');
    if (blockers.isEmpty) {
      buffer.writeln('\nAll required release gates have attached evidence.');
    } else {
      buffer
        ..writeln('\nBlocking gates:')
        ..writeln();
      for (final blocker in blockers) {
        buffer.writeln('- `$blocker`');
      }
    }
    return buffer.toString().trimRight();
  }
}

class PrivateAlphaReadinessService {
  const PrivateAlphaReadinessService();

  PrivateAlphaReadinessReport evaluate(
    PrivateAlphaReadinessEvidence evidence, {
    List<String> additionalBlockers = const [],
  }) {
    final blockers = <String>[
      if (!evidence.automatedGatePassed) 'automated_gate_pending',
      if (!evidence.androidBuildVerified) 'android_build_pending',
      if (!evidence.physicalDevicePassed) 'physical_device_pending',
      if (!evidence.controlledCredentialAvailable)
        'controlled_credential_required',
      if (!evidence.dataProcessingOwnerAssigned)
        'data_processing_owner_required',
      if (!evidence.releaseDayAcceptancePassed)
        'release_day_acceptance_pending',
      if (!evidence.cohortCompleted) 'cohort_pending',
      ...additionalBlockers,
    ];
    return PrivateAlphaReadinessReport(
      status: blockers.isEmpty
          ? PrivateAlphaReadinessStatus.go
          : PrivateAlphaReadinessStatus.hold,
      blockers: List.unmodifiable(blockers),
    );
  }
}
