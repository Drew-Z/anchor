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
          '009e7e3c5b3c71482bb2e3692984096093f9946276bd62622c714821dfd5ba8a',
      requiredHeadings: [
        '# Anchor Learning Private Alpha Recruitment Register',
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
          '497c1cfe7a6a62acf0215191a99bb8c0659e901007fda0c32b11be9f0dd039ec',
      requiredHeadings: [
        '# Anchor Learning Private Alpha Participant Guide',
        '## Before You Start',
        '## Sending Feedback',
        '## Your Data',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'session_worksheet',
      relativePath: 'docs/private-alpha-session-worksheet.md',
      approvedSha256:
          '7e5d5d9489541236c218b43c447cfe7815ea08c9033f094b35106686ee8fbcbb',
      requiredHeadings: [
        '# Anchor Learning Private Alpha Session Worksheet',
        '## Session Identity',
        '## Entry Checks',
        '## Closeout',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'issue_log',
      relativePath: 'docs/private-alpha-issue-log.md',
      approvedSha256:
          'b3f2eb27e36409ea39a74d8f8a1934ea1f76f617e189c304575636fb50984d15',
      requiredHeadings: [
        '# Anchor Learning Private Alpha Issue Log',
        '## Issue Record',
        '## Severity And Required Action',
        '## Stop Decision',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'decision_log',
      relativePath: 'docs/private-alpha-decision-log.md',
      approvedSha256:
          '6de68985efefbc48933752f24ec0c8f349f9c2699c3d9baa83ce02da9d8403cf',
      requiredHeadings: [
        '# Anchor Learning Private Alpha Decision Log',
        '## Decision Record',
        '## Go / No-Go Record',
      ],
    ),
    PrivateAlphaOperatorTemplateSpec(
      id: 'report_template',
      relativePath: 'docs/private-alpha-report-template.md',
      approvedSha256:
          '8fe85b55e740a575b4709f8a922b5f48192aa3337426a7431e499b9f05f660fa',
      requiredHeadings: [
        '# Anchor Learning Private Alpha Report',
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
