import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/services/ai/tasks/citation_verification_task.dart';
import 'package:anchor_learning/services/ingestion/source_grounded_ingestion_service.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('SourceGroundedIngestionService review decisions', () {
    late DatabaseHelper databaseHelper;
    late SourceGroundedIngestionService service;

    setUp(() {
      databaseHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
      );
      service = SourceGroundedIngestionService(
        databaseHelper: databaseHelper,
        citationVerificationTask:
            CitationVerificationTask(_UnusedOpenAIService()),
      );
    });

    tearDown(() => databaseHelper.close());

    test('saves approved points and filters questions for deleted points',
        () async {
      final fixture = _ReviewFixture();
      final result = await service.saveReviewedContent(
        fixture.request(
          pointDecisions: [
            _pointDecision(fixture.architecturePoint, approved: true),
            _pointDecision(fixture.boundaryPoint, deleted: true),
          ],
          questionDecisions: [
            _questionDecision(fixture.architectureQuestion),
            _questionDecision(fixture.boundaryQuestion),
          ],
        ),
      );

      expect(result.savedKnowledgePointCount, 1);
      expect(result.savedQuestionCount, 1);
      expect(
        (await databaseHelper.getAllKnowledgePoints()).map((point) => point.id),
        ['point-architecture'],
      );
      expect(
        (await databaseHelper.getQuestionsByDeck('deck-1'))
            .map((question) => question.id),
        ['question-architecture'],
      );
      expect((await databaseHelper.getDeck('deck-1'))?.questionCount, 1);
      expect(
        (await databaseHelper.getKnowledgePointSources('point-architecture'))
            .map((relation) => relation.sourceChunkId),
        ['chunk-architecture'],
      );
      expect(
        await databaseHelper.getKnowledgePoint('point-boundary'),
        isNull,
      );
    });

    test('persists approved knowledge without creating an empty deck',
        () async {
      final fixture = _ReviewFixture();
      final result = await service.saveReviewedContent(
        fixture.request(
          pointDecisions: [
            _pointDecision(fixture.architecturePoint, approved: true),
          ],
          questionDecisions: const [],
        ),
      );

      expect(result.savedKnowledgePointCount, 1);
      expect(result.savedQuestionCount, 0);
      expect(
        await databaseHelper.getKnowledgePoint('point-architecture'),
        isNotNull,
      );
      expect(await databaseHelper.getDeck('deck-1'), isNull);
      expect(await databaseHelper.getSource('source-1'), isNotNull);
    });

    test('does not save an approved point whose evidence is unreadable',
        () async {
      final fixture = _ReviewFixture();
      final request = SourceGroundedSaveRequest(
        source: fixture.source,
        chunks: fixture.chunks,
        knowledgePointDecisions: [
          _pointDecision(fixture.architecturePoint, approved: true),
        ],
        sourceChunkIdsByKnowledgePointId: const {
          'point-architecture': ['missing-chunk'],
        },
        deckId: 'deck-1',
        deckTitle: 'Project interview',
        deckSourceText: 'project:source-1',
        questionDecisions: const [],
      );

      final result = await service.saveReviewedContent(request);
      expect(result.savedKnowledgePointCount, 0);
      expect(await databaseHelper.getSource('source-1'), isNull);
    });

    test('saves reviewed content against previously persisted source material',
        () async {
      final fixture = _ReviewFixture();
      await service.saveSourceMaterial(
        source: fixture.source,
        chunks: fixture.chunks,
      );

      final result = await service.saveReviewedContent(
        fixture.request(
          pointDecisions: [
            _pointDecision(fixture.architecturePoint, approved: true),
          ],
          questionDecisions: [
            _questionDecision(fixture.architectureQuestion),
          ],
          sourceMaterialAlreadySaved: true,
        ),
      );

      expect(result.savedKnowledgePointCount, 1);
      expect(result.savedQuestionCount, 1);
      expect((await databaseHelper.getSourceChunks('source-1')).length, 2);
      expect(
        await databaseHelper.getKnowledgePoint('point-architecture'),
        isNotNull,
      );
    });

    test('source material persistence is idempotent for the same snapshot',
        () async {
      final fixture = _ReviewFixture();

      await service.saveSourceMaterial(
        source: fixture.source,
        chunks: fixture.chunks,
      );
      await service.saveSourceMaterial(
        source: fixture.source,
        chunks: fixture.chunks,
      );

      expect((await databaseHelper.getAllSources()).length, 1);
      expect((await databaseHelper.getSourceChunks('source-1')).length, 2);
    });
  });
}

SourceGroundedKnowledgePointDecision _pointDecision(
  KnowledgePoint point, {
  bool approved = false,
  bool deleted = false,
}) {
  return SourceGroundedKnowledgePointDecision(
    knowledgePoint: point,
    approved: approved,
    deleted: deleted,
  );
}

SourceGroundedQuestionDecision _questionDecision(Question question) {
  return SourceGroundedQuestionDecision(
    question: question,
    sourceStatus: SourceStatus.verified,
    deleted: false,
  );
}

class _ReviewFixture {
  final DateTime now = DateTime(2026, 7, 14);

  late final Source source = Source(
    id: 'source-1',
    title: 'Project source',
    type: SourceType.project,
    trustLevel: SourceTrustLevel.sourceCode,
    createdAt: now,
    updatedAt: now,
  );

  late final List<SourceChunk> chunks = [
    _chunk('chunk-architecture', 'lib/app.dart:1-20'),
    _chunk('chunk-boundary', 'lib/storage.dart:1-12'),
  ];

  late final KnowledgePoint architecturePoint = _point(
    'point-architecture',
    KnowledgePointKind.architecture,
  );
  late final KnowledgePoint boundaryPoint = _point(
    'point-boundary',
    KnowledgePointKind.boundary,
  );
  late final Question architectureQuestion = _question(
    'question-architecture',
    architecturePoint.id,
    'chunk-architecture',
  );
  late final Question boundaryQuestion = _question(
    'question-boundary',
    boundaryPoint.id,
    'chunk-boundary',
  );

  SourceGroundedSaveRequest request({
    required List<SourceGroundedKnowledgePointDecision> pointDecisions,
    required List<SourceGroundedQuestionDecision> questionDecisions,
    bool sourceMaterialAlreadySaved = false,
  }) {
    return SourceGroundedSaveRequest(
      source: source,
      chunks: chunks,
      knowledgePointDecisions: pointDecisions,
      sourceChunkIdsByKnowledgePointId: const {
        'point-architecture': ['chunk-architecture'],
        'point-boundary': ['chunk-boundary'],
      },
      deckId: 'deck-1',
      deckTitle: 'Project interview',
      deckSourceText: 'project:source-1',
      questionDecisions: questionDecisions,
      sourceMaterialAlreadySaved: sourceMaterialAlreadySaved,
    );
  }

  SourceChunk _chunk(String id, String locator) {
    return SourceChunk(
      id: id,
      sourceId: source.id,
      chunkIndex: chunksLengthFor(id),
      content: 'source for $id',
      locator: locator,
      contentHash: 'hash-$id',
      createdAt: now,
    );
  }

  int chunksLengthFor(String id) => id == 'chunk-architecture' ? 0 : 1;

  KnowledgePoint _point(String id, KnowledgePointKind kind) {
    return KnowledgePoint(
      id: id,
      title: id,
      summary: 'summary for $id',
      kind: kind,
      createdAt: now,
      updatedAt: now,
    );
  }

  Question _question(String id, String pointId, String chunkId) {
    return Question(
      id: id,
      deckId: 'deck-1',
      knowledgePointId: pointId,
      type: QuestionType.fillBlank,
      content: 'question for $pointId',
      answer: 'answer',
      sourceStatus: SourceStatus.verified,
      citationIds: [chunkId],
    );
  }
}

class _UnusedOpenAIService extends OpenAIService {
  @override
  Future<String> chatCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
  }) {
    throw UnimplementedError();
  }
}
