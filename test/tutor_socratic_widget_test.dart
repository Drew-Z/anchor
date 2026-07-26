import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_prerequisite.dart';
import 'package:dlg_q/data/models/knowledge_point_source.dart';
import 'package:dlg_q/data/models/learning_session.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/models/tutor_turn.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/data/repositories/learning_session_repository.dart';
import 'package:dlg_q/data/repositories/source_chunk_repository.dart';
import 'package:dlg_q/features/agent/tutor_session_screen.dart';
import 'package:dlg_q/services/openai_service.dart';

import 'support/fake_programming_review_closure_service.dart';

void main() {
  testWidgets('answers one grounded tutor question and advances to the next',
      (tester) async {
    final now = DateTime(2026, 7, 15);
    final prerequisite = _point('state', 'State lifecycle', now);
    final point = _point('set-state', 'setState mechanism', now);
    final knowledgeRepository = _FakeKnowledgePointRepository(
      points: [point, prerequisite],
      sourcesByPointId: {
        point.id: [
          KnowledgePointSource(
            knowledgePointId: point.id,
            sourceChunkId: 'chunk-set-state',
          ),
        ],
        prerequisite.id: [
          KnowledgePointSource(
            knowledgePointId: prerequisite.id,
            sourceChunkId: 'chunk-state',
          ),
        ],
      },
      prerequisites: [
        KnowledgePointPrerequisite(
          knowledgePointId: point.id,
          prerequisiteKnowledgePointId: prerequisite.id,
          rationale: 'State comes first.',
          citationIds: const ['chunk-state'],
          createdAt: now,
        ),
      ],
    );
    final chunkRepository = _FakeSourceChunkRepository({
      'chunk-set-state': _chunk(
        'chunk-set-state',
        'Calling setState notifies the framework that state changed.',
      ),
      'chunk-state': _chunk(
        'chunk-state',
        'State objects hold mutable information for a widget.',
      ),
    });
    final sessionRepository = _FakeLearningSessionRepository();
    final openai = _SequencedOpenAIService([
      {
        'definition_and_intuition': 'setState reports a state change.',
        'mechanism': 'The framework schedules a rebuild after the callback.',
        'code_or_doc_example': 'The source calls setState around the mutation.',
        'boundaries': 'The source only supports widget state changes.',
        'misconceptions': ['Mutation alone is not the notification call.'],
        'interview_expression': 'Separate mutation from rebuild notification.',
        'opening_question': 'What does setState notify the framework about?',
        'citation_ids': ['chunk-set-state', 'chunk-state'],
        'unsupported_layers': [],
        'evidence_sufficient': true,
      },
      {
        'feedback': 'You identified the state change but omitted the rebuild.',
        'reference_answer': 'It reports the change so a rebuild is scheduled.',
        'misconception': 'setState was described as directly drawing the UI.',
        'next_question': 'Why is understanding State a prerequisite here?',
        'citation_ids': ['chunk-set-state', 'chunk-state'],
        'evidence_sufficient': true,
        'accuracy_score': 70,
        'claims': [
          {
            'section': 'feedback',
            'text': 'You identified the state change but omitted the rebuild.',
            'evidence': [
              {
                'citation_id': 'chunk-set-state',
                'quote': 'notifies the framework that state changed',
              },
            ],
          },
          {
            'section': 'reference_answer',
            'text': 'It reports the change so a rebuild is scheduled.',
            'evidence': [
              {
                'citation_id': 'chunk-set-state',
                'quote': 'Calling setState notifies the framework',
              },
            ],
          },
          {
            'section': 'misconception',
            'text': 'setState was described as directly drawing the UI.',
            'evidence': [
              {
                'citation_id': 'chunk-state',
                'quote': 'State objects hold mutable information',
              },
            ],
          },
        ],
      },
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openaiServiceProvider.overrideWithValue(openai),
          knowledgePointRepositoryProvider
              .overrideWithValue(knowledgeRepository),
          sourceChunkRepositoryProvider.overrideWithValue(chunkRepository),
          learningSessionRepositoryProvider
              .overrideWithValue(sessionRepository),
          programmingReviewClosureServiceProvider.overrideWithValue(
            FakeProgrammingReviewClosureService(
              onTutorTurn: (turn) async {
                await sessionRepository.insertTutorTurn(turn);
              },
            ),
          ),
          evidenceBackedKnowledgePointListProvider.overrideWith(
            (ref) async => [point, prerequisite],
          ),
          sourceProvider.overrideWith(
            (ref, sourceId) async => Source(
              id: sourceId,
              title: 'Flutter framework source',
              type: SourceType.officialDoc,
              trustLevel: SourceTrustLevel.officialDoc,
              createdAt: now,
              updatedAt: now,
            ),
          ),
        ],
        child: MaterialApp(home: TutorSessionScreen(initialPoint: point)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('定义与直觉'), findsOneWidget);
    expect(find.textContaining('setState reports'), findsOneWidget);
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('tutor-answer-input')),
      find.byType(ListView),
      const Offset(0, -500),
    );
    expect(
      find.text(
        'What does setState notify the framework about?',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('tutor-answer-input')),
      'It directly redraws after state changes.',
    );
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('tutor-submit-answer')),
      find.byType(ListView),
      const Offset(0, -250),
    );
    await tester.tap(find.byKey(const ValueKey('tutor-submit-answer')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(
        'Why is understanding State a prerequisite here?',
        skipOffstage: false,
      ),
      350,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.textContaining('omitted the rebuild'), findsOneWidget);
    expect(find.textContaining('directly drawing'), findsOneWidget);
    expect(
      find.text('Why is understanding State a prerequisite here?'),
      findsOneWidget,
    );
    expect(sessionRepository.turns, hasLength(1));
    expect(sessionRepository.turns.single.citationIds, hasLength(2));
    expect(sessionRepository.turns.single.accuracyScore, 70);
    expect(openai.userContents.last, contains('id: chunk-state'));
    expect(openai.userContents.last, contains('current_turn'));
  });
}

KnowledgePoint _point(String id, String title, DateTime now) {
  return KnowledgePoint(
    id: id,
    title: title,
    summary: '$title summary',
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk(String id, String content) {
  return SourceChunk(
    id: id,
    sourceId: 'source',
    chunkIndex: 0,
    content: content,
    locator: 'snapshot:L1-L1',
    contentHash: 'hash-$id',
    createdAt: DateTime(2026, 7, 15),
  );
}

class _FakeKnowledgePointRepository extends KnowledgePointRepository {
  final List<KnowledgePoint> points;
  final Map<String, List<KnowledgePointSource>> sourcesByPointId;
  final List<KnowledgePointPrerequisite> prerequisites;

  _FakeKnowledgePointRepository({
    required this.points,
    required this.sourcesByPointId,
    required this.prerequisites,
  }) : super(DatabaseHelper());

  @override
  Future<KnowledgePoint?> getKnowledgePoint(String id) async {
    for (final point in points) {
      if (point.id == id) return point;
    }
    return null;
  }

  @override
  Future<List<KnowledgePointSource>> getKnowledgePointSources(String id) async {
    return sourcesByPointId[id] ?? const [];
  }

  @override
  Future<List<KnowledgePointPrerequisite>>
      getKnowledgePointPrerequisites() async => prerequisites;
}

class _FakeSourceChunkRepository extends SourceChunkRepository {
  final Map<String, SourceChunk> chunks;

  _FakeSourceChunkRepository(this.chunks) : super(DatabaseHelper());

  @override
  Future<SourceChunk?> getSourceChunk(String id) async => chunks[id];
}

class _FakeLearningSessionRepository extends LearningSessionRepository {
  final Map<String, LearningSession> sessions = {};
  final List<TutorTurn> turns = [];

  _FakeLearningSessionRepository() : super(DatabaseHelper());

  @override
  Future<String> insertLearningSession(LearningSession session) async {
    sessions[session.id] = session;
    return session.id;
  }

  @override
  Future<LearningSession?> getLearningSession(String id) async => sessions[id];

  @override
  Future<void> updateLearningSession(LearningSession session) async {
    sessions[session.id] = session;
  }

  @override
  Future<String> insertTutorTurn(TutorTurn turn) async {
    turns.add(turn);
    return turn.id;
  }
}

class _SequencedOpenAIService extends OpenAIService {
  final List<Object> responses;
  final List<String> userContents = [];
  int _index = 0;

  _SequencedOpenAIService(this.responses);

  @override
  Future<bool> hasApiKey({String? providerId}) async => true;

  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) async {
    userContents.add(userContent);
    return jsonEncode(responses[_index++]);
  }
}
