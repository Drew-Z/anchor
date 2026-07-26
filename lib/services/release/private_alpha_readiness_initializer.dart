import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class PrivateAlphaReadinessInitializer {
  const PrivateAlphaReadinessInitializer();

  Future<Map<String, dynamic>> build({
    required String repositoryRoot,
    required String apkPath,
    required String outputPath,
    required DateTime completedAt,
    required int testsPassed,
    required int analyzerErrors,
    required int analyzerWarnings,
    required bool formatPassed,
    required bool diffCheckPassed,
    required bool arm64Only,
    required bool v2Signed,
  }) async {
    if (testsPassed <= 0 || analyzerErrors < 0 || analyzerWarnings < 0) {
      throw const FormatException(
        'Test and analyzer counts must be non-negative, with tests > 0.',
      );
    }
    final root = p.normalize(p.absolute(repositoryRoot));
    final normalizedApkPath = _repositoryRelativePath(
      root: root,
      value: apkPath,
      label: 'APK',
    );
    final normalizedOutputPath = _repositoryRelativePath(
      root: root,
      value: outputPath,
      label: 'Output',
    );
    if (!p.isWithin('build', normalizedOutputPath)) {
      throw const FormatException(
        'Output must stay under the ignored build directory.',
      );
    }
    final apk = File(p.join(root, normalizedApkPath));
    if (!await apk.exists()) {
      throw const FileSystemException('APK does not exist.');
    }
    final bytes = await apk.length();
    final hash = await sha256.bind(apk.openRead()).first;
    final automatedGatePassed = analyzerErrors == 0 &&
        analyzerWarnings == 0 &&
        formatPassed &&
        diffCheckPassed;
    final androidBuildVerified = arm64Only && v2Signed;

    return {
      'schema_version': 2,
      'privacy_scan': {
        'paths': [normalizedOutputPath],
      },
      'automated_gate': {
        'completed_at': completedAt.toUtc().toIso8601String(),
        'tests_passed': testsPassed,
        'analyzer_errors': analyzerErrors,
        'analyzer_warnings': analyzerWarnings,
        'format_passed': formatPassed,
        'diff_check_passed': diffCheckPassed,
      },
      'android_build': {
        'apk_path': normalizedApkPath,
        'bytes': bytes,
        'sha256': hash.toString(),
        'arm64_only': arm64Only,
        'v2_signed': v2Signed,
      },
      'automated_gate_passed': automatedGatePassed,
      'android_build_verified': androidBuildVerified,
      'physical_device_passed': false,
      'controlled_credential_available': false,
      'data_processing_owner_assigned': false,
      'release_day_acceptance_passed': false,
      'cohort_completed': false,
    };
  }

  String _repositoryRelativePath({
    required String root,
    required String value,
    required String label,
  }) {
    if (value.trim().isEmpty || p.isAbsolute(value)) {
      throw FormatException('$label path must be repository-relative.');
    }
    final normalized = p.normalize(value.trim());
    final absolute = p.normalize(p.absolute(root, normalized));
    if (!p.isWithin(root, absolute)) {
      throw FormatException('$label path must stay inside the repository.');
    }
    return normalized;
  }
}
