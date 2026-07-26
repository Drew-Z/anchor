import 'package:dlg_q/services/agent/learning_agent_checkpoint.dart';
import 'package:dlg_q/services/agent/learning_agent_checkpoint_store.dart';
import 'package:dlg_q/services/agent/learning_agent_executor.dart';
import 'package:dlg_q/services/agent/learning_agent_plan_codec.dart';
import 'package:dlg_q/services/agent/learning_agent_planner_service.dart';
import 'package:dlg_q/services/agent/learning_agent_resume_policy.dart';
import 'package:dlg_q/services/agent/learning_agent_runtime.dart';
import 'package:dlg_q/services/agent/learning_agent_state.dart';
import 'package:dlg_q/services/agent/learning_agent_tool_input_snapshot.dart';
import 'package:dlg_q/services/agent/learning_agent_tool_registry.dart';
import 'package:dlg_q/services/agent/learning_agent_trace.dart';
import 'package:dlg_q/services/agent/learning_agent_user_decision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningAgentCheckpoint', () {
    test('normalizes state trace ids to the persisted event order', () {
      final state = _state(traceEventIds: const ['stale-event']);
      final events = [
        _event(id: 'event-1'),
        _event(id: 'event-2'),
      ];

      final checkpoint = LearningAgentCheckpoint(
        state: state,
        traceEvents: events,
      );

      expect(checkpoint.sessionId, 'session-1');
      expect(checkpoint.revision, 0);
      expect(checkpoint.state.traceEventIds, ['event-1', 'event-2']);
      expect(checkpoint.traceEvents, events);
    });

    test('rejects a trace event from another session', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _state(),
          traceEvents: [_event(id: 'event-1', sessionId: 'session-2')],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate trace event ids', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _state(),
          traceEvents: [
            _event(id: 'event-1'),
            _event(id: 'event-1'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a plan snapshot for another goal', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _state(),
          traceEvents: [_event(id: 'event-1')],
          plan: _plan(goal: LearningAgentGoal.aiInterviewPrep),
        ),
        throwsArgumentError,
      );
    });

    test('runtime persists a normalized checkpoint through the store port',
        () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);

      final checkpoint = await runtime.persistCheckpoint(
        state: _resumableState().copyWith(
          traceEventIds: const ['stale-event'],
        ),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );

      expect(store.savedCheckpoint, same(checkpoint));
      expect(checkpoint.state.traceEventIds, ['event-1']);
      expect(checkpoint.revision, 1);
    });

    test('runtime completes reflection with one reflection trace', () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final state = _resumableState()
          .copyWith(
            activeToolOperationId: 'operation-import-1',
            activeToolInputSnapshot: _toolInputSnapshot(),
          )
          .transitionTo(LearningAgentPhase.reflect);
      final completedAt = DateTime(2026, 7, 13, 10);

      final checkpoint = await runtime.persistReflectionCheckpoint(
        state: state,
        traceEvents: [
          _event(id: 'event-1'),
          _event(
            id: 'old-reflection',
            type: LearningAgentTraceEventType.reflectionSaved,
          ),
        ],
        plan: _plan(),
        targetLabel: 'Runtime checkpoint',
        detail: 'criteria 1/1',
        savedAt: completedAt,
      );

      final reflectionEvents = checkpoint.traceEvents
          .where(
            (event) =>
                event.type == LearningAgentTraceEventType.reflectionSaved,
          )
          .toList();
      expect(checkpoint.state.phase, LearningAgentPhase.complete);
      expect(checkpoint.state.activeToolOperationId, isNull);
      expect(reflectionEvents, hasLength(1));
      expect(reflectionEvents.single.phase, LearningAgentPhase.complete);
      expect(reflectionEvents.single.occurredAt, completedAt);
      expect(store.savedCheckpoint, same(checkpoint));
      expect(checkpoint.revision, 1);
    });

    testWidgets(
        'executor stops before tool call when tool-start checkpoint fails',
        (tester) async {
      late BuildContext buildContext;
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              buildContext = context;
              widgetRef = ref;
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      final checkpointFailure = StateError('disk unavailable');
      var checkpointWriteCount = 0;
      LearningAgentState? capturedState;
      List<LearningAgentTraceEvent>? capturedTraceEvents;

      final execution = const DefaultLearningAgentExecutor().execute(
        LearningAgentExecutionContext(
          buildContext: buildContext,
          ref: widgetRef,
          plan: _plan(),
          sessionId: 'session-1',
          initialState: _resumableState(),
          initialTraceEvents: [_event(id: 'event-1')],
          persistToolStartCheckpoint: (state, traceEvents) async {
            checkpointWriteCount += 1;
            capturedState = state;
            capturedTraceEvents = traceEvents;
            throw checkpointFailure;
          },
        ),
      );

      await expectLater(
        execution,
        throwsA(
          isA<LearningAgentToolStartCheckpointException>().having(
            (error) => error.cause,
            'cause',
            same(checkpointFailure),
          ),
        ),
      );
      expect(checkpointWriteCount, 1);
      expect(capturedState?.phase, LearningAgentPhase.act);
      expect(
        capturedState?.pendingUserDecision?.reason,
        LearningAgentUserDecisionReason.toolOutcomeUnknown,
      );
      expect(
        capturedTraceEvents?.map((event) => event.type).toList(),
        [
          LearningAgentTraceEventType.planCreated,
          LearningAgentTraceEventType.toolSelected,
          LearningAgentTraceEventType.policyChecked,
          LearningAgentTraceEventType.toolStarted,
        ],
      );
      expect(
        capturedState?.pendingUserDecision?.attemptId,
        capturedTraceEvents?.last.id,
      );
      expect(capturedState?.activeToolOperationId, isNotEmpty);
      expect(
        capturedState?.pendingUserDecision?.operationId,
        capturedState?.activeToolOperationId,
      );
      expect(
        capturedState?.activeToolInputSnapshot?.toolId,
        LearningAgentToolId.importSources.value,
      );
      expect(
        capturedState?.pendingUserDecision?.toolId,
        capturedTraceEvents?.last.toolId,
      );
    });

    testWidgets('tool retry keeps operation id and creates a new attempt id',
        (tester) async {
      late BuildContext buildContext;
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              buildContext = context;
              widgetRef = ref;
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      LearningAgentState? firstAttemptState;
      List<LearningAgentTraceEvent>? firstAttemptEvents;
      LearningAgentState? retryState;
      List<LearningAgentTraceEvent>? retryEvents;
      final executor = const DefaultLearningAgentExecutor();

      await expectLater(
        executor.execute(
          LearningAgentExecutionContext(
            buildContext: buildContext,
            ref: widgetRef,
            plan: _plan(),
            sessionId: 'session-1',
            initialState: _resumableState(),
            initialTraceEvents: [_event(id: 'event-1')],
            persistToolStartCheckpoint: (state, traceEvents) async {
              firstAttemptState = state;
              firstAttemptEvents = traceEvents;
              throw StateError('stop before first tool call');
            },
          ),
        ),
        throwsA(isA<LearningAgentToolStartCheckpointException>()),
      );

      await expectLater(
        executor.execute(
          LearningAgentExecutionContext(
            buildContext: buildContext,
            ref: widgetRef,
            plan: _plan(),
            sessionId: 'session-1',
            initialState: firstAttemptState!.copyWith(
              clearPendingUserDecision: true,
            ),
            initialTraceEvents: firstAttemptEvents!,
            persistToolStartCheckpoint: (state, traceEvents) async {
              retryState = state;
              retryEvents = traceEvents;
              throw StateError('stop before retry tool call');
            },
          ),
        ),
        throwsA(isA<LearningAgentToolStartCheckpointException>()),
      );

      expect(
        retryState?.activeToolOperationId,
        firstAttemptState?.activeToolOperationId,
      );
      expect(
        retryState?.pendingUserDecision?.operationId,
        firstAttemptState?.pendingUserDecision?.operationId,
      );
      expect(
        retryState?.pendingUserDecision?.attemptId,
        isNot(firstAttemptState?.pendingUserDecision?.attemptId),
      );
      expect(
        retryState?.pendingUserDecision?.attemptId,
        retryEvents?.last.id,
      );
      expect(
        retryState?.activeToolInputSnapshot?.toStorageValue(),
        firstAttemptState?.activeToolInputSnapshot?.toStorageValue(),
      );
    });

    testWidgets('tool retry rejects a changed routing input before tool start',
        (tester) async {
      late BuildContext buildContext;
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              buildContext = context;
              widgetRef = ref;
              return const MaterialApp(home: Scaffold());
            },
          ),
        ),
      );
      var checkpointWriteCount = 0;
      final initialState = _resumableState().copyWith(
        activeToolOperationId: 'operation-import-1',
        activeToolInputSnapshot: _toolInputSnapshot(
          evidenceChunkIds: const ['evidence-old'],
        ),
        evidenceChunkIds: const ['evidence-old'],
      );

      final result = await const DefaultLearningAgentExecutor().execute(
        LearningAgentExecutionContext(
          buildContext: buildContext,
          ref: widgetRef,
          plan: _plan(),
          sessionId: 'session-1',
          initialState: initialState,
          initialTraceEvents: [_event(id: 'event-1')],
          persistToolStartCheckpoint: (state, traceEvents) async {
            checkpointWriteCount++;
          },
        ),
      );

      expect(result.isFailed, isTrue);
      expect(checkpointWriteCount, 0);
      expect(result.state?.activeToolOperationId, isNull);
      expect(result.state?.activeToolInputSnapshot, isNull);
      expect(
        result.traceEvents.last.type,
        LearningAgentTraceEventType.toolInputRejected,
      );
      expect(result.message, contains('重试输入发生变化'));
    });

    test('tool-start checkpoint advances revision before tool result',
        () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final planCheckpoint = await runtime.persistCheckpoint(
        state: _resumableState(),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );
      final toolStartCheckpoint = await runtime.persistCheckpoint(
        state: planCheckpoint.state,
        traceEvents: [
          ...planCheckpoint.traceEvents,
          _event(
            id: 'event-tool-started',
            type: LearningAgentTraceEventType.toolStarted,
          ),
        ],
        plan: _plan(),
        checkpointRevision: planCheckpoint.revision,
      );
      final resultCheckpoint = await runtime.persistCheckpoint(
        state: toolStartCheckpoint.state,
        traceEvents: [
          ...toolStartCheckpoint.traceEvents,
          _event(
            id: 'event-tool-completed',
            type: LearningAgentTraceEventType.toolCompleted,
          ),
        ],
        plan: _plan(),
        checkpointRevision: toolStartCheckpoint.revision,
      );

      expect(planCheckpoint.revision, 1);
      expect(toolStartCheckpoint.revision, 2);
      expect(resultCheckpoint.revision, 3);
      expect(
        store.savedCheckpoints.map((checkpoint) => checkpoint.revision),
        [1, 2, 3],
      );
      expect(
        store.savedCheckpoints
            .map((checkpoint) => checkpoint.sessionId)
            .toSet(),
        {'session-1'},
      );
      expect(
        store.savedCheckpoints[1].traceEvents.last.type,
        LearningAgentTraceEventType.toolStarted,
      );
      expect(
        store.savedCheckpoints[2].traceEvents.last.type,
        LearningAgentTraceEventType.toolCompleted,
      );
    });

    test('plan snapshot codec preserves resume-critical fields', () {
      const codec = LearningAgentPlanCodec();
      final plan = _plan();

      final decoded = codec.decode(codec.encode(plan));

      expect(decoded.goal, plan.goal);
      expect(decoded.nextStep?.type, LearningAgentStepType.importSources);
      expect(decoded.sessionSummary.targetLabel, '来源库');
      expect(decoded.sessionSummary.successCriteria, ['import source']);
      expect(decoded.memory.goalSessionCount, 2);
    });

    test('user decision request supports JSON and legacy text storage', () {
      final request = _decisionRequest();

      final decoded = LearningAgentUserDecisionRequest.fromStorageValue(
        request.toStorageValue(),
      );
      final legacy = LearningAgentUserDecisionRequest.fromStorageValue(
        '继续执行旧 checkpoint？',
        fallbackRequestedAt: DateTime(2026, 7, 13, 8),
        fallbackToolId: LearningAgentToolId.importSources.value,
      );
      final restoredState = LearningAgentState.fromMap(
        _resumableState().copyWith(pendingUserDecision: request).toMap(),
      );
      final legacyStateMap = _resumableState().toMap();
      legacyStateMap['pending_user_decision'] = '处理旧版待决策状态？';
      final restoredLegacyState = LearningAgentState.fromMap(legacyStateMap);

      expect(decoded?.id, request.id);
      expect(decoded?.prompt, request.prompt);
      expect(decoded?.requestedAt, request.requestedAt);
      expect(decoded?.toolId, request.toolId);
      expect(
        decoded?.reason,
        LearningAgentUserDecisionReason.toolInterrupted,
      );
      expect(legacy?.prompt, '继续执行旧 checkpoint？');
      expect(
        legacy?.reason,
        LearningAgentUserDecisionReason.legacyCheckpoint,
      );
      expect(restoredState.pendingUserDecision?.id, request.id);
      expect(
        restoredLegacyState.pendingUserDecision?.prompt,
        '处理旧版待决策状态？',
      );
    });

    test('state map preserves its active tool operation id', () {
      final state = _resumableState().copyWith(
        activeToolOperationId: 'operation-import-1',
        activeToolInputSnapshot: _toolInputSnapshot(),
      );

      final restored = LearningAgentState.fromMap(state.toMap());

      expect(restored.activeToolOperationId, 'operation-import-1');
      expect(
        restored.activeToolInputSnapshot?.toStorageValue(),
        state.activeToolInputSnapshot?.toStorageValue(),
      );
    });

    test('tool input snapshot normalizes ids and preserves readable JSON', () {
      final snapshot = LearningAgentToolInputSnapshot(
        toolId: ' import_sources ',
        targetId: ' import_sources ',
        evidenceChunkIds: const ['chunk-b', ' chunk-a ', 'chunk-b', ''],
      );

      final restored = LearningAgentToolInputSnapshot.fromStorageValue(
        snapshot.toStorageValue(),
      );

      expect(snapshot.toolId, LearningAgentToolId.importSources.value);
      expect(snapshot.targetId, 'import_sources');
      expect(snapshot.evidenceChunkIds, ['chunk-a', 'chunk-b']);
      expect(
        restored?.toStorageValue(),
        snapshot.toStorageValue(),
      );
    });

    test('unknown-outcome request JSON preserves operation and attempt ids',
        () {
      final request = _unknownOutcomeRequest();

      final decoded = LearningAgentUserDecisionRequest.fromStorageValue(
        request.toStorageValue(),
      );

      expect(
        decoded?.reason,
        LearningAgentUserDecisionReason.toolOutcomeUnknown,
      );
      expect(decoded?.toolId, LearningAgentToolId.importSources.value);
      expect(decoded?.operationId, 'operation-import-1');
      expect(decoded?.attemptId, 'event-tool-started');
    });

    test('version 2 user decision JSON remains readable', () {
      const stored = '{'
          '"version":2,'
          '"id":"version-2-decision",'
          '"prompt":"确认工具结果？",'
          '"requested_at":1783994400000,'
          '"tool_id":"import_sources",'
          '"attempt_id":"event-tool-started",'
          '"reason":"tool_outcome_unknown"'
          '}';

      final decoded = LearningAgentUserDecisionRequest.fromStorageValue(stored);
      final legacyStateMap = _resumableState().toMap();
      legacyStateMap['active_tool_operation_id'] = null;
      legacyStateMap['pending_user_decision'] = stored;
      final restoredState = LearningAgentState.fromMap(legacyStateMap);

      expect(decoded?.id, 'version-2-decision');
      expect(decoded?.operationId, isNull);
      expect(decoded?.attemptId, 'event-tool-started');
      expect(
        restoredState.activeToolOperationId,
        'legacy_operation_event-tool-started',
      );
      expect(
        restoredState.pendingUserDecision?.operationId,
        restoredState.activeToolOperationId,
      );
      expect(
        restoredState.activeToolInputSnapshot?.toolId,
        LearningAgentToolId.importSources.value,
      );
    });

    test('version 1 user decision JSON remains readable', () {
      const stored = '{'
          '"version":1,'
          '"id":"legacy-json-decision",'
          '"prompt":"继续执行？",'
          '"requested_at":1783906200000,'
          '"tool_id":"import_sources",'
          '"reason":"tool_interrupted"'
          '}';

      final decoded = LearningAgentUserDecisionRequest.fromStorageValue(stored);

      expect(decoded?.id, 'legacy-json-decision');
      expect(
        decoded?.reason,
        LearningAgentUserDecisionReason.toolInterrupted,
      );
      expect(decoded?.attemptId, isNull);
    });

    test('unknown tool outcome requires an operation id', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _resumableState().copyWith(
            activeToolOperationId: 'operation-import-1',
            activeToolInputSnapshot: _toolInputSnapshot(),
            pendingUserDecision: LearningAgentUserDecisionRequest(
              id: 'decision-missing-operation',
              prompt: '工具结果未知',
              requestedAt: DateTime(2026, 7, 14, 10),
              toolId: LearningAgentToolId.importSources.value,
              attemptId: 'event-tool-started',
              reason: LearningAgentUserDecisionReason.toolOutcomeUnknown,
            ),
          ),
          traceEvents: [_toolStartedEvent()],
          plan: _plan(),
        ),
        throwsArgumentError,
      );
    });

    test('unknown tool outcome operation must match the active operation', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _unknownOutcomeState().copyWith(
            activeToolOperationId: 'operation-import-2',
          ),
          traceEvents: [_toolStartedEvent()],
          plan: _plan(),
        ),
        throwsArgumentError,
      );
    });

    test('unknown tool outcome requires an attempt id', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _resumableState().copyWith(
            activeToolOperationId: 'operation-import-1',
            activeToolInputSnapshot: _toolInputSnapshot(),
            pendingUserDecision: LearningAgentUserDecisionRequest(
              id: 'decision-missing-attempt',
              prompt: '工具结果未知',
              requestedAt: DateTime(2026, 7, 14, 10),
              toolId: LearningAgentToolId.importSources.value,
              operationId: 'operation-import-1',
              reason: LearningAgentUserDecisionReason.toolOutcomeUnknown,
            ),
          ),
          traceEvents: [_event(id: 'event-1')],
          plan: _plan(),
        ),
        throwsArgumentError,
      );
    });

    test('unknown tool outcome requires an existing attempt trace', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _unknownOutcomeState(),
          traceEvents: [_event(id: 'event-1')],
          plan: _plan(),
        ),
        throwsArgumentError,
      );
    });

    test('active tool input must match checkpoint routing state', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _resumableState().copyWith(
            activeToolOperationId: 'operation-import-1',
            activeToolInputSnapshot: _toolInputSnapshot(
              targetId: 'another-target',
            ),
          ),
          traceEvents: [_event(id: 'event-1')],
          plan: _plan(),
        ),
        throwsArgumentError,
      );
    });

    test('unknown tool outcome attempt must be a tool-start trace', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _unknownOutcomeState(),
          traceEvents: [
            _event(
              id: 'event-tool-started',
              toolId: LearningAgentToolId.importSources.value,
            ),
          ],
          plan: _plan(),
        ),
        throwsArgumentError,
      );
    });

    test('unknown tool outcome attempt must use the requested tool', () {
      expect(
        () => LearningAgentCheckpoint(
          state: _unknownOutcomeState(),
          traceEvents: [
            _event(
              id: 'event-tool-started',
              type: LearningAgentTraceEventType.toolStarted,
              toolId: LearningAgentToolId.verifyPendingQuestions.value,
            ),
          ],
          plan: _plan(),
        ),
        throwsArgumentError,
      );
    });

    test('tool result clears a persisted unknown-outcome request', () {
      final recorder = LearningAgentTraceRecorder(
        initialState: _unknownOutcomeState(),
        initialEvents: [_toolStartedEvent()],
      );

      recorder.record(
        _event(
          id: 'event-tool-completed',
          type: LearningAgentTraceEventType.toolCompleted,
          toolId: LearningAgentToolId.importSources.value,
        ),
        phase: LearningAgentPhase.complete,
        clearPendingUserDecision: true,
        clearActiveToolOperation: true,
      );

      expect(recorder.state?.pendingUserDecision, isNull);
      expect(recorder.state?.activeToolOperationId, isNull);
      expect(recorder.state?.activeToolInputSnapshot, isNull);
      expect(recorder.state?.phase, LearningAgentPhase.complete);
    });

    test('tool failure clears the active operation', () {
      final recorder = LearningAgentTraceRecorder(
        initialState: _unknownOutcomeState(),
        initialEvents: [_toolStartedEvent()],
      );

      recorder.record(
        _event(
          id: 'event-tool-failed',
          type: LearningAgentTraceEventType.toolFailed,
          toolId: LearningAgentToolId.importSources.value,
        ),
        phase: LearningAgentPhase.blocked,
        clearPendingUserDecision: true,
        clearActiveToolOperation: true,
      );

      expect(recorder.state?.pendingUserDecision, isNull);
      expect(recorder.state?.activeToolOperationId, isNull);
      expect(recorder.state?.activeToolInputSnapshot, isNull);
    });

    test('state can explicitly clear a pending user decision', () {
      final waitingState = _resumableState().copyWith(
        pendingUserDecision: _decisionRequest(),
      );

      final clearedState = waitingState.copyWith(
        clearPendingUserDecision: true,
      );

      expect(waitingState.isWaitingForUser, isTrue);
      expect(clearedState.isWaitingForUser, isFalse);
      expect(clearedState.pendingUserDecision, isNull);
    });

    test('pending decision blocks resume without writing a checkpoint',
        () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final checkpoint = LearningAgentCheckpoint(
        state: _interruptedOperationState(),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );

      final readiness = runtime.evaluateResumeCheckpoint(checkpoint);
      final result = await runtime.resumeCheckpoint(checkpoint);

      expect(readiness.status, LearningAgentResumeStatus.waitingForUser);
      expect(readiness.canResume, isTrue);
      expect(readiness.requiresUserDecision, isTrue);
      expect(result.canResume, isFalse);
      expect(store.savedCheckpoints, isEmpty);
    });

    test('runtime refuses a legacy checkpoint without a plan snapshot',
        () async {
      final runtime = LearningAgentRuntime(
        checkpointStore: _RecordingCheckpointStore(),
      );
      final checkpoint = LearningAgentCheckpoint(
        state: _resumableState(),
        traceEvents: [_event(id: 'event-1')],
      );

      final result = await runtime.resumeCheckpoint(checkpoint);

      expect(result.canResume, isFalse);
      expect(result.readiness.status, LearningAgentResumeStatus.missingPlan);
    });

    test('runtime resumes the original session and records a resume trace',
        () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final resumedAt = DateTime(2026, 7, 13, 11);
      final checkpoint = LearningAgentCheckpoint(
        state: _resumableState(),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );

      final result = await runtime.resumeCheckpoint(
        checkpoint,
        reason: 'test resume',
        resumedAt: resumedAt,
      );

      expect(result.canResume, isTrue);
      expect(result.session?.sessionId, 'session-1');
      expect(result.session?.plan.sessionSummary.targetLabel, '来源库');
      expect(
        result.session?.traceEvents.last.type,
        LearningAgentTraceEventType.sessionResumed,
      );
      expect(result.session?.traceEvents.last.occurredAt, resumedAt);
      expect(result.session?.checkpointRevision, 1);
      expect(store.savedCheckpoint?.plan, isNotNull);
    });

    test('continue decision clears waiting state and resumes the session',
        () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final resolvedAt = DateTime(2026, 7, 13, 12);
      final checkpoint = LearningAgentCheckpoint(
        state: _interruptedOperationState(),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );

      final result = await runtime.resolveUserDecision(
        checkpoint,
        action: LearningAgentUserDecisionAction.continueSession,
        note: '重新打开导入工具',
        resolvedAt: resolvedAt,
      );

      expect(result.didResume, isTrue);
      expect(result.session?.sessionId, 'session-1');
      expect(result.session?.state.pendingUserDecision, isNull);
      expect(
        result.session?.state.activeToolOperationId,
        'operation-import-1',
      );
      expect(result.session?.state.activeToolInputSnapshot, isNotNull);
      expect(
        result.session?.traceEvents
            .map((event) => event.type)
            .toList()
            .sublist(1),
        [
          LearningAgentTraceEventType.userDecisionResolved,
          LearningAgentTraceEventType.sessionResumed,
        ],
      );
      expect(store.savedCheckpoints, hasLength(2));
      expect(result.checkpoint.revision, 2);
    });

    test('unknown outcome can be retried in the original act phase', () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final checkpoint = _unknownOutcomeCheckpoint();

      final result = await runtime.resolveUserDecision(
        checkpoint,
        action: LearningAgentUserDecisionAction.continueSession,
        note: '页面中没有看到导入结果',
        resolvedAt: DateTime(2026, 7, 14, 11),
      );

      expect(result.didResume, isTrue);
      expect(result.session?.sessionId, 'session-1');
      expect(result.session?.state.phase, LearningAgentPhase.act);
      expect(result.session?.state.pendingUserDecision, isNull);
      expect(
        result.session?.state.activeToolOperationId,
        'operation-import-1',
      );
      expect(result.session?.state.activeToolInputSnapshot, isNotNull);
      expect(store.savedCheckpoints.map((item) => item.revision), [1, 2]);
      expect(
        result.session?.traceEvents
            .map((event) => event.type)
            .toList()
            .sublist(1),
        [
          LearningAgentTraceEventType.userDecisionResolved,
          LearningAgentTraceEventType.sessionResumed,
        ],
      );
    });

    test('unknown outcome can be confirmed and resumed in reflect', () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final checkpoint = _unknownOutcomeCheckpoint();

      final result = await runtime.resolveUserDecision(
        checkpoint,
        action: LearningAgentUserDecisionAction.confirmToolCompleted,
        note: '已在来源库看到新内容',
        resolvedAt: DateTime(2026, 7, 14, 12),
      );

      final decisionEvent = result.session?.traceEvents.firstWhere(
        (event) =>
            event.type == LearningAgentTraceEventType.userDecisionResolved,
      );
      expect(result.didResume, isTrue);
      expect(result.session?.state.phase, LearningAgentPhase.reflect);
      expect(result.session?.state.pendingUserDecision, isNull);
      expect(result.session?.state.activeToolOperationId, isNull);
      expect(result.session?.state.activeToolInputSnapshot, isNull);
      expect(store.savedCheckpoints.map((item) => item.revision), [1, 2]);
      expect(decisionEvent?.detail, contains('event-tool-started'));
      expect(
        result.session?.traceEvents.last.type,
        LearningAgentTraceEventType.sessionResumed,
      );
      expect(result.checkpoint.revision, 2);
    });

    test('completed confirmation is rejected for ordinary interruptions',
        () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final checkpoint = LearningAgentCheckpoint(
        state: _interruptedOperationState(),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );

      await expectLater(
        runtime.resolveUserDecision(
          checkpoint,
          action: LearningAgentUserDecisionAction.confirmToolCompleted,
        ),
        throwsStateError,
      );
      expect(store.savedCheckpoints, isEmpty);
    });

    test('cancel decision records a terminal checkpoint without resuming',
        () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final checkpoint = LearningAgentCheckpoint(
        state: _interruptedOperationState(),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );

      final result = await runtime.resolveUserDecision(
        checkpoint,
        action: LearningAgentUserDecisionAction.cancelSession,
        resolvedAt: DateTime(2026, 7, 13, 13),
      );

      expect(result.didResume, isFalse);
      expect(result.checkpoint.state.phase, LearningAgentPhase.canceled);
      expect(result.checkpoint.state.isTerminal, isTrue);
      expect(result.checkpoint.state.pendingUserDecision, isNull);
      expect(result.checkpoint.state.activeToolOperationId, isNull);
      expect(result.checkpoint.state.activeToolInputSnapshot, isNull);
      expect(
        result.checkpoint.traceEvents.last.type,
        LearningAgentTraceEventType.userDecisionResolved,
      );
      expect(result.readiness.status, LearningAgentResumeStatus.canceled);
      expect(store.savedCheckpoints, hasLength(1));
      expect(result.checkpoint.revision, 1);
    });

    test('runtime refuses a checkpoint whose tool differs from its plan',
        () async {
      final runtime = LearningAgentRuntime(
        checkpointStore: _RecordingCheckpointStore(),
      );
      final checkpoint = LearningAgentCheckpoint(
        state: _state(
          phase: LearningAgentPhase.act,
          targetId: 'import_sources',
          selectedToolId: LearningAgentToolId.verifyPendingQuestions.value,
        ),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );

      final result = await runtime.resumeCheckpoint(checkpoint);

      expect(result.canResume, isFalse);
      expect(
        result.readiness.status,
        LearningAgentResumeStatus.incompatiblePlan,
      );
    });

    test('runtime refuses a decision request for another tool', () {
      final runtime = LearningAgentRuntime(
        checkpointStore: _RecordingCheckpointStore(),
      );
      final checkpoint = LearningAgentCheckpoint(
        state: _resumableState().copyWith(
          pendingUserDecision: LearningAgentUserDecisionRequest(
            id: 'decision-other-tool',
            prompt: '继续执行？',
            requestedAt: DateTime(2026, 7, 13, 9, 30),
            toolId: LearningAgentToolId.verifyPendingQuestions.value,
            reason: LearningAgentUserDecisionReason.toolInterrupted,
          ),
        ),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );

      final readiness = runtime.evaluateResumeCheckpoint(checkpoint);

      expect(readiness.status, LearningAgentResumeStatus.incompatiblePlan);
    });

    test('checkpoint revision rejects a stale runtime write', () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final first = await runtime.persistCheckpoint(
        state: _resumableState(),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
      );
      final second = await runtime.persistCheckpoint(
        state: _resumableState(),
        traceEvents: [_event(id: 'event-1')],
        plan: _plan(),
        checkpointRevision: first.revision,
      );

      expect(first.revision, 1);
      expect(second.revision, 2);
      await expectLater(
        runtime.persistCheckpoint(
          state: _resumableState(),
          traceEvents: [_event(id: 'event-1')],
          plan: _plan(),
          checkpointRevision: first.revision,
        ),
        throwsA(
          isA<LearningAgentCheckpointConflictException>()
              .having(
                (error) => error.expectedRevision,
                'expectedRevision',
                1,
              )
              .having(
                (error) => error.actualRevision,
                'actualRevision',
                2,
              ),
        ),
      );
      expect(store.savedCheckpoint?.revision, 2);
    });

    test('the same user decision checkpoint cannot be resolved twice',
        () async {
      final store = _RecordingCheckpointStore();
      final runtime = LearningAgentRuntime(checkpointStore: store);
      final waiting = await store.save(
        LearningAgentCheckpoint(
          state: _resumableState().copyWith(
            pendingUserDecision: _decisionRequest(),
          ),
          traceEvents: [_event(id: 'event-1')],
          plan: _plan(),
        ),
      );

      final first = await runtime.resolveUserDecision(
        waiting,
        action: LearningAgentUserDecisionAction.cancelSession,
        resolvedAt: DateTime(2026, 7, 13, 14),
      );

      expect(first.checkpoint.revision, 2);
      await expectLater(
        runtime.resolveUserDecision(
          waiting,
          action: LearningAgentUserDecisionAction.cancelSession,
          resolvedAt: DateTime(2026, 7, 13, 15),
        ),
        throwsA(isA<LearningAgentCheckpointConflictException>()),
      );
      expect(store.savedCheckpoint?.revision, 2);
      expect(
        store.savedCheckpoint?.traceEvents.last.type,
        LearningAgentTraceEventType.userDecisionResolved,
      );
    });
  });
}

class _RecordingCheckpointStore implements LearningAgentCheckpointStore {
  LearningAgentCheckpoint? savedCheckpoint;
  final List<LearningAgentCheckpoint> savedCheckpoints = [];

  @override
  Future<LearningAgentCheckpoint> save(
    LearningAgentCheckpoint checkpoint,
  ) async {
    final actualRevision = savedCheckpoint?.sessionId == checkpoint.sessionId
        ? savedCheckpoint!.revision
        : 0;
    if (checkpoint.revision != actualRevision) {
      throw LearningAgentCheckpointConflictException(
        sessionId: checkpoint.sessionId,
        expectedRevision: checkpoint.revision,
        actualRevision: actualRevision,
      );
    }
    final saved = checkpoint.withRevision(actualRevision + 1);
    savedCheckpoint = saved;
    savedCheckpoints.add(saved);
    return saved;
  }

  @override
  Future<LearningAgentCheckpoint?> load(String sessionId) async => null;

  @override
  Future<List<LearningAgentCheckpoint>> loadActive({int limit = 20}) async {
    return savedCheckpoint == null ? [] : [savedCheckpoint!];
  }

  @override
  Future<void> delete(String sessionId) async {}
}

LearningAgentState _state({
  List<String> traceEventIds = const [],
  LearningAgentPhase phase = LearningAgentPhase.plan,
  String? targetId,
  String? selectedToolId,
  String? activeToolOperationId,
  LearningAgentToolInputSnapshot? activeToolInputSnapshot,
  LearningAgentUserDecisionRequest? pendingUserDecision,
}) {
  final now = DateTime(2026, 7, 13, 9);
  return LearningAgentState(
    sessionId: 'session-1',
    goal: LearningAgentGoal.projectWalkthrough,
    phase: phase,
    targetId: targetId,
    selectedToolId: selectedToolId,
    activeToolOperationId: activeToolOperationId,
    activeToolInputSnapshot: activeToolInputSnapshot,
    pendingUserDecision: pendingUserDecision,
    traceEventIds: traceEventIds,
    createdAt: now,
    updatedAt: now,
  );
}

LearningAgentState _resumableState() {
  return _state(
    phase: LearningAgentPhase.act,
    targetId: 'import_sources',
    selectedToolId: LearningAgentToolId.importSources.value,
  );
}

LearningAgentUserDecisionRequest _decisionRequest() {
  return LearningAgentUserDecisionRequest.toolInterrupted(
    sessionId: 'session-1',
    toolTitle: '导入来源',
    toolId: LearningAgentToolId.importSources.value,
    requestedAt: DateTime(2026, 7, 13, 9, 30),
  );
}

LearningAgentState _interruptedOperationState() {
  const operationId = 'operation-import-1';
  return _resumableState().copyWith(
    activeToolOperationId: operationId,
    activeToolInputSnapshot: _toolInputSnapshot(),
    pendingUserDecision: LearningAgentUserDecisionRequest.toolInterrupted(
      sessionId: 'session-1',
      toolTitle: '导入来源',
      toolId: LearningAgentToolId.importSources.value,
      operationId: operationId,
      requestedAt: DateTime(2026, 7, 13, 9, 30),
    ),
  );
}

LearningAgentUserDecisionRequest _unknownOutcomeRequest() {
  return LearningAgentUserDecisionRequest.toolOutcomeUnknown(
    sessionId: 'session-1',
    toolTitle: '导入来源',
    toolId: LearningAgentToolId.importSources.value,
    operationId: 'operation-import-1',
    attemptId: 'event-tool-started',
    requestedAt: DateTime(2026, 7, 14, 10),
  );
}

LearningAgentState _unknownOutcomeState() {
  return _resumableState().copyWith(
    activeToolOperationId: 'operation-import-1',
    activeToolInputSnapshot: _toolInputSnapshot(),
    pendingUserDecision: _unknownOutcomeRequest(),
  );
}

LearningAgentToolInputSnapshot _toolInputSnapshot({
  String targetId = 'import_sources',
  List<String> evidenceChunkIds = const [],
}) {
  return LearningAgentToolInputSnapshot(
    toolId: LearningAgentToolId.importSources.value,
    targetId: targetId,
    evidenceChunkIds: evidenceChunkIds,
  );
}

LearningAgentTraceEvent _toolStartedEvent() {
  return _event(
    id: 'event-tool-started',
    type: LearningAgentTraceEventType.toolStarted,
    toolId: LearningAgentToolId.importSources.value,
  );
}

LearningAgentCheckpoint _unknownOutcomeCheckpoint() {
  return LearningAgentCheckpoint(
    state: _unknownOutcomeState(),
    traceEvents: [_toolStartedEvent()],
    plan: _plan(),
  );
}

LearningAgentPlan _plan({
  LearningAgentGoal goal = LearningAgentGoal.projectWalkthrough,
}) {
  const step = LearningAgentPlanStep(
    type: LearningAgentStepType.importSources,
    title: 'Import sources',
    description: 'Import a source',
    enabled: true,
    targetCount: 1,
  );
  return LearningAgentPlan(
    goal: goal,
    readiness: const LearningAgentReadiness(
      evidenceBackedPointCount: 0,
      practiceablePointCount: 0,
      verifiedQuestionCount: 0,
      pendingQuestionCount: 0,
    ),
    memory: const LearningAgentMemoryState(
      goalSessionCount: 2,
      goalOpenFollowUpCount: 0,
    ),
    steps: [step],
    sessionSummary: LearningAgentSessionSummary(
      goal: goal,
      nextStep: step,
      focusPoint: null,
      title: 'Import sources',
      objective: 'Import a source',
      targetLabel: '来源库',
      evidenceConstraint: 'Source required',
      memoryReminder: null,
      successCriteria: ['import source'],
      reflectionPrompts: ['what changed'],
    ),
  );
}

LearningAgentTraceEvent _event({
  required String id,
  String sessionId = 'session-1',
  LearningAgentTraceEventType type = LearningAgentTraceEventType.planCreated,
  String? toolId,
}) {
  return LearningAgentTraceEvent(
    id: id,
    sessionId: sessionId,
    goal: LearningAgentGoal.projectWalkthrough,
    type: type,
    occurredAt: DateTime(2026, 7, 13, 9),
    phase: LearningAgentPhase.plan,
    toolId: toolId,
    summary: 'test event',
  );
}
