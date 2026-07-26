import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class PrivateAlphaOperatorTemplateSpec {
  final String id;
  final String relativePath;
  final String approvedSha256;
  final List<String> requiredHeadings;

  const PrivateAlphaOperatorTemplateSpec({
    required this.id,
    required this.relativePath,
    required this.approvedSha256,
    required this.requiredHeadings,
  });
}

class PrivateAlphaOperatorPackEvidence {
  static const requiredRoleCodes = {
    'alphaOwner',
    'privacyReviewer',
    'reliabilityOwner',
  };

  final Set<String> roleCodes;
  final String externalRecordLocator;
  final bool accessRestricted;
  final bool retentionPolicyDeclared;
  final bool deletionProcedureDeclared;
  final bool incidentResponseDeclared;

  const PrivateAlphaOperatorPackEvidence({
    required this.roleCodes,
    required this.externalRecordLocator,
    required this.accessRestricted,
    required this.retentionPolicyDeclared,
    required this.deletionProcedureDeclared,
    required this.incidentResponseDeclared,
  });

  factory PrivateAlphaOperatorPackEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final value = json['operator_pack'];
    if (value is! Map<String, dynamic>) {
      throw const FormatException('operator_pack must be a JSON object.');
    }
    final rawRoles = value['role_codes'];
    if (rawRoles is! List || rawRoles.any((role) => role is! String)) {
      throw const FormatException(
        'operator_pack.role_codes must be an array of strings.',
      );
    }
    return PrivateAlphaOperatorPackEvidence(
      roleCodes: Set.unmodifiable(rawRoles.cast<String>()),
      externalRecordLocator: _requiredString(
        value,
        'external_record_locator',
      ),
      accessRestricted: _requiredBool(value, 'access_restricted'),
      retentionPolicyDeclared: _requiredBool(
        value,
        'retention_policy_declared',
      ),
      deletionProcedureDeclared: _requiredBool(
        value,
        'deletion_procedure_declared',
      ),
      incidentResponseDeclared: _requiredBool(
        value,
        'incident_response_declared',
      ),
    );
  }
}

class PrivateAlphaOperatorPackVerification {
  final List<String> blockers;

  const PrivateAlphaOperatorPackVerification(this.blockers);
}

class PrivateAlphaOperatorPackVerifier {
  static const approvedTemplates = [
    PrivateAlphaOperatorTemplateSpec(
      id: 'recruitment_register',
      relativePath: 'docs/private-alpha-recruitment-register.md',
      approvedSha256:
          'a69c34c73622bc6aca3618f474340d48b2f61f5a4a8a793f0a5fe49b8b4c8eb9',
      requiredHeadings: [
        '# Duoduo Private Alpha Recruitment Register',
        '## Storage Rule',
        '## Enrollment Gate',
        '## Screener Register',
        '## Cohort Freeze',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'participant_guide',
      relativePath: 'docs/private-alpha-participant-guide.md',
      approvedSha256:
          '26f5b6275318a1269e44e4634271f99dd7a7bfddff10bc4336178bd8e0281966',
      requiredHeadings: [
        '# Duoduo Private Alpha Participant Guide',
        '## Before You Start',
        '## Sending Feedback',
        '## Your Data',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'session_worksheet',
      relativePath: 'docs/private-alpha-session-worksheet.md',
      approvedSha256:
          '66242c9c722472ef71350d68ff91fe912a5a702e2b98c6e9ad2601a95916aae5',
      requiredHeadings: [
        '# Duoduo Private Alpha Session Worksheet',
        '## Session Identity',
        '## Entry Checks',
        '## Closeout',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'issue_log',
      relativePath: 'docs/private-alpha-issue-log.md',
      approvedSha256:
          '37042b195d6cf042b0f381b990f6b3f07b7537d748f69cb7a553b2698bbbb3f7',
      requiredHeadings: [
        '# Duoduo Private Alpha Issue Log',
        '## Issue Record',
        '## Severity And Required Action',
        '## Stop Decision',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'decision_log',
      relativePath: 'docs/private-alpha-decision-log.md',
      approvedSha256:
          'b79aaa35df5d3cd7501cf756274f8553cca3904da525f4f31c5d5505a5984f2a',
      requiredHeadings: [
        '# Duoduo Private Alpha Decision Log',
        '## Decision Record',
        '## Go / No-Go Record',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'report_template',
      relativePath: 'docs/private-alpha-report-template.md',
      approvedSha256:
          'e856d77c873356a9c7e18b51be5f5be37265f3d09ff192741ec7bab0502a7a1e',
      requiredHeadings: [
        '# Duoduo Private Alpha Report',
        '## Release And Model Evidence',
        '## Reliability And Privacy Incidents',
        '## Evidence Index',
      ],
    ),
  ];

  final List<PrivateAlphaOperatorTemplateSpec> templates;

  const PrivateAlphaOperatorPackVerifier({
    this.templates = approvedTemplates,
  });

  Future<PrivateAlphaOperatorPackVerification> verify({
    required PrivateAlphaOperatorPackEvidence evidence,
    required String repositoryRoot,
  }) async {
    final blockers = <String>[];
    if (!evidence.roleCodes.containsAll(
      PrivateAlphaOperatorPackEvidence.requiredRoleCodes,
    )) {
      blockers.add('operator_pack_required_roles_missing');
    }
    if (!RegExp(r'^OPS-[A-Z0-9-]{3,64}$')
        .hasMatch(evidence.externalRecordLocator)) {
      blockers.add('operator_pack_external_locator_invalid');
    }
    if (!evidence.accessRestricted) {
      blockers.add('operator_pack_access_not_restricted');
    }
    if (!evidence.retentionPolicyDeclared) {
      blockers.add('operator_pack_retention_policy_missing');
    }
    if (!evidence.deletionProcedureDeclared) {
      blockers.add('operator_pack_deletion_procedure_missing');
    }
    if (!evidence.incidentResponseDeclared) {
      blockers.add('operator_pack_incident_response_missing');
    }

    final root = p.normalize(p.absolute(repositoryRoot));
    for (final template in templates) {
      final absolutePath = p.normalize(
        p.absolute(root, template.relativePath),
      );
      if (!p.isWithin(root, absolutePath)) {
        blockers.add('operator_pack_path_invalid:${template.id}');
        continue;
      }
      final file = File(absolutePath);
      if (!await file.exists()) {
        blockers.add('operator_pack_missing:${template.id}');
        continue;
      }
      try {
        final content = await file.readAsString();
        for (final heading in template.requiredHeadings) {
          if (!content.split('\n').contains(heading)) {
            blockers.add('operator_pack_section_missing:${template.id}');
            break;
          }
        }
        final actualHash = await sha256.bind(file.openRead()).first;
        if (actualHash.toString() != template.approvedSha256) {
          blockers.add('operator_pack_template_drift:${template.id}');
        }
      } on FileSystemException {
        blockers.add('operator_pack_unreadable:${template.id}');
      }
    }
    return PrivateAlphaOperatorPackVerification(
      List.unmodifiable(blockers.toSet()),
    );
  }
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
