import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_metadata.dart';
import 'privacy_redactor.dart';
import 'support_bundle_service.dart';

enum AlphaFeedbackCategory {
  setupOrImport('setup_or_import', '无法导入或配置'),
  evidence('evidence', '来源或证据错误/缺失'),
  explanation('explanation', '讲解或评价帮助不大'),
  nextAction('next_action', '下一动作错误或困惑'),
  interfaceOrAccessibility(
    'interface_or_accessibility',
    '界面或无障碍问题',
  ),
  featureRequest('feature_request', '功能建议');

  final String value;
  final String label;

  const AlphaFeedbackCategory(this.value, this.label);
}

enum AlphaFeedbackSeverity {
  low('low', '建议'),
  medium('medium', '一般'),
  high('high', '严重'),
  blocking('blocking', '阻断使用');

  final String value;
  final String label;

  const AlphaFeedbackSeverity(this.value, this.label);
}

class AlphaFeedbackDraft {
  final AlphaFeedbackCategory category;
  final AlphaFeedbackSeverity severity;
  final String screenId;
  final String details;
  final bool diagnosticConsent;
  final String? stableErrorCode;
  final List<String> diagnosticLines;

  const AlphaFeedbackDraft({
    required this.category,
    required this.severity,
    required this.screenId,
    required this.details,
    required this.diagnosticConsent,
    this.stableErrorCode,
    this.diagnosticLines = const [],
  });
}

typedef AlphaFeedbackSupportBundleBuilder = Future<LocalTextExport> Function(
  List<String> diagnosticLines,
);
typedef AlphaFeedbackArtifactSaver = Future<bool> Function(
  LocalTextExport artifact,
);
typedef AlphaFeedbackEventRecorder = Future<void> Function(
  AlphaFeedbackDraft draft,
);

class AlphaFeedbackService {
  static const int feedbackSchemaVersion = 1;
  static const int maxDetailsLength = 1200;

  final int _databaseSchemaVersion;
  final AlphaFeedbackSupportBundleBuilder _supportBundleBuilder;
  final AlphaFeedbackArtifactSaver _artifactSaver;
  final AlphaFeedbackEventRecorder _eventRecorder;
  final PrivacyRedactor _redactor;
  final DateTime Function() _clock;

  AlphaFeedbackService({
    required int databaseSchemaVersion,
    required AlphaFeedbackSupportBundleBuilder supportBundleBuilder,
    required AlphaFeedbackEventRecorder eventRecorder,
    AlphaFeedbackArtifactSaver? artifactSaver,
    PrivacyRedactor redactor = const PrivacyRedactor(),
    DateTime Function()? clock,
  })  : _databaseSchemaVersion = databaseSchemaVersion,
        _supportBundleBuilder = supportBundleBuilder,
        _eventRecorder = eventRecorder,
        _artifactSaver = artifactSaver ?? _saveWithFilePicker,
        _redactor = redactor,
        _clock = clock ?? DateTime.now;

  Future<bool> submit(AlphaFeedbackDraft draft) async {
    final artifact = await buildExport(draft);
    final saved = await _artifactSaver(artifact);
    if (!saved) return false;
    await _eventRecorder(draft);
    return true;
  }

  Future<LocalTextExport> buildExport(AlphaFeedbackDraft draft) async {
    final screenId = _stableIdentifier(draft.screenId, field: 'screen_id');
    final stableErrorCode = draft.stableErrorCode == null
        ? null
        : _stableIdentifier(
            draft.stableErrorCode!,
            field: 'stable_error_code',
          );
    final details = draft.details.trim();
    if (details.isEmpty || details.length > maxDetailsLength) {
      throw ArgumentError(
        'Feedback details must be between 1 and $maxDetailsLength characters.',
      );
    }

    final generatedAt = _clock().toUtc();
    final includedSections = <String>[
      'feedback',
      'app',
      if (draft.diagnosticConsent) 'redacted_diagnostics',
    ];
    final payload = <String, Object?>{
      'feedback_schema_version': feedbackSchemaVersion,
      'generated_at': generatedAt.toIso8601String(),
      'included_sections': includedSections,
      'feedback': {
        'category': draft.category.value,
        'severity': draft.severity.value,
        'screen_id': screenId,
        if (stableErrorCode != null) 'stable_error_code': stableErrorCode,
        'details': _redactor.redact(details),
        'diagnostic_consent': draft.diagnosticConsent,
      },
      'app': {
        'version': AppMetadata.version,
        'database_schema_version': _databaseSchemaVersion,
      },
    };

    if (draft.diagnosticConsent) {
      final supportBundle = await _supportBundleBuilder(
        draft.diagnosticLines,
      );
      payload['redacted_diagnostics'] = jsonDecode(supportBundle.content);
    }

    return LocalTextExport(
      fileName: 'anchor-learning-feedback-${_fileTimestamp(generatedAt)}.json',
      content: _redactor.redact(
        const JsonEncoder.withIndent('  ').convert(payload),
      ),
      includedSections: includedSections,
    );
  }

  static Future<bool> _saveWithFilePicker(LocalTextExport artifact) async {
    final path = await FilePicker.saveFile(
      dialogTitle: '导出 Private Alpha 反馈',
      fileName: artifact.fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: Uint8List.fromList(utf8.encode(artifact.content)),
    );
    return path != null;
  }

  static String _stableIdentifier(String value, {required String field}) {
    final normalized = value.trim();
    if (!_stableIdentifierPattern.hasMatch(normalized)) {
      throw ArgumentError('$field must be a stable snake-case identifier.');
    }
    return normalized;
  }

  static String _fileTimestamp(DateTime value) {
    return value.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
  }
}

final RegExp _stableIdentifierPattern = RegExp(r'^[a-z0-9_]{1,80}$');
