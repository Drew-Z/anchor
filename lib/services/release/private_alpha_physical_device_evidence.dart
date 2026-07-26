class PrivateAlphaPhysicalDeviceEvidence {
  final DateTime completedAt;
  final String status;
  final String apkSha256;
  final String deviceKind;
  final String abi;
  final int apiLevel;
  final bool executionRequested;
  final bool executionAttempted;
  final bool installSucceeded;
  final bool coldStartSucceeded;
  final bool processAlive;
  final int logErrorMatches;

  const PrivateAlphaPhysicalDeviceEvidence({
    required this.completedAt,
    required this.status,
    required this.apkSha256,
    required this.deviceKind,
    required this.abi,
    required this.apiLevel,
    required this.executionRequested,
    required this.executionAttempted,
    required this.installSucceeded,
    required this.coldStartSucceeded,
    required this.processAlive,
    required this.logErrorMatches,
  });

  factory PrivateAlphaPhysicalDeviceEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final value = json['physical_device_evidence'];
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'physical_device_evidence must be a JSON object.',
      );
    }
    final completedAt = DateTime.tryParse(_string(value, 'completed_at'));
    if (completedAt == null) {
      throw const FormatException(
        'physical_device_evidence.completed_at must be ISO-8601.',
      );
    }
    final report = _map(value, 'report');
    final apk = _map(report, 'apk');
    final device = _map(report, 'device');
    final execution = _map(report, 'execution');
    return PrivateAlphaPhysicalDeviceEvidence(
      completedAt: completedAt.toUtc(),
      status: _string(report, 'status').toUpperCase(),
      apkSha256: _hash(apk, 'sha256'),
      deviceKind: _string(device, 'kind').toLowerCase(),
      abi: _string(device, 'abi').toLowerCase(),
      apiLevel: _integer(device, 'api_level'),
      executionRequested: _boolean(execution, 'requested'),
      executionAttempted: _boolean(execution, 'attempted'),
      installSucceeded: _boolean(execution, 'install_succeeded'),
      coldStartSucceeded: _boolean(execution, 'cold_start_succeeded'),
      processAlive: _boolean(execution, 'process_alive'),
      logErrorMatches: _integer(execution, 'log_error_matches'),
    );
  }
}

class PrivateAlphaPhysicalDeviceVerification {
  final List<String> blockers;

  const PrivateAlphaPhysicalDeviceVerification(this.blockers);
}

class PrivateAlphaPhysicalDeviceEvidenceVerifier {
  final Duration maximumAge;

  const PrivateAlphaPhysicalDeviceEvidenceVerifier({
    this.maximumAge = const Duration(hours: 24),
  });

  PrivateAlphaPhysicalDeviceVerification verify({
    required PrivateAlphaPhysicalDeviceEvidence evidence,
    required String expectedApkSha256,
    required DateTime evaluatedAt,
  }) {
    final blockers = <String>[];
    if (evidence.status != 'PASSED') {
      blockers.add('physical_device_evidence_not_passed');
    }
    if (evidence.deviceKind != 'physical') {
      blockers.add('physical_device_required');
    }
    if (!evidence.abi.contains('arm64') && !evidence.abi.contains('aarch64')) {
      blockers.add('physical_device_arm64_required');
    }
    if (evidence.apiLevel < 24 || evidence.apiLevel > 35) {
      blockers.add('physical_device_api_24_to_35_required');
    }
    if (!evidence.executionRequested || !evidence.executionAttempted) {
      blockers.add('physical_device_execution_required');
    }
    if (!evidence.installSucceeded ||
        !evidence.coldStartSucceeded ||
        !evidence.processAlive ||
        evidence.logErrorMatches != 0) {
      blockers.add('physical_device_smoke_failed');
    }
    if (evidence.apkSha256 != expectedApkSha256.toLowerCase()) {
      blockers.add('physical_device_apk_mismatch');
    }
    final age = evaluatedAt.toUtc().difference(evidence.completedAt);
    if (age.isNegative || age > maximumAge) {
      blockers.add('physical_device_evidence_stale');
    }
    return PrivateAlphaPhysicalDeviceVerification(
      List.unmodifiable(blockers),
    );
  }
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$key must be a JSON object.');
  }
  return value;
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value.trim();
}

bool _boolean(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

String _hash(Map<String, dynamic> json, String key) {
  final value = _string(json, key).toLowerCase();
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw FormatException('$key must contain 64 hexadecimal characters.');
  }
  return value;
}
