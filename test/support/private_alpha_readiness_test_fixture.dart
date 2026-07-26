import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dlg_q/services/release/private_alpha_operator_pack_evidence.dart';

class PrivateAlphaReadinessTestFixture {
  final Directory root;
  final Map<String, dynamic> evidence;

  const PrivateAlphaReadinessTestFixture(this.root, this.evidence);

  Future<File> writeEvidence({String name = 'readiness.json'}) async {
    final file = File('${root.path}${Platform.pathSeparator}$name');
    await file.writeAsString(_jsonEncoder.convert(evidence));
    return file;
  }
}

Future<PrivateAlphaReadinessTestFixture> createPrivateAlphaReadinessFixture(
  DateTime evaluatedAt, {
  String decision = 'go',
}) async {
  final root = await Directory.systemTemp.createTemp('duoduo-readiness-go-');
  final apk = File('${root.path}${Platform.pathSeparator}build'
      '${Platform.pathSeparator}app.apk');
  await apk.parent.create(recursive: true);
  final apkBytes = List<int>.generate(64, (index) => index);
  await apk.writeAsBytes(apkBytes);
  final apkHash = sha256.convert(apkBytes).toString();

  final cleanArtifact = File('${root.path}${Platform.pathSeparator}evidence'
      '${Platform.pathSeparator}clean.txt');
  await cleanArtifact.parent.create(recursive: true);
  await cleanArtifact.writeAsString('anonymous release evidence\n');

  for (final template in PrivateAlphaOperatorPackVerifier.approvedTemplates) {
    final source = File(template.relativePath);
    final target = File(
      '${root.path}${Platform.pathSeparator}'
      '${template.relativePath.replaceAll('/', Platform.pathSeparator)}',
    );
    await target.parent.create(recursive: true);
    await source.copy(target.path);
  }

  const providerId = 'custom';
  const endpoint = 'https://relay.example/v1';
  const model = 'grok-4.5';
  const protocol = 'responses';
  final fingerprint = sha256
      .convert('$providerId|$endpoint|$model|$protocol'.codeUnits)
      .toString();
  final completedAt = evaluatedAt.subtract(const Duration(hours: 1));
  final frozenAt = evaluatedAt.subtract(const Duration(hours: 3));
  final decisionAt = evaluatedAt.subtract(const Duration(hours: 2));
  const cases = {
    'structuredJson': 'passed',
    'chinesePoem': 'passed',
    'dartCoding': 'passed',
    'claimGrounding': 'passed',
    'evidenceRefusal': 'passed',
  };

  return PrivateAlphaReadinessTestFixture(root, {
    'schema_version': 2,
    'privacy_scan': {
      'paths': ['evidence/clean.txt'],
    },
    'automated_gate': {
      'completed_at': frozenAt.toIso8601String(),
      'tests_passed': 1,
      'analyzer_errors': 0,
      'analyzer_warnings': 0,
      'format_passed': true,
      'diff_check_passed': true,
    },
    'android_build': {
      'apk_path': 'build/app.apk',
      'bytes': apkBytes.length,
      'sha256': apkHash,
      'arm64_only': true,
      'v2_signed': true,
    },
    'automated_gate_passed': true,
    'android_build_verified': true,
    'physical_device_passed': true,
    'controlled_credential_available': true,
    'data_processing_owner_assigned': true,
    'release_day_acceptance_passed': true,
    'cohort_completed': true,
    'release_day_acceptance': {
      'fallback_offered': false,
      'profiles': [
        {
          'role': 'primary',
          'provider_id': providerId,
          'endpoint': endpoint,
          'model': model,
          'protocol': protocol,
          'fingerprint': fingerprint,
          'completed_at': completedAt.toIso8601String(),
          'apk_sha256': apkHash,
          'credential_scope': 'controlled',
          'cases': cases,
        },
      ],
    },
    'controlled_credential': {
      'bindings': [
        {
          'role': 'primary',
          'scope': 'controlled',
          'credential_reference': 'CRED-PRIMARY-001',
          'profile_fingerprint': fingerprint,
          'quota_owner_declared': true,
          'quota_limit_known': true,
          'revocation_supported': true,
          'revocation_owner_declared': true,
          'retention_policy_declared': true,
          'data_handling_policy_declared': true,
        },
      ],
    },
    'operator_pack': {
      'role_codes': [
        'alphaOwner',
        'privacyReviewer',
        'reliabilityOwner',
      ],
      'external_record_locator': 'OPS-ALPHA-001',
      'access_restricted': true,
      'retention_policy_declared': true,
      'deletion_procedure_declared': true,
      'incident_response_declared': true,
    },
    'physical_device_evidence': {
      'completed_at': completedAt.toIso8601String(),
      'report': {
        'status': 'PASSED',
        'apk': {'sha256': apkHash},
        'device': {
          'kind': 'physical',
          'abi': 'arm64-v8a',
          'api_level': 35,
        },
        'execution': {
          'requested': true,
          'attempted': true,
          'install_succeeded': true,
          'cold_start_succeeded': true,
          'process_alive': true,
          'log_error_matches': 0,
        },
      },
    },
    'cohort_evidence': {
      'freeze_reference': 'COHORT-ALPHA-001',
      'frozen_at': frozenAt.toIso8601String(),
      'formal_denominator': 10,
      'apk_sha256': apkHash,
      'profile_fingerprints': [fingerprint],
      'participants': [
        for (var index = 1; index <= 10; index++)
          {
            'code': 'A${index.toString().padLeft(2, '0')}',
            'track': index <= 5 ? 'observed' : 'selfServe',
            'consent': 'accepted',
            'invitation': 'complete',
            'profile_fingerprint': fingerprint,
            'credential_scope': 'controlled',
            'd0_status': 'completed',
            'd0_grounded_turn_completed': true,
            'd0_evidence_reference': 'EV-D0-A$index',
            'd7_status': 'completed',
            'd7_grounded_turn_completed': true,
            'd7_evidence_reference': 'EV-D7-A$index',
            'd14_status': 'completed',
            'learning_claim_status': 'supported',
            'd14_evidence_reference': 'EV-D14-A$index',
          },
      ],
      'decision': decision,
      'decision_at': decisionAt.toIso8601String(),
      'report_reference': 'REPORT-ALPHA-001',
      'operator_record_locator': 'OPS-ALPHA-001',
    },
  });
}

const _jsonEncoder = JsonEncoder.withIndent('  ');
