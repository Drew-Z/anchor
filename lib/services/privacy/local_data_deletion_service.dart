import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/product_event.dart';
import '../onboarding/first_run_progress.dart';
import '../openai_service.dart';
import 'privacy_preferences.dart';
import 'product_event_recorder.dart';

enum LocalDataScope {
  learningHistory('learning_history', '学习历史'),
  learningContent('learning_content', '来源与学习内容（含关联历史）'),
  productEvents('product_events', '本地产品事件'),
  modelConfiguration('model_configuration', '模型配置与凭据'),
  onboardingState('onboarding_state', '首次运行状态');

  final String value;
  final String label;

  const LocalDataScope(this.value, this.label);
}

class LocalDataDeletionResult {
  final Set<LocalDataScope> scopes;
  final Map<String, int> deletedRows;

  const LocalDataDeletionResult({
    required this.scopes,
    required this.deletedRows,
  });
}

class LocalDataDeletionService {
  static const Set<String> _modelPreferenceKeys = {
    'ai_model',
    'ai_base_url',
    'ai_provider_id',
    'ai_api_protocol',
    'ai_model_acceptance_reports_v1',
    'ai_api_key',
    'openai_api_key',
    'openai_model',
  };

  final DatabaseHelper _databaseHelper;
  final OpenAIService _openAIService;
  final FirstRunProgressStore _firstRunProgressStore;
  final PrivacyPreferencesStore _privacyPreferencesStore;
  final ProductEventRecorder _eventRecorder;
  final Future<SharedPreferences> Function() _preferencesLoader;

  LocalDataDeletionService({
    required DatabaseHelper databaseHelper,
    required OpenAIService openAIService,
    required FirstRunProgressStore firstRunProgressStore,
    required PrivacyPreferencesStore privacyPreferencesStore,
    required ProductEventRecorder eventRecorder,
    Future<SharedPreferences> Function()? preferencesLoader,
  })  : _databaseHelper = databaseHelper,
        _openAIService = openAIService,
        _firstRunProgressStore = firstRunProgressStore,
        _privacyPreferencesStore = privacyPreferencesStore,
        _eventRecorder = eventRecorder,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  Future<LocalDataDeletionResult> delete(Set<LocalDataScope> scopes) async {
    if (scopes.isEmpty) {
      throw ArgumentError('At least one local data scope must be selected.');
    }
    final deletedRows = <String, int>{};
    final database = await _databaseHelper.database;
    await database.transaction((transaction) async {
      if (scopes.contains(LocalDataScope.learningContent)) {
        await _deleteLearningHistory(transaction, deletedRows);
        await _deleteLearningContent(transaction, deletedRows);
      } else if (scopes.contains(LocalDataScope.learningHistory)) {
        await _deleteLearningHistory(transaction, deletedRows);
      }
      if (scopes.contains(LocalDataScope.productEvents)) {
        deletedRows['product_events'] = await transaction.delete(
          'product_events',
        );
      }
    });

    if (scopes.contains(LocalDataScope.modelConfiguration)) {
      await _deleteModelConfiguration();
    }
    if (scopes.contains(LocalDataScope.onboardingState)) {
      await _firstRunProgressStore.clear();
      final preferences = await _preferencesLoader();
      await preferences.remove('learning_agent_goal');
    }
    if (scopes.contains(LocalDataScope.productEvents)) {
      await _privacyPreferencesStore.resetAnonymousInstallId();
    }

    await _eventRecorder.recordBestEffort(
      ProductEventName.dataDeleted,
      flowId: 'privacy_settings',
      properties: {
        'data_scopes': scopes.map((scope) => scope.value).toList()..sort(),
        'result': 'completed',
      },
    );
    return LocalDataDeletionResult(scopes: scopes, deletedRows: deletedRows);
  }

  Future<void> _deleteLearningHistory(
    Transaction transaction,
    Map<String, int> deletedRows,
  ) async {
    for (final table in [
      'learning_agent_trace_events',
      'learning_agent_states',
      'programming_review_actions',
      'programming_exercise_attempts',
      'interview_turns',
      'tutor_turns',
      'learning_sessions',
      'study_records',
    ]) {
      deletedRows[table] = await transaction.delete(table);
    }
    await transaction.update('questions', {
      'last_reviewed_at': null,
      'next_review_at': null,
      'ease': 1.0,
      'lapse_count': 0,
    });
    await transaction.update('knowledge_points', {'mastery_level': 0});
    await transaction.update('decks', {'mastery_level': 0});
    await transaction.update(
      'user_stats',
      {
        'xp': 0,
        'streak': 0,
        'hearts': 5,
        'today_xp': 0,
        'last_study_date': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> _deleteLearningContent(
    Transaction transaction,
    Map<String, int> deletedRows,
  ) async {
    for (final table in [
      'programming_exercises',
      'knowledge_point_prerequisites',
      'knowledge_point_sources',
      'questions',
      'decks',
      'knowledge_points',
      'source_chunks',
      'sources',
    ]) {
      deletedRows[table] = await transaction.delete(table);
    }
  }

  Future<void> _deleteModelConfiguration() async {
    final providerIds = <String>{
      ...AIProviders.builtin.map((provider) => provider.id),
      await _openAIService.getProviderId(),
    };
    for (final providerId in providerIds) {
      await _openAIService.clearApiKey(providerId: providerId);
    }
    final preferences = await _preferencesLoader();
    for (final key in _modelPreferenceKeys) {
      await preferences.remove(key);
    }
    final profileKeys = preferences
        .getKeys()
        .where(
          (key) => key.startsWith(OpenAIService.profilePreferencePrefix),
        )
        .toList(growable: false);
    for (final key in profileKeys) {
      await preferences.remove(key);
    }
  }
}
