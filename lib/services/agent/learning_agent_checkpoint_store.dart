import '../../data/database/database_helper.dart';
import 'learning_agent_checkpoint.dart';
import 'learning_agent_plan_codec.dart';
import 'learning_agent_state.dart';
import 'learning_agent_trace.dart';

abstract interface class LearningAgentCheckpointStore {
  Future<LearningAgentCheckpoint> save(LearningAgentCheckpoint checkpoint);

  Future<LearningAgentCheckpoint?> load(String sessionId);

  Future<List<LearningAgentCheckpoint>> loadActive({int limit = 20});

  Future<void> delete(String sessionId);
}

class LearningAgentCheckpointConflictException implements Exception {
  final String sessionId;
  final int expectedRevision;
  final int actualRevision;

  const LearningAgentCheckpointConflictException({
    required this.sessionId,
    required this.expectedRevision,
    required this.actualRevision,
  });

  @override
  String toString() {
    return 'Agent checkpoint 已被其他流程更新：session=$sessionId，'
        '当前基于 revision $expectedRevision，最新 revision 为 $actualRevision。';
  }
}

class SqliteLearningAgentCheckpointStore
    implements LearningAgentCheckpointStore {
  final DatabaseHelper _databaseHelper;
  final LearningAgentPlanCodec _planCodec;

  const SqliteLearningAgentCheckpointStore(
    this._databaseHelper, {
    LearningAgentPlanCodec planCodec = const LearningAgentPlanCodec(),
  }) : _planCodec = planCodec;

  @override
  Future<LearningAgentCheckpoint> save(
    LearningAgentCheckpoint checkpoint,
  ) async {
    final stateMap = Map<String, Object?>.from(checkpoint.state.toMap());
    stateMap['plan_snapshot'] =
        checkpoint.plan == null ? null : _planCodec.encode(checkpoint.plan!);
    try {
      final revision = await _databaseHelper.saveLearningAgentCheckpoint(
        state: stateMap,
        traceEvents: checkpoint.traceEvents
            .map((event) => event.toMap())
            .toList(growable: false),
        expectedRevision: checkpoint.revision,
      );
      return checkpoint.withRevision(revision);
    } on LearningAgentCheckpointRevisionConflict catch (conflict) {
      throw LearningAgentCheckpointConflictException(
        sessionId: conflict.sessionId,
        expectedRevision: conflict.expectedRevision,
        actualRevision: conflict.actualRevision,
      );
    }
  }

  @override
  Future<LearningAgentCheckpoint?> load(String sessionId) async {
    final stateMap = await _databaseHelper.getLearningAgentStateMap(sessionId);
    if (stateMap == null) return null;

    final traceMaps =
        await _databaseHelper.getLearningAgentTraceEventMaps(sessionId);
    final planSnapshot = stateMap['plan_snapshot'] as String?;
    return LearningAgentCheckpoint(
      state: LearningAgentState.fromMap(stateMap),
      traceEvents: traceMaps
          .map(LearningAgentTraceEvent.fromMap)
          .toList(growable: false),
      plan: planSnapshot == null ? null : _planCodec.decode(planSnapshot),
      revision: stateMap['checkpoint_revision'] as int? ?? 1,
    );
  }

  @override
  Future<List<LearningAgentCheckpoint>> loadActive({int limit = 20}) async {
    final stateMaps =
        await _databaseHelper.getActiveLearningAgentStateMaps(limit: limit);
    final checkpoints = <LearningAgentCheckpoint>[];
    for (final stateMap in stateMaps) {
      final sessionId = stateMap['session_id'] as String;
      final traceMaps =
          await _databaseHelper.getLearningAgentTraceEventMaps(sessionId);
      final planSnapshot = stateMap['plan_snapshot'] as String?;
      checkpoints.add(
        LearningAgentCheckpoint(
          state: LearningAgentState.fromMap(stateMap),
          traceEvents: traceMaps
              .map(LearningAgentTraceEvent.fromMap)
              .toList(growable: false),
          plan: planSnapshot == null ? null : _planCodec.decode(planSnapshot),
          revision: stateMap['checkpoint_revision'] as int? ?? 1,
        ),
      );
    }
    return checkpoints;
  }

  @override
  Future<void> delete(String sessionId) {
    return _databaseHelper.deleteLearningAgentCheckpoint(sessionId);
  }
}
