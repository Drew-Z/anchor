import 'dart:convert';

import 'package:anchor_learning/services/privacy/alpha_feedback_service.dart';
import 'package:anchor_learning/services/privacy/support_bundle_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports redacted feedback without diagnostics by default', () async {
    LocalTextExport? savedArtifact;
    AlphaFeedbackDraft? recordedDraft;
    var supportBundleCalls = 0;
    final service = AlphaFeedbackService(
      databaseSchemaVersion: 23,
      supportBundleBuilder: (_) async {
        supportBundleCalls++;
        return _supportBundle();
      },
      artifactSaver: (artifact) async {
        savedArtifact = artifact;
        return true;
      },
      eventRecorder: (draft) async => recordedDraft = draft,
      clock: () => DateTime.utc(2026, 7, 16, 8, 30),
    );
    const draft = AlphaFeedbackDraft(
      category: AlphaFeedbackCategory.featureRequest,
      severity: AlphaFeedbackSeverity.medium,
      screenId: 'agent_workspace',
      details:
          'API key sk-secret123456 at C:\\Users\\tester\\project and https://example.com/path?token=secret',
      diagnosticConsent: false,
    );

    expect(await service.submit(draft), isTrue);
    expect(supportBundleCalls, 0);
    expect(recordedDraft, same(draft));
    expect(savedArtifact, isNotNull);
    final payload = jsonDecode(savedArtifact!.content) as Map<String, dynamic>;
    expect(payload['included_sections'], ['feedback', 'app']);
    expect(payload.containsKey('redacted_diagnostics'), isFalse);
    expect(payload['app']['database_schema_version'], 23);
    final details = payload['feedback']['details'].toString();
    expect(details, contains('[redacted_secret]'));
    expect(details, contains('[private_path]'));
    expect(details, isNot(contains('token=secret')));
  });

  test('explicit consent attaches only the redacted support bundle', () async {
    List<String>? receivedDiagnosticLines;
    final service = AlphaFeedbackService(
      databaseSchemaVersion: 23,
      supportBundleBuilder: (lines) async {
        receivedDiagnosticLines = lines;
        return _supportBundle();
      },
      artifactSaver: (_) async => true,
      eventRecorder: (_) async {},
      clock: () => DateTime.utc(2026, 7, 16, 9),
    );
    const draft = AlphaFeedbackDraft(
      category: AlphaFeedbackCategory.setupOrImport,
      severity: AlphaFeedbackSeverity.blocking,
      screenId: 'first_run_project_import',
      details: '目录扫描没有继续。',
      diagnosticConsent: true,
      stableErrorCode: 'project_scan_failed',
      diagnosticLines: ['phase=scan'],
    );

    final artifact = await service.buildExport(draft);
    final payload = jsonDecode(artifact.content) as Map<String, dynamic>;
    expect(receivedDiagnosticLines, ['phase=scan']);
    expect(
      payload['included_sections'],
      ['feedback', 'app', 'redacted_diagnostics'],
    );
    expect(payload['feedback']['stable_error_code'], 'project_scan_failed');
    expect(payload['redacted_diagnostics']['bundle_schema_version'], 1);
    expect(payload.toString(), isNot(contains('sk-secret')));
  });

  test('cancelled save does not record feedback submission', () async {
    var recorded = false;
    final service = AlphaFeedbackService(
      databaseSchemaVersion: 23,
      supportBundleBuilder: (_) async => _supportBundle(),
      artifactSaver: (_) async => false,
      eventRecorder: (_) async => recorded = true,
    );

    final saved = await service.submit(
      const AlphaFeedbackDraft(
        category: AlphaFeedbackCategory.interfaceOrAccessibility,
        severity: AlphaFeedbackSeverity.low,
        screenId: 'project_interview_outcome',
        details: '按钮在大字体下不易找到。',
        diagnosticConsent: false,
      ),
    );

    expect(saved, isFalse);
    expect(recorded, isFalse);
  });

  test('rejects empty details and unstable identifiers', () async {
    final service = AlphaFeedbackService(
      databaseSchemaVersion: 23,
      supportBundleBuilder: (_) async => _supportBundle(),
      artifactSaver: (_) async => true,
      eventRecorder: (_) async {},
    );

    expect(
      () => service.buildExport(
        const AlphaFeedbackDraft(
          category: AlphaFeedbackCategory.evidence,
          severity: AlphaFeedbackSeverity.high,
          screenId: 'Agent Workspace',
          details: ' ',
          diagnosticConsent: false,
        ),
      ),
      throwsArgumentError,
    );
  });
}

LocalTextExport _supportBundle() {
  return const LocalTextExport(
    fileName: 'support.json',
    content: '{"bundle_schema_version":1,"has_api_key":true}',
    includedSections: ['app'],
  );
}
