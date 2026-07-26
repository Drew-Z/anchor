import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class PrivateAlphaAutomatedGateEvidence {
  final DateTime completedAt;
  final int testsPassed;
  final int analyzerErrors;
  final int analyzerWarnings;
  final bool formatPassed;
  final bool diffCheckPassed;

  const PrivateAlphaAutomatedGateEvidence({
    required this.completedAt,
    required this.testsPassed,
    required this.analyzerErrors,
    required this.analyzerWarnings,
    required this.formatPassed,
    required this.diffCheckPassed,
  });

  factory PrivateAlphaAutomatedGateEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final completedAt = DateTime.tryParse(_readString(json, 'completed_at'));
    if (completedAt == null) {
      throw const FormatException(
        'automated_gate.completed_at must be an ISO-8601 timestamp.',
      );
    }
    return PrivateAlphaAutomatedGateEvidence(
      completedAt: completedAt.toUtc(),
      testsPassed: _readNonNegativeInt(json, 'tests_passed'),
      analyzerErrors: _readNonNegativeInt(json, 'analyzer_errors'),
      analyzerWarnings: _readNonNegativeInt(json, 'analyzer_warnings'),
      formatPassed: _readBool(json, 'format_passed'),
      diffCheckPassed: _readBool(json, 'diff_check_passed'),
    );
  }

  bool get isPassing =>
      testsPassed > 0 &&
      analyzerErrors == 0 &&
      analyzerWarnings == 0 &&
      formatPassed &&
      diffCheckPassed;
}

class PrivateAlphaAndroidBuildEvidence {
  final String apkPath;
  final int bytes;
  final String sha256;
  final bool arm64Only;
  final bool v2Signed;

  const PrivateAlphaAndroidBuildEvidence({
    required this.apkPath,
    required this.bytes,
    required this.sha256,
    required this.arm64Only,
    required this.v2Signed,
  });

  factory PrivateAlphaAndroidBuildEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final apkPath = _readString(json, 'apk_path').trim();
    if (apkPath.isEmpty || p.isAbsolute(apkPath)) {
      throw const FormatException(
        'android_build.apk_path must be a non-empty repository-relative path.',
      );
    }
    final hash = _readString(json, 'sha256').trim().toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      throw const FormatException(
        'android_build.sha256 must contain 64 hexadecimal characters.',
      );
    }
    return PrivateAlphaAndroidBuildEvidence(
      apkPath: p.normalize(apkPath),
      bytes: _readPositiveInt(json, 'bytes'),
      sha256: hash,
      arm64Only: _readBool(json, 'arm64_only'),
      v2Signed: _readBool(json, 'v2_signed'),
    );
  }

  bool get isDeclaredPassing => arm64Only && v2Signed;
}

class PrivateAlphaReleaseEvidence {
  final int schemaVersion;
  final PrivateAlphaAutomatedGateEvidence automatedGate;
  final PrivateAlphaAndroidBuildEvidence androidBuild;

  const PrivateAlphaReleaseEvidence({
    required this.schemaVersion,
    required this.automatedGate,
    required this.androidBuild,
  });

  factory PrivateAlphaReleaseEvidence.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _readPositiveInt(json, 'schema_version');
    if (schemaVersion != 2) {
      throw const FormatException('schema_version must be 2.');
    }
    return PrivateAlphaReleaseEvidence(
      schemaVersion: schemaVersion,
      automatedGate: PrivateAlphaAutomatedGateEvidence.fromJson(
        _readMap(json, 'automated_gate'),
      ),
      androidBuild: PrivateAlphaAndroidBuildEvidence.fromJson(
        _readMap(json, 'android_build'),
      ),
    );
  }
}

class PrivateAlphaReleaseEvidenceVerification {
  final List<String> blockers;

  const PrivateAlphaReleaseEvidenceVerification(this.blockers);

  bool get passed => blockers.isEmpty;
}

class PrivateAlphaReleaseEvidenceVerifier {
  const PrivateAlphaReleaseEvidenceVerifier();

  Future<PrivateAlphaReleaseEvidenceVerification> verify({
    required PrivateAlphaReleaseEvidence evidence,
    required String repositoryRoot,
  }) async {
    final blockers = <String>[
      if (!evidence.automatedGate.isPassing) 'automated_gate_evidence_invalid',
      if (!evidence.androidBuild.isDeclaredPassing)
        'android_build_evidence_invalid',
    ];
    final root = p.normalize(p.absolute(repositoryRoot));
    final apkPath =
        p.normalize(p.absolute(root, evidence.androidBuild.apkPath));
    if (!p.isWithin(root, apkPath)) {
      blockers.add('android_build_path_outside_repository');
      return PrivateAlphaReleaseEvidenceVerification(
        List.unmodifiable(blockers),
      );
    }
    final apk = File(apkPath);
    if (!await apk.exists()) {
      blockers.add('android_build_apk_missing');
      return PrivateAlphaReleaseEvidenceVerification(
        List.unmodifiable(blockers),
      );
    }
    if (await apk.length() != evidence.androidBuild.bytes) {
      blockers.add('android_build_bytes_mismatch');
    }
    final actualHash = await sha256.bind(apk.openRead()).first;
    if (actualHash.toString() != evidence.androidBuild.sha256) {
      blockers.add('android_build_sha256_mismatch');
    }
    return PrivateAlphaReleaseEvidenceVerification(
      List.unmodifiable(blockers),
    );
  }
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$key must be a JSON object.');
  }
  return value;
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string.');
  return value;
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

int _readPositiveInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value <= 0) {
    throw FormatException('$key must be a positive integer.');
  }
  return value;
}

int _readNonNegativeInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value < 0) {
    throw FormatException('$key must be a non-negative integer.');
  }
  return value;
}
