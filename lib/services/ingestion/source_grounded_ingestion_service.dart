import 'package:sqflite/sqflite.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/deck.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/knowledge_point_source.dart';
import '../../data/models/product_event.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../ai/tasks/citation_verification_task.dart';
import '../ai/tasks/knowledge_extraction_task.dart';
import '../ai/tasks/project_understanding_task.dart';
import '../privacy/product_event_recorder.dart';

class KnowledgePointDraftBuildResult {
  final List<KnowledgePoint> knowledgePoints;
  final Map<String, List<String>> sourceChunkIdsByKnowledgePointId;

  const KnowledgePointDraftBuildResult({
    required this.knowledgePoints,
    required this.sourceChunkIdsByKnowledgePointId,
  });
}

class SourceGroundedQuestionDecision {
  final Question question;
  final SourceStatus sourceStatus;
  final bool deleted;

  const SourceGroundedQuestionDecision({
    required this.question,
    required this.sourceStatus,
    required this.deleted,
  });
}

class SourceGroundedKnowledgePointDecision {
  final KnowledgePoint knowledgePoint;
  final bool approved;
  final bool deleted;

  const SourceGroundedKnowledgePointDecision({
    required this.knowledgePoint,
    required this.approved,
    required this.deleted,
  });

  bool get shouldSave => approved && !deleted;
}

class SourceGroundedSaveRequest {
  final Source source;
  final List<SourceChunk> chunks;
  final List<SourceGroundedKnowledgePointDecision> knowledgePointDecisions;
  final Map<String, List<String>> sourceChunkIdsByKnowledgePointId;
  final String deckId;
  final String deckTitle;
  final String deckSourceText;
  final List<SourceGroundedQuestionDecision> questionDecisions;
  final bool sourceMaterialAlreadySaved;
  final String? eventFlowId;
  final String? eventGoal;

  const SourceGroundedSaveRequest({
    required this.source,
    required this.chunks,
    required this.knowledgePointDecisions,
    required this.sourceChunkIdsByKnowledgePointId,
    required this.deckId,
    required this.deckTitle,
    required this.deckSourceText,
    required this.questionDecisions,
    this.sourceMaterialAlreadySaved = false,
    this.eventFlowId,
    this.eventGoal,
  });
}

class SourceGroundedSaveResult {
  final int savedKnowledgePointCount;
  final int savedQuestionCount;

  const SourceGroundedSaveResult({
    required this.savedKnowledgePointCount,
    required this.savedQuestionCount,
  });
}

class SourceGroundedIngestionService {
  final DatabaseHelper _databaseHelper;
  final CitationVerificationTask _citationVerificationTask;
  final ProductEventRecorder? _eventRecorder;

  SourceGroundedIngestionService({
    required DatabaseHelper databaseHelper,
    required CitationVerificationTask citationVerificationTask,
    ProductEventRecorder? eventRecorder,
  })  : _databaseHelper = databaseHelper,
        _citationVerificationTask = citationVerificationTask,
        _eventRecorder = eventRecorder;

  KnowledgePointDraftBuildResult buildKnowledgePointDrafts({
    required String sourceId,
    required DateTime now,
    required List<ExtractedKnowledgePoint> extractedKnowledgePoints,
  }) {
    final sourceChunkIdsByKnowledgePointId = <String, List<String>>{};
    final knowledgePoints =
        extractedKnowledgePoints.asMap().entries.map((entry) {
      final index = entry.key;
      final draft = entry.value;
      final pointId = '${sourceId}_kp_$index';
      sourceChunkIdsByKnowledgePointId[pointId] = draft.sourceChunkIds;
      return KnowledgePoint(
        id: pointId,
        title: draft.title,
        summary: draft.summary,
        tags: draft.tags,
        difficulty: draft.difficulty,
        interviewRelevance: draft.interviewRelevance,
        masteryLevel: 0,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    return KnowledgePointDraftBuildResult(
      knowledgePoints: knowledgePoints,
      sourceChunkIdsByKnowledgePointId: sourceChunkIdsByKnowledgePointId,
    );
  }

  KnowledgePointDraftBuildResult buildProjectUnderstandingDrafts({
    required String sourceId,
    required DateTime now,
    required List<ProjectUnderstandingUnit> units,
  }) {
    final sourceChunkIdsByKnowledgePointId = <String, List<String>>{};
    final knowledgePoints = units.asMap().entries.map((entry) {
      final pointId = '${sourceId}_kp_${entry.key}';
      final unit = entry.value;
      sourceChunkIdsByKnowledgePointId[pointId] = unit.sourceChunkIds;
      return KnowledgePoint(
        id: pointId,
        title: unit.title,
        summary: unit.summary,
        kind: unit.kind,
        tags: unit.tags,
        difficulty: unit.difficulty,
        interviewRelevance: unit.interviewRelevance,
        masteryLevel: 0,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    return KnowledgePointDraftBuildResult(
      knowledgePoints: knowledgePoints,
      sourceChunkIdsByKnowledgePointId: sourceChunkIdsByKnowledgePointId,
    );
  }

  int questionCountFor(int knowledgePointCount) {
    return (knowledgePointCount * 2).clamp(4, 12).toInt();
  }

  Future<List<Question>> precheckQuestions({
    required List<Question> questions,
    required List<SourceChunk> chunks,
  }) async {
    final chunksById = {for (final chunk in chunks) chunk.id: chunk};
    final checked = <Question>[];

    for (final question in questions) {
      final validCitationIds =
          question.citationIds.where(chunksById.containsKey).toSet().toList();
      final questionForCheck = question.copyWith(
        citationIds: validCitationIds,
      );
      final citedChunks = validCitationIds
          .map((id) => chunksById[id])
          .whereType<SourceChunk>()
          .toList();
      final result = await _citationVerificationTask.run(
        question: questionForCheck,
        citedChunks: citedChunks,
      );

      if (!result.isSuccess) {
        checked.add(
          questionForCheck.copyWith(
            sourceStatus: validCitationIds.isEmpty
                ? SourceStatus.noSource
                : SourceStatus.pending,
          ),
        );
        continue;
      }

      final verification = result.requireData;
      final checkedCitationIds =
          verification.status == CitationVerificationStatus.noSource
              ? <String>[]
              : verification.supportedCitationIds.isEmpty
                  ? validCitationIds
                  : verification.supportedCitationIds;
      checked.add(
        questionForCheck.copyWith(
          sourceStatus: checkedCitationIds.isEmpty
              ? SourceStatus.noSource
              : SourceStatus.pending,
          citationIds: checkedCitationIds,
        ),
      );
    }

    return checked;
  }

  Future<void> saveSourceMaterial({
    required Source source,
    required List<SourceChunk> chunks,
  }) async {
    if (chunks.isEmpty) {
      throw StateError('至少需要一个项目材料片段');
    }
    if (chunks.any((chunk) => chunk.sourceId != source.id)) {
      throw StateError('项目材料与来源 ID 不一致');
    }
    if (chunks.map((chunk) => chunk.id).toSet().length != chunks.length) {
      throw StateError('项目材料包含重复 chunk ID');
    }

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final storedSource = await txn.query(
        'sources',
        where: 'id = ?',
        whereArgs: [source.id],
        limit: 1,
      );
      if (storedSource.isNotEmpty) {
        final storedChunks = await txn.query(
          'source_chunks',
          where: 'source_id = ?',
          whereArgs: [source.id],
        );
        final storedHashes = {
          for (final chunk in storedChunks)
            chunk['id']?.toString(): chunk['content_hash']?.toString(),
        };
        final unchanged = storedChunks.length == chunks.length &&
            chunks.every(
              (chunk) => storedHashes[chunk.id] == chunk.contentHash,
            );
        if (unchanged) return;
        throw StateError('同一来源 ID 已存在不同的项目材料');
      }

      await txn.insert('sources', source.toMap());
      for (final chunk in chunks) {
        await txn.insert('source_chunks', chunk.toMap());
      }
    });
  }

  Future<SourceGroundedSaveResult> saveReviewedContent(
    SourceGroundedSaveRequest request,
  ) async {
    final knownChunkIds = request.chunks.map((chunk) => chunk.id).toSet();
    final keptKnowledgePoints = request.knowledgePointDecisions
        .where((decision) {
          if (!decision.shouldSave) return false;
          final sourceChunkIds = request.sourceChunkIdsByKnowledgePointId[
                  decision.knowledgePoint.id] ??
              const [];
          return sourceChunkIds.any(knownChunkIds.contains);
        })
        .map((decision) => decision.knowledgePoint)
        .toList();
    final keptKnowledgePointIds =
        keptKnowledgePoints.map((point) => point.id).toSet();
    final keptQuestionDecisions = request.questionDecisions.where((decision) {
      if (decision.deleted) return false;
      final knowledgePointId = decision.question.knowledgePointId;
      return knowledgePointId == null ||
          keptKnowledgePointIds.contains(knowledgePointId);
    }).toList();
    if (keptKnowledgePoints.isEmpty && keptQuestionDecisions.isEmpty) {
      return const SourceGroundedSaveResult(
        savedKnowledgePointCount: 0,
        savedQuestionCount: 0,
      );
    }

    final now = DateTime.now();
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      if (request.sourceMaterialAlreadySaved) {
        await _verifyStoredSourceMaterial(txn, request);
      } else {
        await txn.insert('sources', request.source.toMap());

        for (final chunk in request.chunks) {
          await txn.insert('source_chunks', chunk.toMap());
        }
      }

      for (final point in keptKnowledgePoints) {
        await txn.insert('knowledge_points', point.toMap());
        final sourceChunkIds =
            request.sourceChunkIdsByKnowledgePointId[point.id] ?? const [];
        for (final chunkId in sourceChunkIds.where(knownChunkIds.contains)) {
          final relation = KnowledgePointSource(
            knowledgePointId: point.id,
            sourceChunkId: chunkId,
          );
          await txn.insert(
            'knowledge_point_sources',
            relation.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      if (keptQuestionDecisions.isNotEmpty) {
        await txn.insert(
          'decks',
          Deck(
            id: request.deckId,
            title: request.deckTitle,
            sourceText: request.deckSourceText,
            questionCount: keptQuestionDecisions.length,
            createdAt: now,
            updatedAt: now,
          ).toMap(),
        );
      }

      for (final entry in keptQuestionDecisions.asMap().entries) {
        final index = entry.key;
        final decision = entry.value;
        final validCitationIds = decision.sourceStatus == SourceStatus.noSource
            ? <String>[]
            : decision.question.citationIds
                .where(knownChunkIds.contains)
                .toSet()
                .toList();
        final sourceStatus = validCitationIds.isEmpty
            ? SourceStatus.noSource
            : decision.sourceStatus;
        final questionId = decision.question.id.isEmpty
            ? '${now.microsecondsSinceEpoch}_q_$index'
            : decision.question.id;
        final question = decision.question.copyWith(
          id: questionId,
          deckId: request.deckId,
          citationIds: validCitationIds,
          sourceStatus: sourceStatus,
        );
        await txn.insert('questions', question.toMap());
      }
    });

    final result = SourceGroundedSaveResult(
      savedKnowledgePointCount: keptKnowledgePoints.length,
      savedQuestionCount: keptQuestionDecisions.length,
    );
    await _eventRecorder?.recordBestEffort(
      ProductEventName.verifiedContentSaved,
      flowId: request.eventFlowId ?? 'ingestion_${request.source.id}',
      goal: request.eventGoal ?? 'unknown',
      properties: {
        'source_count': 1,
        'point_count': result.savedKnowledgePointCount,
        'question_count': result.savedQuestionCount,
        'exercise_count': 0,
      },
      dedupeKey: 'verified_content_saved:${request.source.id}',
    );
    return result;
  }

  Future<void> _verifyStoredSourceMaterial(
    DatabaseExecutor txn,
    SourceGroundedSaveRequest request,
  ) async {
    final storedSource = await txn.query(
      'sources',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [request.source.id],
      limit: 1,
    );
    if (storedSource.isEmpty) {
      throw StateError('本地项目来源已不存在，请重新导入');
    }
    final storedChunks = await txn.query(
      'source_chunks',
      columns: ['id'],
      where: 'source_id = ?',
      whereArgs: [request.source.id],
    );
    final storedChunkIds =
        storedChunks.map((chunk) => chunk['id']?.toString()).toSet();
    String? missingChunk;
    for (final chunk in request.chunks) {
      if (!storedChunkIds.contains(chunk.id)) {
        missingChunk = chunk.id;
        break;
      }
    }
    if (missingChunk != null) {
      throw StateError('本地项目证据片段已变化，请重新导入');
    }
  }
}
