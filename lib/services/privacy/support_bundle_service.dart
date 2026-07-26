import 'dart:convert';

import '../../data/database/database_helper.dart';
import '../../data/models/product_event.dart';
import '../../data/repositories/product_event_repository.dart';
import '../ai/ai_model_acceptance.dart';
import '../onboarding/first_run_progress.dart';
import '../openai_service.dart';
import 'privacy_preferences.dart';
import 'privacy_redactor.dart';
import 'product_event_recorder.dart';

class LocalTextExport {
  final String fileName;
  final String content;
  final List<String> includedSections;

  const LocalTextExport({
    required this.fileName,
    required this.content,
    this.includedSections = const [],
  });
}

class SupportBundleService {
  final DatabaseHelper _databaseHelper;
  final ProductEventRepository _productEventRepository;
  final PrivacyPreferencesStore _privacyPreferencesStore;
  final AiModelAcceptanceStore _acceptanceStore;
  final FirstRunProgressStore _firstRunProgressStore;
  final OpenAIService _openAIService;
  final PrivacyRedactor _redactor;
  final DateTime Function() _clock;

  SupportBundleService({
    required DatabaseHelper databaseHelper,
    required ProductEventRepository productEventRepository,
    required PrivacyPreferencesStore privacyPreferencesStore,
    required AiModelAcceptanceStore acceptanceStore,
    required FirstRunProgressStore firstRunProgressStore,
    required OpenAIService openAIService,
    PrivacyRedactor redactor = const PrivacyRedactor(),
    DateTime Function()? clock,
  })  : _databaseHelper = databaseHelper,
        _productEventRepository = productEventRepository,
        _privacyPreferencesStore = privacyPreferencesStore,
        _acceptanceStore = acceptanceStore,
        _firstRunProgressStore = firstRunProgressStore,
        _openAIService = openAIService,
        _redactor = redactor,
        _clock = clock ?? DateTime.now;

  Future<LocalTextExport> buildProductEventExport() async {
    final generatedAt = _clock().toUtc();
    final events = await _productEventRepository.getEvents();
    final payload = {
      'schema_version': 1,
      'generated_at': generatedAt.toIso8601String(),
      'event_count': events.length,
      'events': events.reversed
          .map((event) => event.toExportJson())
          .toList(growable: false),
    };
    return LocalTextExport(
      fileName: 'duoduo-events-${_fileTimestamp(generatedAt)}.json',
      content: const JsonEncoder.withIndent('  ').convert(payload),
      includedSections: const ['product_events'],
    );
  }

  Future<LocalTextExport> buildSupportBundle({
    bool? includeAgentRuntimeSummary,
    List<String> diagnosticLines = const [],
  }) async {
    final generatedAt = _clock().toUtc();
    final preferences = await _privacyPreferencesStore.read();
    final includeRuntime =
        includeAgentRuntimeSummary ?? preferences.includeAgentRuntimeSummary;
    final firstRun = await _firstRunProgressStore.read();
    final reports = await _acceptanceStore.readAll();
    final events = await _productEventRepository.getEvents(limit: 50);
    final providerId = await _openAIService.getProviderId();
    final baseUrl = await _openAIService.getBaseUrl();
    final model = await _openAIService.getModel();
    final protocol = await _openAIService.getApiProtocol();
    final includedSections = <String>[
      'app',
      'database_counts',
      'privacy',
      'first_run',
      'model_configuration',
      'model_acceptance',
      'product_event_summary',
      if (diagnosticLines.isNotEmpty) 'diagnostic_lines',
      if (includeRuntime) 'agent_runtime_summary',
    ];
    final payload = <String, Object?>{
      'bundle_schema_version': 1,
      'redaction_version': PrivacyRedactor.currentVersion,
      'generated_at': generatedAt.toIso8601String(),
      'included_sections': includedSections,
      'app': {
        'version': ProductEventRecorder.appVersion,
        'database_schema_version': await _databaseSchemaVersion(),
      },
      'database_counts': await _databaseCounts(),
      'privacy': preferences.toJson(),
      'first_run': firstRun == null
          ? {'present': false}
          : {
              'present': true,
              'step': firstRun.step.value,
              'goal': firstRun.selectedGoal.value,
              'legacy_user': firstRun.legacyUser,
              'has_source': firstRun.sourceId != null,
              'has_session': firstRun.sessionId != null,
              'started_at': firstRun.startedAt.toUtc().toIso8601String(),
              'updated_at': firstRun.updatedAt.toUtc().toIso8601String(),
            },
      'model_configuration': {
        'provider_id': providerId,
        'endpoint': _sanitizeEndpoint(baseUrl),
        'model': model,
        'protocol': protocol.value,
        'has_api_key': await _openAIService.hasApiKey(providerId: providerId),
      },
      'model_acceptance': reports.take(5).map((report) {
        return {
          'run_at': report.runAt.toUtc().toIso8601String(),
          'provider_id': report.configuration.providerId,
          'endpoint': report.configuration.endpoint,
          'model': report.configuration.model,
          'protocol': report.configuration.protocol.value,
          'passed': report.passed,
          'passed_count': report.passedCount,
          'attempted_count': report.attemptedCount,
          'latency_bucket': ProductEventRecorder.durationBucket(
            Duration(milliseconds: report.totalLatencyMs),
          ),
          'failure_category': report.blockingFailure?.name ?? 'none',
        };
      }).toList(growable: false),
      'product_event_summary': {
        'total_count': await _productEventRepository.count(),
        'counts_by_name': _eventCounts(events),
        'latest_events': events
            .map((event) => {
                  'event_name': event.name.value,
                  'occurred_at': event.occurredAt.toUtc().toIso8601String(),
                  'schema_version': event.schemaVersion,
                })
            .toList(growable: false),
      },
      if (diagnosticLines.isNotEmpty)
        'diagnostic_lines': diagnosticLines
            .map(_redactor.redactDiagnostic)
            .toList(growable: false),
      if (includeRuntime) 'agent_runtime_summary': await _agentRuntimeSummary(),
    };
    final encoded = const JsonEncoder.withIndent('  ').convert(payload);
    return LocalTextExport(
      fileName: 'duoduo-support-${_fileTimestamp(generatedAt)}.json',
      content: _redactor.redact(encoded),
      includedSections: includedSections,
    );
  }

  Future<Map<String, int>> _databaseCounts() async {
    const tables = [
      'sources',
      'source_chunks',
      'knowledge_points',
      'decks',
      'questions',
      'study_records',
      'learning_sessions',
      'interview_turns',
      'tutor_turns',
      'programming_exercises',
      'programming_exercise_attempts',
      'programming_review_actions',
      'learning_agent_states',
      'learning_agent_trace_events',
      'product_events',
    ];
    final database = await _databaseHelper.database;
    final counts = <String, int>{};
    for (final table in tables) {
      final result = await database.rawQuery('SELECT COUNT(*) FROM $table');
      counts[table] = _firstInt(result);
    }
    return counts;
  }

  Future<int> _databaseSchemaVersion() async {
    final database = await _databaseHelper.database;
    final rows = await database.rawQuery('PRAGMA user_version');
    return _firstInt(rows);
  }

  Future<Map<String, Object?>> _agentRuntimeSummary() async {
    final database = await _databaseHelper.database;
    final states = await database.rawQuery('''
      SELECT goal, phase, COUNT(*) AS item_count
      FROM learning_agent_states
      GROUP BY goal, phase
      ORDER BY goal, phase
    ''');
    final traces = await database.rawQuery('''
      SELECT type, level, COUNT(*) AS item_count
      FROM learning_agent_trace_events
      GROUP BY type, level
      ORDER BY type, level
    ''');
    return {
      'state_counts': states,
      'trace_counts': traces,
    };
  }

  Map<String, int> _eventCounts(Iterable<ProductEvent> events) {
    final counts = <String, int>{};
    for (final event in events) {
      counts.update(event.name.value, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  int _firstInt(List<Map<String, Object?>> rows) {
    if (rows.isEmpty || rows.first.values.isEmpty) return 0;
    return int.tryParse(rows.first.values.first.toString()) ?? 0;
  }

  String _sanitizeEndpoint(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.isEmpty) return 'invalid_endpoint';
    return Uri(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      port: uri.hasPort ? uri.port : null,
      path: uri.path.replaceFirst(RegExp(r'/+$'), ''),
    ).toString();
  }

  String _fileTimestamp(DateTime value) {
    return value
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .replaceAll('Z', '');
  }
}
