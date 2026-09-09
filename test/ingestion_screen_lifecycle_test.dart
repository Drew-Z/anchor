import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/features/ingestion/ingestion_screen.dart';
import 'package:anchor_learning/services/ai/ai_task_result.dart';
import 'package:anchor_learning/services/ai/tasks/knowledge_extraction_task.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pending analysis owns the analyze action', (tester) async {
    final openai = _ControlledOpenAIService.pendingKey();
    await _pumpScreen(tester, openai: openai);
    await _enterText(tester);

    await _tapAnalyze(tester);
    await tester.tap(find.text('AI 拆解为题目'));
    await tester.pump();
    openai.pendingKey!.complete(false);
    await tester.pumpAndSettle();

    expect(openai.hasApiKeyCalls, 1);
  });

  testWidgets('late API-key result after route exit does not update UI',
      (tester) async {
    final openai = _ControlledOpenAIService.pendingKey();
    await _pumpScreen(tester, openai: openai);
    await _enterText(tester);

    await _tapAnalyze(tester);
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    openai.pendingKey!.complete(true);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('late AI extraction result after route exit does not update UI',
      (tester) async {
    final extraction = _ControlledKnowledgeExtractionTask.pending();
    await _pumpScreen(
      tester,
      openai: _ControlledOpenAIService.immediateKey(),
      extraction: extraction,
    );
    await _enterText(tester);

    await _tapAnalyze(tester);
    await tester.pump();
    for (var i = 0; i < 5 && extraction.runCalls == 0; i++) {
      await tester.pump();
    }
    expect(extraction.runCalls, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    extraction.pendingResult!.complete(
      AiTaskResult.success(KnowledgeExtractionResult(knowledgePoints: [])),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('mounted analysis failure remains retryable', (tester) async {
    final extraction = _ControlledKnowledgeExtractionTask.failure(
      'controlled extraction failure',
    );
    await _pumpScreen(
      tester,
      openai: _ControlledOpenAIService.immediateKey(),
      extraction: extraction,
    );
    await _enterText(tester);

    await _tapAnalyze(tester);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('分析失败: Bad state: controlled extraction failure'),
      findsOneWidget,
    );
    expect(find.text('AI 拆解为题目'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required OpenAIService openai,
  KnowledgeExtractionTask? extraction,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        openaiServiceProvider.overrideWithValue(openai),
        if (extraction != null)
          knowledgeExtractionTaskProvider.overrideWithValue(extraction),
      ],
      child: const MaterialApp(home: IngestionScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _enterText(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).last, 'A short source note.');
}

Future<void> _tapAnalyze(WidgetTester tester) async {
  final finder = find.text('AI 拆解为题目');
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

class _ControlledOpenAIService extends OpenAIService {
  final Completer<bool>? pendingKey;
  final bool immediateKey;
  int hasApiKeyCalls = 0;

  _ControlledOpenAIService._({this.pendingKey, this.immediateKey = false});

  factory _ControlledOpenAIService.pendingKey() =>
      _ControlledOpenAIService._(pendingKey: Completer<bool>());

  factory _ControlledOpenAIService.immediateKey() =>
      _ControlledOpenAIService._(immediateKey: true);

  @override
  Future<bool> hasApiKey({String? providerId}) {
    hasApiKeyCalls++;
    final pending = pendingKey;
    if (pending != null) return pending.future;
    return Future.value(immediateKey);
  }
}

class _ControlledKnowledgeExtractionTask extends KnowledgeExtractionTask {
  final Completer<AiTaskResult<KnowledgeExtractionResult>>? pendingResult;
  final String? failureMessage;
  int runCalls = 0;

  _ControlledKnowledgeExtractionTask._({
    this.pendingResult,
    this.failureMessage,
  }) : super(_ControlledOpenAIService.immediateKey());

  factory _ControlledKnowledgeExtractionTask.pending() =>
      _ControlledKnowledgeExtractionTask._(
        pendingResult: Completer<AiTaskResult<KnowledgeExtractionResult>>(),
      );

  factory _ControlledKnowledgeExtractionTask.failure(String message) =>
      _ControlledKnowledgeExtractionTask._(failureMessage: message);

  @override
  Future<AiTaskResult<KnowledgeExtractionResult>> run({
    required List<SourceChunk> sourceChunks,
  }) {
    runCalls++;
    final pending = pendingResult;
    if (pending != null) return pending.future;
    return Future.value(
      AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: failureMessage!,
      ),
    );
  }
}
