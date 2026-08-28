import '../../data/models/grounded_claim.dart';
import '../../data/models/interview_turn.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/knowledge_point_source.dart';
import '../../data/models/programming_exercise_attempt.dart';
import '../../data/models/programming_review_action.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../data/models/tutor_turn.dart';
import '../ai/grounded_claim_gate.dart';
import 'learning_agent_memory_record.dart';
import 'learning_agent_memory_store.dart';
import 'project_interview_flow_service.dart';

enum ProjectInterviewOutcomeStatus {
  ready('ready', '可面试'),
  needsPractice('needs_practice', '需要练习'),
  evidenceGap('evidence_gap', '证据缺口'),
  notAssessed('not_assessed', '尚未评估');

  final String value;
  final String label;

  const ProjectInterviewOutcomeStatus(this.value, this.label);
}

enum ProjectInterviewOutcomeReasonCode {
  missingEvidence('missing_evidence', '没有可用的保存来源'),
  invalidEvaluationCitation('invalid_evaluation_citation', '评估引用超出该单元来源'),
  invalidClaimQuote('invalid_claim_quote', '评估主张的逐字引用未通过校验'),
  invalidPracticeEvidence('invalid_practice_evidence', '练习结果的来源依据未通过校验'),
  noUserParticipation('no_user_participation', '还没有真实回答或完成练习'),
  unsupportedEvaluation('unsupported_evaluation', '已有回答，但还没有完整的来源支持评估'),
  scoreBelowReady('score_below_ready', '四项面试能力尚未全部达到 4/5'),
  practiceBelowReady('practice_below_ready', '已完成来源核验练习，但尚未达到掌握门槛'),
  weakDimensions('weak_dimensions', '仍有薄弱能力维度'),
  openFollowUp('open_follow_up', '还有未处理的面试追问'),
  pendingReview('pending_review', '还有未完成的复习动作'),
  readyFromInterview('ready_from_interview', '来源支持的面试评估已达到门槛'),
  readyFromPractice('ready_from_practice', '已完成来源核验的练习目标');

  final String value;
  final String label;

  const ProjectInterviewOutcomeReasonCode(this.value, this.label);
}

class ProjectInterviewOutcomeScore {
  final int accuracy;
  final int projectDetail;
  final int engineering;
  final int clarity;

  const ProjectInterviewOutcomeScore({
    required this.accuracy,
    required this.projectDetail,
    required this.engineering,
    required this.clarity,
  });

  int get total => accuracy + projectDetail + engineering + clarity;

  double get average => total / 4;

  bool get meetsReadyThreshold =>
      accuracy >= 4 && projectDetail >= 4 && engineering >= 4 && clarity >= 4;

  int valueFor(InterviewScoreDimension dimension) {
    switch (dimension) {
      case InterviewScoreDimension.accuracy:
        return accuracy;
      case InterviewScoreDimension.projectDetail:
        return projectDetail;
      case InterviewScoreDimension.engineering:
        return engineering;
      case InterviewScoreDimension.clarity:
        return clarity;
    }
  }
}

class ProjectInterviewOutcomeEvidence {
  final Source source;
  final SourceChunk chunk;
  final KnowledgePointSourceRelation relation;
  final String excerpt;

  const ProjectInterviewOutcomeEvidence({
    required this.source,
    required this.chunk,
    required this.relation,
    required this.excerpt,
  });

  String get locator {
    final direct = chunk.locator?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final path = chunk.relativePath?.trim();
    if (path != null && path.isNotEmpty) {
      final start = chunk.startLine;
      final end = chunk.endLine;
      if (start != null && end != null) return '$path:$start-$end';
      if (start != null) return '$path:$start';
      return path;
    }
    final uri = source.uri?.trim();
    if (uri != null && uri.isNotEmpty) return uri;
    return '${source.title}#${chunk.chunkIndex}';
  }

  bool get hasCodeLocator =>
      (chunk.relativePath?.trim().isNotEmpty ?? false) ||
      (chunk.locator?.trim().isNotEmpty ?? false);
}

class ProjectInterviewOutcomeClaim {
  final String section;
  final String text;
  final List<ProjectInterviewOutcomeClaimEvidence> evidence;

  const ProjectInterviewOutcomeClaim({
    required this.section,
    required this.text,
    required this.evidence,
  });

  List<String> get citationIds => evidence
      .map((item) => item.sourceEvidence.chunk.id)
      .toSet()
      .toList(growable: false);
}

class ProjectInterviewOutcomeClaimEvidence {
  final ProjectInterviewOutcomeEvidence sourceEvidence;
  final String quote;

  const ProjectInterviewOutcomeClaimEvidence({
    required this.sourceEvidence,
    required this.quote,
  });
}

class ProjectInterviewOutcomeAnswer {
  final String surface;
  final String text;
  final DateTime createdAt;

  const ProjectInterviewOutcomeAnswer({
    required this.surface,
    required this.text,
    required this.createdAt,
  });
}

class ProjectInterviewOutcomeUnit {
  final KnowledgePoint point;
  final ProjectInterviewOutcomeStatus status;
  final List<ProjectInterviewOutcomeReasonCode> reasons;
  final List<ProjectInterviewOutcomeEvidence> evidence;
  final ProjectInterviewOutcomeEvidence? strongestEvidence;
  final InterviewTurn? latestInterviewTurn;
  final ProjectInterviewOutcomeScore? interviewScore;
  final List<InterviewScoreDimension> weakDimensions;
  final List<ProjectInterviewOutcomeEvidence> evaluationEvidence;
  final List<ProjectInterviewOutcomeClaim> referenceOutline;
  final ProjectInterviewOutcomeAnswer? latestAnswer;
  final String? openFollowUp;
  final DateTime? nextReviewAt;
  final int memoryRecordCount;
  final List<String> memoryWeakDimensions;
  final bool hasUserParticipation;
  final bool completedVerifiedPractice;
  final int openReviewActionCount;

  const ProjectInterviewOutcomeUnit({
    required this.point,
    required this.status,
    required this.reasons,
    required this.evidence,
    required this.strongestEvidence,
    required this.latestInterviewTurn,
    required this.interviewScore,
    required this.weakDimensions,
    required this.evaluationEvidence,
    required this.referenceOutline,
    required this.latestAnswer,
    required this.openFollowUp,
    required this.nextReviewAt,
    required this.memoryRecordCount,
    required this.memoryWeakDimensions,
    required this.hasUserParticipation,
    required this.completedVerifiedPractice,
    required this.openReviewActionCount,
  });

  List<String> get sourceIds =>
      evidence.map((item) => item.source.id).toSet().toList(growable: false);

  bool get hasOpenWork => openFollowUp != null || openReviewActionCount > 0;
}

class ProjectInterviewOutcome {
  final DateTime generatedAt;
  final String goal;
  final List<KnowledgePointKind> scope;
  final List<String> projectTitles;
  final List<ProjectInterviewOutcomeUnit> units;

  const ProjectInterviewOutcome({
    required this.generatedAt,
    required this.goal,
    required this.scope,
    required this.projectTitles,
    required this.units,
  });

  int get readyCount => _count(ProjectInterviewOutcomeStatus.ready);

  int get needsPracticeCount =>
      _count(ProjectInterviewOutcomeStatus.needsPractice);

  int get evidenceGapCount => _count(ProjectInterviewOutcomeStatus.evidenceGap);

  int get notAssessedCount => _count(ProjectInterviewOutcomeStatus.notAssessed);

  int get citationCount => _exportEvidence().length;

  ProjectInterviewOutcome forSource(String sourceId) {
    final normalized = sourceId.trim();
    if (normalized.isEmpty) return this;
    final filtered = units
        .where((unit) => unit.sourceIds.contains(normalized))
        .toList(growable: false);
    return _withUnits(filtered);
  }

  List<ProjectInterviewOutcomeEvidence> _exportEvidence() {
    final seen = <String>{};
    final result = <ProjectInterviewOutcomeEvidence>[];
    for (final unit in units) {
      final candidates = <ProjectInterviewOutcomeEvidence>[
        if (unit.strongestEvidence != null) unit.strongestEvidence!,
        ...unit.evaluationEvidence,
        ...unit.referenceOutline.expand(
          (claim) => claim.evidence.map((item) => item.sourceEvidence),
        ),
      ];
      for (final evidence in candidates) {
        if (seen.add(evidence.chunk.id)) result.add(evidence);
      }
    }
    return result;
  }

  ProjectInterviewOutcome _withUnits(List<ProjectInterviewOutcomeUnit> value) {
    final orderedKinds = <KnowledgePointKind>[];
    final titles = <String>[];
    for (final unit in value) {
      if (!orderedKinds.contains(unit.point.kind)) {
        orderedKinds.add(unit.point.kind);
      }
      for (final evidence in unit.evidence) {
        if (!titles.contains(evidence.source.title)) {
          titles.add(evidence.source.title);
        }
      }
    }
    return ProjectInterviewOutcome(
      generatedAt: generatedAt,
      goal: goal,
      scope: List.unmodifiable(orderedKinds),
      projectTitles: List.unmodifiable(titles),
      units: List.unmodifiable(value),
    );
  }

  int _count(ProjectInterviewOutcomeStatus status) {
    return units.where((unit) => unit.status == status).length;
  }
}

class ProjectInterviewOutcomeService {
  final ProjectInterviewFlowService _flow;
  final GroundedClaimGate _claimGate;

  const ProjectInterviewOutcomeService({
    ProjectInterviewFlowService flow = const ProjectInterviewFlowService(),
    GroundedClaimGate claimGate = const GroundedClaimGate(),
  })  : _flow = flow,
        _claimGate = claimGate;

  ProjectInterviewOutcome build({
    required List<KnowledgePoint> knowledgePoints,
    required List<KnowledgePointSource> knowledgePointSources,
    required List<Source> sources,
    required List<SourceChunk> sourceChunks,
    required List<InterviewTurn> interviewTurns,
    required List<TutorTurn> tutorTurns,
    required List<Question> questions,
    required List<ProgrammingExerciseAttempt> programmingAttempts,
    required List<ProgrammingReviewAction> reviewActions,
    required LearningAgentMemoryStore memoryStore,
    DateTime? now,
  }) {
    final generatedAt = (now ?? DateTime.now()).toUtc();
    final points = _flow
        .orderKnowledgePoints(
          knowledgePoints
              .where((point) => point.kind.isProjectUnderstanding)
              .toList(growable: false),
        )
        .toList(growable: false);
    final sourcesById = {for (final source in sources) source.id: source};
    final chunksById = {for (final chunk in sourceChunks) chunk.id: chunk};
    final relationsByPoint = <String, List<KnowledgePointSource>>{};
    for (final relation in knowledgePointSources) {
      relationsByPoint
          .putIfAbsent(relation.knowledgePointId, () => [])
          .add(relation);
    }

    final units = points
        .map(
          (point) => _buildUnit(
            point: point,
            relations: relationsByPoint[point.id] ?? const [],
            sourcesById: sourcesById,
            chunksById: chunksById,
            interviewTurns: interviewTurns,
            tutorTurns: tutorTurns,
            questions: questions,
            programmingAttempts: programmingAttempts,
            reviewActions: reviewActions,
            memory: memoryStore.query(targetId: point.id),
            now: generatedAt,
          ),
        )
        .toList(growable: false);

    return ProjectInterviewOutcome(
      generatedAt: generatedAt,
      goal: '讲清项目架构、数据流、实现、边界与取舍',
      scope: List.unmodifiable(
        units.map((unit) => unit.point.kind).toSet().toList(),
      ),
      projectTitles: List.unmodifiable(
        units
            .expand((unit) =>
                unit.evidence.map((evidence) => evidence.source.title))
            .toSet()
            .toList(),
      ),
      units: List.unmodifiable(units),
    );
  }

  ProjectInterviewOutcomeUnit _buildUnit({
    required KnowledgePoint point,
    required List<KnowledgePointSource> relations,
    required Map<String, Source> sourcesById,
    required Map<String, SourceChunk> chunksById,
    required List<InterviewTurn> interviewTurns,
    required List<TutorTurn> tutorTurns,
    required List<Question> questions,
    required List<ProgrammingExerciseAttempt> programmingAttempts,
    required List<ProgrammingReviewAction> reviewActions,
    required LearningAgentMemorySnapshot memory,
    required DateTime now,
  }) {
    final evidence = <ProjectInterviewOutcomeEvidence>[];
    for (final relation in relations) {
      final chunk = chunksById[relation.sourceChunkId];
      final source = chunk == null ? null : sourcesById[chunk.sourceId];
      if (chunk == null || source == null || chunk.content.trim().isEmpty) {
        continue;
      }
      evidence.add(
        ProjectInterviewOutcomeEvidence(
          source: source,
          chunk: chunk,
          relation: relation.relation,
          excerpt: _excerpt(chunk.content),
        ),
      );
    }
    evidence.sort(_compareEvidence);
    final evidenceByChunkId = {
      for (final item in evidence) item.chunk.id: item,
    };

    final pointInterviewTurns = interviewTurns
        .where((turn) => turn.knowledgePointId == point.id)
        .toList()
      ..sort(_compareInterviewTurnsNewestFirst);
    final assessmentTurn = pointInterviewTurns
        .where((turn) => turn.userAnswer.trim().isNotEmpty)
        .firstOrNull;
    final interviewAudit = assessmentTurn == null
        ? null
        : _auditEvaluation(
            claims: assessmentTurn.groundedClaims,
            citationIds: assessmentTurn.citationIds,
            disposition: assessmentTurn.groundingDisposition,
            evidenceByChunkId: evidenceByChunkId,
          );

    final pointTutorTurns = tutorTurns
        .where((turn) => turn.knowledgePointId == point.id)
        .where((turn) => turn.userAnswer.trim().isNotEmpty)
        .toList()
      ..sort(_compareTutorTurnsNewestFirst);
    final pointAttempts = programmingAttempts
        .where((attempt) => attempt.knowledgePointId == point.id)
        .where((attempt) => attempt.userAnswer.trim().isNotEmpty)
        .toList()
      ..sort(_compareAttemptsNewestFirst);

    final verifiedPractice = _findVerifiedPractice(
      pointId: point.id,
      masteryLevel: point.masteryLevel,
      questions: questions,
      attempts: pointAttempts,
      evidenceByChunkId: evidenceByChunkId,
    );
    final latestAnswer = _latestAnswer(
      interview: assessmentTurn,
      tutor: pointTutorTurns.firstOrNull,
      attempt: pointAttempts.firstOrNull,
    );

    final weakDimensions = _weakDimensions(assessmentTurn);
    final openFollowUp = _openFollowUp(
      memory: memory,
      turn: assessmentTurn,
    );
    final openReviewActions = reviewActions
        .where((action) =>
            action.knowledgePointId == point.id && !action.isCompleted)
        .length;
    final nextReviewAt = _nextReviewAt(
      point: point,
      questions: questions,
      memory: memory,
      turn: assessmentTurn,
      reviewActions: reviewActions,
      now: now,
    );
    final dueReview = _hasDueReview(
      point: point,
      questions: questions,
      memory: memory,
      reviewActions: reviewActions,
      now: now,
    );
    final hasParticipation =
        latestAnswer != null || verifiedPractice.completedAt != null;
    final practiceAfterInterview =
        verifiedPractice.qualifyingCompletedAt != null &&
            (assessmentTurn == null ||
                !verifiedPractice.qualifyingCompletedAt!
                    .isBefore(assessmentTurn.createdAt));
    final unresolvedWeakDimensions = practiceAfterInterview
        ? const <InterviewScoreDimension>[]
        : weakDimensions;
    final hasOpenWork = openFollowUp != null ||
        openReviewActions > 0 ||
        dueReview ||
        unresolvedWeakDimensions.isNotEmpty;

    final reasons = <ProjectInterviewOutcomeReasonCode>[];
    final status = _status(
      evidence: evidence,
      assessmentTurn: assessmentTurn,
      interviewAudit: interviewAudit,
      practice: verifiedPractice,
      hasParticipation: hasParticipation,
      practiceAfterInterview: practiceAfterInterview,
      hasOpenWork: hasOpenWork,
      openFollowUp: openFollowUp,
      openReviewActions: openReviewActions,
      dueReview: dueReview,
      weakDimensions: unresolvedWeakDimensions,
      reasons: reasons,
    );

    return ProjectInterviewOutcomeUnit(
      point: point,
      status: status,
      reasons: List.unmodifiable(reasons),
      evidence: List.unmodifiable(evidence),
      strongestEvidence: evidence.isEmpty ? null : evidence.first,
      latestInterviewTurn: assessmentTurn,
      interviewScore: assessmentTurn == null
          ? null
          : ProjectInterviewOutcomeScore(
              accuracy: assessmentTurn.accuracyScore,
              projectDetail: assessmentTurn.projectDetailScore,
              engineering: assessmentTurn.engineeringScore,
              clarity: assessmentTurn.clarityScore,
            ),
      weakDimensions: List.unmodifiable(unresolvedWeakDimensions),
      evaluationEvidence: List.unmodifiable(
        interviewAudit?.evidence ?? const [],
      ),
      referenceOutline: List.unmodifiable(
        interviewAudit?.claims
                .where((claim) => claim.section == 'reference_answer')
                .toList(growable: false) ??
            const [],
      ),
      latestAnswer: latestAnswer,
      openFollowUp: openFollowUp,
      nextReviewAt: nextReviewAt,
      memoryRecordCount: memory.recordCount,
      memoryWeakDimensions: List.unmodifiable(
        memory.weakDimensions.map((item) => item.label).toSet(),
      ),
      hasUserParticipation: hasParticipation,
      completedVerifiedPractice: verifiedPractice.completedAt != null,
      openReviewActionCount: openReviewActions,
    );
  }

  ProjectInterviewOutcomeStatus _status({
    required List<ProjectInterviewOutcomeEvidence> evidence,
    required InterviewTurn? assessmentTurn,
    required _EvaluationAudit? interviewAudit,
    required _VerifiedPractice practice,
    required bool hasParticipation,
    required bool practiceAfterInterview,
    required bool hasOpenWork,
    required String? openFollowUp,
    required int openReviewActions,
    required bool dueReview,
    required List<InterviewScoreDimension> weakDimensions,
    required List<ProjectInterviewOutcomeReasonCode> reasons,
  }) {
    if (evidence.isEmpty) {
      reasons.add(ProjectInterviewOutcomeReasonCode.missingEvidence);
      return ProjectInterviewOutcomeStatus.evidenceGap;
    }
    if (interviewAudit?.hasDefect == true || practice.hasEvidenceDefect) {
      if (interviewAudit?.hasCitationDefect == true) {
        reasons
            .add(ProjectInterviewOutcomeReasonCode.invalidEvaluationCitation);
      }
      if (interviewAudit?.hasClaimDefect == true) {
        reasons.add(ProjectInterviewOutcomeReasonCode.invalidClaimQuote);
      }
      if (practice.hasEvidenceDefect) {
        reasons.add(ProjectInterviewOutcomeReasonCode.invalidPracticeEvidence);
      }
      return ProjectInterviewOutcomeStatus.evidenceGap;
    }
    if (!hasParticipation) {
      reasons.add(ProjectInterviewOutcomeReasonCode.noUserParticipation);
      return ProjectInterviewOutcomeStatus.notAssessed;
    }

    final score = assessmentTurn == null
        ? null
        : ProjectInterviewOutcomeScore(
            accuracy: assessmentTurn.accuracyScore,
            projectDetail: assessmentTurn.projectDetailScore,
            engineering: assessmentTurn.engineeringScore,
            clarity: assessmentTurn.clarityScore,
          );
    final interviewReady = interviewAudit?.isSupported == true &&
        score?.meetsReadyThreshold == true &&
        weakDimensions.isEmpty &&
        !hasOpenWork;
    final practiceReady = practice.qualifyingCompletedAt != null &&
        practiceAfterInterview &&
        !hasOpenWork;
    if (interviewReady) {
      reasons.add(ProjectInterviewOutcomeReasonCode.readyFromInterview);
      return ProjectInterviewOutcomeStatus.ready;
    }
    if (practiceReady) {
      reasons.add(ProjectInterviewOutcomeReasonCode.readyFromPractice);
      return ProjectInterviewOutcomeStatus.ready;
    }

    if (interviewAudit?.isSupported != true && assessmentTurn != null) {
      reasons.add(ProjectInterviewOutcomeReasonCode.unsupportedEvaluation);
    }
    if (score != null && !score.meetsReadyThreshold) {
      reasons.add(ProjectInterviewOutcomeReasonCode.scoreBelowReady);
    }
    if (practice.completedAt != null &&
        practice.qualifyingCompletedAt == null) {
      reasons.add(ProjectInterviewOutcomeReasonCode.practiceBelowReady);
    }
    if (weakDimensions.isNotEmpty) {
      reasons.add(ProjectInterviewOutcomeReasonCode.weakDimensions);
    }
    if (openFollowUp != null) {
      reasons.add(ProjectInterviewOutcomeReasonCode.openFollowUp);
    }
    if (openReviewActions > 0 || dueReview) {
      reasons.add(ProjectInterviewOutcomeReasonCode.pendingReview);
    }
    if (reasons.isEmpty) {
      reasons.add(ProjectInterviewOutcomeReasonCode.noUserParticipation);
    }
    return ProjectInterviewOutcomeStatus.needsPractice;
  }

  _EvaluationAudit _auditEvaluation({
    required List<GroundedClaim> claims,
    required List<String> citationIds,
    required GroundingDisposition disposition,
    required Map<String, ProjectInterviewOutcomeEvidence> evidenceByChunkId,
  }) {
    final normalizedCitationIds =
        citationIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    final evidenceIds = evidenceByChunkId.keys.toSet();
    final citationDefect = normalizedCitationIds.isEmpty ||
        normalizedCitationIds.any((id) => !evidenceIds.contains(id));
    final allowedChunks = evidenceByChunkId.values
        .where((item) => normalizedCitationIds.contains(item.chunk.id))
        .map((item) => item.chunk)
        .toList(growable: false);
    final validClaims = <ProjectInterviewOutcomeClaim>[];
    var claimDefect = false;
    for (final claim in claims) {
      final result = _claimGate.evaluate(
        claims: [claim],
        sourceChunks: allowedChunks,
        evidenceSufficient: true,
      );
      if (result.invalidEvidenceCount > 0 ||
          result.groundedClaims.length != 1 ||
          result.uncoveredClaims.isNotEmpty) {
        claimDefect = true;
        continue;
      }
      final sanitized = result.groundedClaims.single;
      final claimEvidence = <ProjectInterviewOutcomeClaimEvidence>[];
      var mappingFailed = false;
      for (final item in sanitized.evidence) {
        final sourceEvidence = evidenceByChunkId[item.citationId];
        if (sourceEvidence == null) {
          mappingFailed = true;
          break;
        }
        claimEvidence.add(
          ProjectInterviewOutcomeClaimEvidence(
            sourceEvidence: sourceEvidence,
            quote: item.quote,
          ),
        );
      }
      if (mappingFailed || claimEvidence.isEmpty) {
        claimDefect = true;
        continue;
      }
      validClaims.add(
        ProjectInterviewOutcomeClaim(
          section: sanitized.section,
          text: sanitized.text,
          evidence: List.unmodifiable(claimEvidence),
        ),
      );
    }
    final supported = disposition == GroundingDisposition.grounded &&
        !citationDefect &&
        !claimDefect &&
        validClaims.isNotEmpty;
    final hasDefect = disposition != GroundingDisposition.legacy &&
        (!supported || claims.isEmpty);
    return _EvaluationAudit(
      claims: validClaims,
      evidence: validClaims
          .expand((claim) => claim.evidence.map((item) => item.sourceEvidence))
          .toSetByChunkId(),
      isSupported: supported,
      hasDefect: hasDefect,
      hasCitationDefect: citationDefect,
      hasClaimDefect: claimDefect || claims.isEmpty,
    );
  }

  _VerifiedPractice _findVerifiedPractice({
    required String pointId,
    required int masteryLevel,
    required List<Question> questions,
    required List<ProgrammingExerciseAttempt> attempts,
    required Map<String, ProjectInterviewOutcomeEvidence> evidenceByChunkId,
  }) {
    DateTime? completedAt;
    DateTime? qualifyingCompletedAt;
    var evidenceDefect = false;
    for (final question in questions.where(
      (question) => question.knowledgePointId == pointId,
    )) {
      if (question.sourceStatus != SourceStatus.verified ||
          question.lastReviewedAt == null) {
        continue;
      }
      final ids = question.citationIds.toSet();
      if (ids.isEmpty || ids.any((id) => !evidenceByChunkId.containsKey(id))) {
        evidenceDefect = true;
        continue;
      }
      if (completedAt == null ||
          question.lastReviewedAt!.isAfter(completedAt)) {
        completedAt = question.lastReviewedAt;
      }
      if (masteryLevel >= 80 &&
          (qualifyingCompletedAt == null ||
              question.lastReviewedAt!.isAfter(qualifyingCompletedAt))) {
        qualifyingCompletedAt = question.lastReviewedAt;
      }
    }
    for (final attempt in attempts) {
      final audit = _auditEvaluation(
        claims: attempt.groundedClaims,
        citationIds: attempt.citationIds,
        disposition: attempt.groundingDisposition,
        evidenceByChunkId: evidenceByChunkId,
      );
      if (!audit.isSupported || !attempt.evidenceSufficient) {
        evidenceDefect = true;
        continue;
      }
      if (completedAt == null || attempt.createdAt.isAfter(completedAt)) {
        completedAt = attempt.createdAt;
      }
      if (attempt.formalMasteryApplied &&
          (qualifyingCompletedAt == null ||
              attempt.createdAt.isAfter(qualifyingCompletedAt))) {
        qualifyingCompletedAt = attempt.createdAt;
      }
    }
    return _VerifiedPractice(
      completedAt: completedAt,
      qualifyingCompletedAt: qualifyingCompletedAt,
      hasEvidenceDefect: evidenceDefect,
    );
  }

  List<InterviewScoreDimension> _weakDimensions(InterviewTurn? turn) {
    if (turn == null) return const [];
    final values = <InterviewScoreDimension, int>{
      InterviewScoreDimension.accuracy: turn.accuracyScore,
      InterviewScoreDimension.projectDetail: turn.projectDetailScore,
      InterviewScoreDimension.engineering: turn.engineeringScore,
      InterviewScoreDimension.clarity: turn.clarityScore,
    };
    final result = <InterviewScoreDimension>{...turn.weakDimensions};
    result.addAll(
      values.entries
          .where((entry) => entry.value < 4)
          .map((entry) => entry.key),
    );
    return InterviewScoreDimension.values
        .where(result.contains)
        .toList(growable: false);
  }

  String? _openFollowUp({
    required LearningAgentMemorySnapshot memory,
    required InterviewTurn? turn,
  }) {
    if (memory.openFollowUps.isNotEmpty) {
      return memory.openFollowUps.first.question;
    }
    if (memory.recordCount == 0) {
      final value = turn?.nextInterviewQuestion.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  DateTime? _nextReviewAt({
    required KnowledgePoint point,
    required List<Question> questions,
    required LearningAgentMemorySnapshot memory,
    required InterviewTurn? turn,
    required List<ProgrammingReviewAction> reviewActions,
    required DateTime now,
  }) {
    final dates = <DateTime>[
      if (memory.nextReviewAt != null) memory.nextReviewAt!,
      if (turn?.reviewDueAt != null) turn!.reviewDueAt!,
      ...reviewActions
          .where((action) =>
              action.knowledgePointId == point.id && !action.isCompleted)
          .map((action) => action.dueAt),
      ...questions
          .where((question) =>
              question.knowledgePointId == point.id &&
              question.nextReviewAt != null)
          .map((question) => question.nextReviewAt!),
    ];
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  bool _hasDueReview({
    required KnowledgePoint point,
    required List<Question> questions,
    required LearningAgentMemorySnapshot memory,
    required List<ProgrammingReviewAction> reviewActions,
    required DateTime now,
  }) {
    if (memory.pendingReviews.any((review) => !review.dueAt.isAfter(now))) {
      return true;
    }
    if (reviewActions.any(
      (action) =>
          action.knowledgePointId == point.id &&
          !action.isCompleted &&
          !action.dueAt.isAfter(now),
    )) {
      return true;
    }
    return questions.any(
      (question) =>
          question.knowledgePointId == point.id &&
          question.nextReviewAt != null &&
          !question.nextReviewAt!.isAfter(now),
    );
  }

  ProjectInterviewOutcomeAnswer? _latestAnswer({
    required InterviewTurn? interview,
    required TutorTurn? tutor,
    required ProgrammingExerciseAttempt? attempt,
  }) {
    final values = <ProjectInterviewOutcomeAnswer>[
      if (interview != null)
        ProjectInterviewOutcomeAnswer(
          surface: 'interview',
          text: interview.userAnswer,
          createdAt: interview.createdAt,
        ),
      if (tutor != null)
        ProjectInterviewOutcomeAnswer(
          surface: 'tutor',
          text: tutor.userAnswer,
          createdAt: tutor.createdAt,
        ),
      if (attempt != null)
        ProjectInterviewOutcomeAnswer(
          surface: 'programming',
          text: attempt.userAnswer,
          createdAt: attempt.createdAt,
        ),
    ];
    if (values.isEmpty) return null;
    values.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return values.first;
  }

  int _compareEvidence(
    ProjectInterviewOutcomeEvidence left,
    ProjectInterviewOutcomeEvidence right,
  ) {
    final trust = _trustRank(left.source.trustLevel)
        .compareTo(_trustRank(right.source.trustLevel));
    if (trust != 0) return trust;
    final relation = _relationRank(left.relation).compareTo(
      _relationRank(right.relation),
    );
    if (relation != 0) return relation;
    final locator = left.hasCodeLocator == right.hasCodeLocator
        ? 0
        : left.hasCodeLocator
            ? -1
            : 1;
    if (locator != 0) return locator;
    final chunkIndex = left.chunk.chunkIndex.compareTo(right.chunk.chunkIndex);
    if (chunkIndex != 0) return chunkIndex;
    return left.chunk.id.compareTo(right.chunk.id);
  }

  int _trustRank(SourceTrustLevel trust) {
    switch (trust) {
      case SourceTrustLevel.sourceCode:
        return 0;
      case SourceTrustLevel.officialDoc:
        return 1;
      case SourceTrustLevel.bookCourse:
        return 2;
      case SourceTrustLevel.article:
        return 3;
      case SourceTrustLevel.userNote:
        return 4;
      case SourceTrustLevel.unknown:
        return 5;
    }
  }

  int _relationRank(KnowledgePointSourceRelation relation) {
    switch (relation) {
      case KnowledgePointSourceRelation.implementation:
        return 0;
      case KnowledgePointSourceRelation.defines:
        return 1;
      case KnowledgePointSourceRelation.explains:
        return 2;
      case KnowledgePointSourceRelation.example:
        return 3;
      case KnowledgePointSourceRelation.counterexample:
        return 4;
    }
  }

  int _compareInterviewTurnsNewestFirst(
      InterviewTurn left, InterviewTurn right) {
    final created = right.createdAt.compareTo(left.createdAt);
    return created == 0 ? left.id.compareTo(right.id) : created;
  }

  int _compareTutorTurnsNewestFirst(TutorTurn left, TutorTurn right) {
    final created = right.createdAt.compareTo(left.createdAt);
    return created == 0 ? left.id.compareTo(right.id) : created;
  }

  int _compareAttemptsNewestFirst(
    ProgrammingExerciseAttempt left,
    ProgrammingExerciseAttempt right,
  ) {
    final created = right.createdAt.compareTo(left.createdAt);
    return created == 0 ? left.id.compareTo(right.id) : created;
  }

  String _excerpt(String content) {
    final trimmed = content.trim();
    if (trimmed.length <= 280) return trimmed;
    final firstLine = trimmed.split('\n').first.trim();
    if (firstLine.isNotEmpty && firstLine.length <= 280) return firstLine;
    return trimmed.substring(0, 280).trim();
  }
}

class _EvaluationAudit {
  final List<ProjectInterviewOutcomeClaim> claims;
  final List<ProjectInterviewOutcomeEvidence> evidence;
  final bool isSupported;
  final bool hasDefect;
  final bool hasCitationDefect;
  final bool hasClaimDefect;

  const _EvaluationAudit({
    required this.claims,
    required this.evidence,
    required this.isSupported,
    required this.hasDefect,
    required this.hasCitationDefect,
    required this.hasClaimDefect,
  });
}

class _VerifiedPractice {
  final DateTime? completedAt;
  final DateTime? qualifyingCompletedAt;
  final bool hasEvidenceDefect;

  const _VerifiedPractice({
    required this.completedAt,
    required this.qualifyingCompletedAt,
    required this.hasEvidenceDefect,
  });
}

extension _EvidenceIterable on Iterable<ProjectInterviewOutcomeEvidence> {
  List<ProjectInterviewOutcomeEvidence> toSetByChunkId() {
    final seen = <String>{};
    return where((item) => seen.add(item.chunk.id)).toList(growable: false);
  }
}

enum ProjectInterviewOutcomeExportFormat {
  markdown('markdown', 'Markdown', 'md'),
  plainText('plain_text', '纯文本', 'txt');

  final String value;
  final String label;
  final String extension;

  const ProjectInterviewOutcomeExportFormat(
    this.value,
    this.label,
    this.extension,
  );
}

class ProjectInterviewOutcomeExport {
  final String fileName;
  final String content;
  final ProjectInterviewOutcomeExportFormat format;
  final int includedCitationCount;

  const ProjectInterviewOutcomeExport({
    required this.fileName,
    required this.content,
    required this.format,
    required this.includedCitationCount,
  });
}

class ProjectInterviewOutcomeExporter {
  final DateTime Function() _clock;

  ProjectInterviewOutcomeExporter({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  ProjectInterviewOutcomeExport build(
    ProjectInterviewOutcome outcome,
    ProjectInterviewOutcomeExportFormat format,
  ) {
    final generatedAt = _clock().toUtc();
    final evidence = _collectEvidence(outcome);
    final markers = <String, String>{};
    for (var index = 0; index < evidence.length; index += 1) {
      markers[evidence[index].chunk.id] = '[S${index + 1}]';
    }
    final content = format == ProjectInterviewOutcomeExportFormat.markdown
        ? _markdown(outcome, generatedAt, markers, evidence)
        : _plainText(outcome, generatedAt, markers, evidence);
    final timestamp = _fileTimestamp(generatedAt);
    return ProjectInterviewOutcomeExport(
      fileName:
          'anchor-learning-project-interview-outcome-$timestamp.${format.extension}',
      content: content,
      format: format,
      includedCitationCount: evidence.length,
    );
  }

  List<ProjectInterviewOutcomeEvidence> _collectEvidence(
    ProjectInterviewOutcome outcome,
  ) {
    final seen = <String>{};
    final result = <ProjectInterviewOutcomeEvidence>[];
    for (final unit in outcome.units) {
      final candidates = <ProjectInterviewOutcomeEvidence>[
        if (unit.strongestEvidence != null) unit.strongestEvidence!,
        ...unit.evaluationEvidence,
        ...unit.referenceOutline.expand(
          (claim) => claim.evidence.map((item) => item.sourceEvidence),
        ),
      ];
      for (final item in candidates) {
        if (seen.add(item.chunk.id)) result.add(item);
      }
    }
    return result;
  }

  String _markdown(
    ProjectInterviewOutcome outcome,
    DateTime generatedAt,
    Map<String, String> markers,
    List<ProjectInterviewOutcomeEvidence> evidence,
  ) {
    final lines = <String>[
      '# 项目面试成果',
      '',
      '- 生成时间: ${generatedAt.toIso8601String()}',
      '- 项目目标: ${_singleLine(outcome.goal)}',
      '- 面试范围: ${outcome.scope.map((kind) => kind.label).join('、')}',
      if (outcome.projectTitles.isNotEmpty)
        '- 来源项目: ${outcome.projectTitles.map(_singleLine).join('、')}',
      '- 状态统计: 可面试 ${outcome.readyCount} · 需要练习 ${outcome.needsPracticeCount} · 证据缺口 ${outcome.evidenceGapCount} · 尚未评估 ${outcome.notAssessedCount}',
      '',
    ];
    for (var index = 0; index < outcome.units.length; index += 1) {
      final unit = outcome.units[index];
      lines.add('## ${index + 1}. ${_singleLine(unit.point.title)}');
      lines.add('');
      lines.add('- 类型: ${unit.point.kind.label}');
      lines.add('- 状态: ${unit.status.label} (${unit.status.value})');
      lines
          .add('- 原因: ${unit.reasons.map((reason) => reason.label).join('、')}');
      if (unit.strongestEvidence != null) {
        final marker = markers[unit.strongestEvidence!.chunk.id]!;
        lines.add(
          '- 已核验摘要: ${_singleLine(unit.point.summary)} $marker',
        );
        lines.add(
          '- 最强证据: "${_singleLine(unit.strongestEvidence!.excerpt)}" $marker',
        );
      }
      if (unit.interviewScore != null) {
        final scoreMarkers = _markersFor(
          unit.evaluationEvidence,
          markers,
        );
        lines.add(
          '- 最近面试评分: ${unit.interviewScore!.accuracy}/${unit.interviewScore!.projectDetail}/${unit.interviewScore!.engineering}/${unit.interviewScore!.clarity}（总分 ${unit.interviewScore!.total}/20）${scoreMarkers.isEmpty ? '' : ' $scoreMarkers'}',
        );
      }
      if (unit.latestAnswer != null) {
        lines.add('- 最近回答（用户内容，不作为项目事实依据，${unit.latestAnswer!.surface}）:');
        lines.addAll(_blockquote(unit.latestAnswer!.text));
      }
      lines.add('');
      lines.add('### 来源支持的参考提纲');
      if (unit.referenceOutline.isEmpty) {
        lines.add('- 当前没有通过逐字引用校验的正式主张。');
      } else {
        for (final claim in unit.referenceOutline) {
          final claimMarkers = _markersFor(
            claim.evidence.map((item) => item.sourceEvidence),
            markers,
          );
          lines.add(
            '- ${_singleLine(claim.text)}${claimMarkers.isEmpty ? '' : ' $claimMarkers'}',
          );
        }
      }
      if (unit.openFollowUp != null) {
        lines.add('- 未处理追问: ${_singleLine(unit.openFollowUp!)}');
      }
      if (unit.nextReviewAt != null) {
        lines.add('- 下一复习: ${unit.nextReviewAt!.toIso8601String()}');
      }
      lines.add('');
    }
    lines.add('## 来源索引');
    lines.add('');
    if (evidence.isEmpty) {
      lines.add('暂无可定位来源。');
    } else {
      for (final item in evidence) {
        lines.add(
          '${markers[item.chunk.id]} ${_singleLine(item.source.title)} · ${_singleLine(item.locator)}',
        );
      }
    }
    return '${lines.join('\n').trim()}\n';
  }

  String _plainText(
    ProjectInterviewOutcome outcome,
    DateTime generatedAt,
    Map<String, String> markers,
    List<ProjectInterviewOutcomeEvidence> evidence,
  ) {
    final lines = <String>[
      '项目面试成果',
      '生成时间: ${generatedAt.toIso8601String()}',
      '项目目标: ${_singleLine(outcome.goal)}',
      '面试范围: ${outcome.scope.map((kind) => kind.label).join('、')}',
      if (outcome.projectTitles.isNotEmpty)
        '来源项目: ${outcome.projectTitles.map(_singleLine).join('、')}',
      '状态统计: 可面试 ${outcome.readyCount} · 需要练习 ${outcome.needsPracticeCount} · 证据缺口 ${outcome.evidenceGapCount} · 尚未评估 ${outcome.notAssessedCount}',
      '',
    ];
    for (var index = 0; index < outcome.units.length; index += 1) {
      final unit = outcome.units[index];
      lines.add('${index + 1}. ${_singleLine(unit.point.title)}');
      lines.add('类型: ${unit.point.kind.label}');
      lines.add('状态: ${unit.status.label} (${unit.status.value})');
      lines.add('原因: ${unit.reasons.map((reason) => reason.label).join('、')}');
      if (unit.strongestEvidence != null) {
        final marker = markers[unit.strongestEvidence!.chunk.id]!;
        lines.add('已核验摘要: ${_singleLine(unit.point.summary)} $marker');
        lines.add(
          '最强证据: "${_singleLine(unit.strongestEvidence!.excerpt)}" $marker',
        );
      }
      if (unit.interviewScore != null) {
        final scoreMarkers = _markersFor(unit.evaluationEvidence, markers);
        lines.add(
          '最近面试评分: ${unit.interviewScore!.accuracy}/${unit.interviewScore!.projectDetail}/${unit.interviewScore!.engineering}/${unit.interviewScore!.clarity}（总分 ${unit.interviewScore!.total}/20）${scoreMarkers.isEmpty ? '' : ' $scoreMarkers'}',
        );
      }
      if (unit.latestAnswer != null) {
        lines.add('最近回答（用户内容，不作为项目事实依据，${unit.latestAnswer!.surface}）:');
        lines.addAll(unit.latestAnswer!.text
            .trim()
            .split('\n')
            .map((line) => '  $line'));
      }
      lines.add('参考提纲:');
      if (unit.referenceOutline.isEmpty) {
        lines.add('  当前没有通过逐字引用校验的正式主张。');
      } else {
        for (final claim in unit.referenceOutline) {
          final claimMarkers = _markersFor(
            claim.evidence.map((item) => item.sourceEvidence),
            markers,
          );
          lines.add(
            '  - ${_singleLine(claim.text)}${claimMarkers.isEmpty ? '' : ' $claimMarkers'}',
          );
        }
      }
      if (unit.openFollowUp != null) {
        lines.add('未处理追问: ${_singleLine(unit.openFollowUp!)}');
      }
      if (unit.nextReviewAt != null) {
        lines.add('下一复习: ${unit.nextReviewAt!.toIso8601String()}');
      }
      lines.add('');
    }
    lines.add('来源索引');
    if (evidence.isEmpty) {
      lines.add('暂无可定位来源。');
    } else {
      for (final item in evidence) {
        lines.add(
          '${markers[item.chunk.id]} ${_singleLine(item.source.title)} · ${_singleLine(item.locator)}',
        );
      }
    }
    return '${lines.join('\n').trim()}\n';
  }

  List<String> _blockquote(String value) {
    return value.trim().split('\n').map((line) => '> $line').toList();
  }

  String _markersFor(
    Iterable<ProjectInterviewOutcomeEvidence> evidence,
    Map<String, String> markers,
  ) {
    final values = <String>[];
    for (final item in evidence) {
      final marker = markers[item.chunk.id];
      if (marker != null && !values.contains(marker)) values.add(marker);
    }
    return values.join(' ');
  }

  String _singleLine(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _fileTimestamp(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year}${_two(utc.month)}${_two(utc.day)}-${_two(utc.hour)}${_two(utc.minute)}${_two(utc.second)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
