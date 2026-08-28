import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:anchor_learning/services/release/private_alpha_operator_pack_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('approved repository operator pack is complete and unchanged', () async {
    final verification = await const PrivateAlphaOperatorPackVerifier().verify(
      evidence: _validEvidence(),
      repositoryRoot: Directory.current.path,
    );

    expect(verification.blockers, isEmpty);
  });

  test('custom pack verifies headings and exact blank-template hashes',
      () async {
    final root =
        await Directory.systemTemp.createTemp('anchor-learning-operator-');
    addTearDown(() => root.delete(recursive: true));
    const content = '# Template\n## Required\n';
    final file = File(p.join(root.path, 'template.md'));
    await file.writeAsString(content);
    final spec = PrivateAlphaOperatorTemplateSpec(
      id: 'template',
      relativePath: 'template.md',
      approvedSha256: sha256.convert(utf8.encode(content)).toString(),
      requiredHeadings: const ['# Template', '## Required'],
    );

    final verification = await PrivateAlphaOperatorPackVerifier(
      templates: [spec],
    ).verify(
      evidence: _validEvidence(),
      repositoryRoot: root.path,
    );

    expect(verification.blockers, isEmpty);
  });

  test('blocks missing roles, policies, sections and template drift', () async {
    final root =
        await Directory.systemTemp.createTemp('anchor-learning-operator-');
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'template.md')).writeAsString('# Template\n');
    const verifier = PrivateAlphaOperatorPackVerifier(
      templates: [
        PrivateAlphaOperatorTemplateSpec(
          id: 'template',
          relativePath: 'template.md',
          approvedSha256:
              '0000000000000000000000000000000000000000000000000000000000000000',
          requiredHeadings: ['# Template', '## Required'],
        ),
        PrivateAlphaOperatorTemplateSpec(
          id: 'missing',
          relativePath: 'missing.md',
          approvedSha256:
              '0000000000000000000000000000000000000000000000000000000000000000',
          requiredHeadings: ['# Missing'],
        ),
      ],
    );
    const invalidEvidence = PrivateAlphaOperatorPackEvidence(
      roleCodes: {'alphaOwner'},
      externalRecordLocator: 'person@example.com',
      accessRestricted: false,
      retentionPolicyDeclared: false,
      deletionProcedureDeclared: false,
      incidentResponseDeclared: false,
    );

    final verification = await verifier.verify(
      evidence: invalidEvidence,
      repositoryRoot: root.path,
    );

    expect(verification.blockers, [
      'operator_pack_required_roles_missing',
      'operator_pack_external_locator_invalid',
      'operator_pack_access_not_restricted',
      'operator_pack_retention_policy_missing',
      'operator_pack_deletion_procedure_missing',
      'operator_pack_incident_response_missing',
      'operator_pack_section_missing:template',
      'operator_pack_template_drift:template',
      'operator_pack_missing:missing',
    ]);
    expect(verification.blockers.join(' '), isNot(contains('person@')));
    expect(verification.blockers.join(' '), isNot(contains(root.path)));
  });

  test('parser requires anonymous role and policy evidence', () {
    expect(
      () => PrivateAlphaOperatorPackEvidence.fromJson(const {}),
      throwsA(isA<FormatException>()),
    );
    final evidence = PrivateAlphaOperatorPackEvidence.fromJson(const {
      'operator_pack': {
        'role_codes': [
          'alphaOwner',
          'privacyReviewer',
          'reliabilityOwner',
        ],
        'external_record_locator': 'OPS-ALPHA-01',
        'access_restricted': true,
        'retention_policy_declared': true,
        'deletion_procedure_declared': true,
        'incident_response_declared': true,
      },
    });
    expect(evidence.externalRecordLocator, 'OPS-ALPHA-01');
  });
}

PrivateAlphaOperatorPackEvidence _validEvidence() {
  return const PrivateAlphaOperatorPackEvidence(
    roleCodes: {
      'alphaOwner',
      'privacyReviewer',
      'reliabilityOwner',
    },
    externalRecordLocator: 'OPS-ALPHA-01',
    accessRestricted: true,
    retentionPolicyDeclared: true,
    deletionProcedureDeclared: true,
    incidentResponseDeclared: true,
  );
}
