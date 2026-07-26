import '../../data/models/grounded_learning_context.dart';
import '../../data/models/question.dart';
import '../../data/models/source_chunk.dart';
import 'learning_agent_practice_target.dart';
import 'learning_agent_planner_service.dart';
import 'learning_agent_state.dart';

enum LearningAgentPolicySeverity {
  info('info', '提示'),
  warning('warning', '警告'),
  blocker('blocker', '阻断');

  final String value;
  final String label;
  const LearningAgentPolicySeverity(this.value, this.label);
}

enum LearningAgentPolicyAction {
  continueFlow('continue_flow', '继续执行'),
  importSources('import_sources', '补充来源'),
  verifyQuestions('verify_questions', '核验题目'),
  attachEvidence('attach_evidence', '补齐证据');

  final String value;
  final String label;
  const LearningAgentPolicyAction(this.value, this.label);
}

class LearningAgentPolicyIssue {
  final String code;
  final String title;
  final String message;
  final LearningAgentPolicySeverity severity;
  final LearningAgentPolicyAction suggestedAction;

  const LearningAgentPolicyIssue({
    required this.code,
    required this.title,
    required this.message,
    required this.severity,
    required this.suggestedAction,
  });

  bool get isBlocker => severity == LearningAgentPolicySeverity.blocker;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'message': message,
      'severity': severity.value,
      'suggested_action': suggestedAction.value,
    };
  }
}

class LearningAgentPolicyResult {
  final List<LearningAgentPolicyIssue> issues;

  const LearningAgentPolicyResult({this.issues = const []});

  factory LearningAgentPolicyResult.allow() {
    return const LearningAgentPolicyResult();
  }

  bool get isAllowed => blockingIssues.isEmpty;

  List<LearningAgentPolicyIssue> get blockingIssues {
    return issues.where((issue) => issue.isBlocker).toList();
  }

  List<String> get blockingMessages {
    return blockingIssues
        .map((issue) => '${issue.title}: ${issue.message}')
        .toList();
  }

  List<String> get warningMessages {
    return issues
        .where((issue) => issue.severity == LearningAgentPolicySeverity.warning)
        .map((issue) => issue.message)
        .toList();
  }

  LearningAgentPolicyAction get nextAction {
    if (blockingIssues.isEmpty) return LearningAgentPolicyAction.continueFlow;
    return blockingIssues.first.suggestedAction;
  }

  LearningAgentPolicyResult merge(LearningAgentPolicyResult other) {
    if (issues.isEmpty) return other;
    if (other.issues.isEmpty) return this;
    return LearningAgentPolicyResult(issues: [...issues, ...other.issues]);
  }
}

class LearningAgentPolicy {
  const LearningAgentPolicy();

  LearningAgentPolicyResult checkStep({
    required LearningAgentStepType stepType,
    String? targetId,
    String? targetLabel,
    List<Question> questions = const [],
    List<SourceChunk> evidenceChunks = const [],
    LearningAgentPracticeTarget? plannedPracticeTarget,
    LearningAgentPracticeTarget? actualPracticeTarget,
  }) {
    switch (stepType) {
      case LearningAgentStepType.importSources:
      case LearningAgentStepType.verifyQuestions:
      case LearningAgentStepType.handleFollowUps:
        return LearningAgentPolicyResult.allow();
      case LearningAgentStepType.tutor:
      case LearningAgentStepType.interview:
        return checkEvidenceBoundAction(
          stepType: stepType,
          targetId: targetId,
          targetLabel: targetLabel,
          evidenceChunks: evidenceChunks,
        );
      case LearningAgentStepType.practice:
      case LearningAgentStepType.review:
        if (plannedPracticeTarget != null || actualPracticeTarget != null) {
          return checkFormalPracticeTarget(
            plannedTarget: plannedPracticeTarget,
            actualTarget: actualPracticeTarget,
            contextLabel: targetLabel,
          );
        }
        return checkFormalPracticeQuestions(
          questions,
          contextLabel: targetLabel,
        );
    }
  }

  LearningAgentPolicyResult checkFormalPracticeTarget({
    required LearningAgentPracticeTarget? plannedTarget,
    required LearningAgentPracticeTarget? actualTarget,
    String? contextLabel,
  }) {
    final issues = <LearningAgentPolicyIssue>[];
    final label = _targetLabel(contextLabel);

    if (actualTarget == null) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'formal_practice_target_unavailable',
          title: '练习目标不可用',
          message: '$label对应的练习已被删除或当前无法读取。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.verifyQuestions,
        ),
      );
      return LearningAgentPolicyResult(issues: issues);
    }

    if (plannedTarget != null &&
        (plannedTarget.routingId != actualTarget.routingId ||
            plannedTarget.knowledgePointId != actualTarget.knowledgePointId)) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'formal_practice_target_changed',
          title: '练习目标已变化',
          message: '$label的类型、ID 或知识点绑定与计划快照不一致。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.verifyQuestions,
        ),
      );
    }

    if (actualTarget.sourceStatus != SourceStatus.verified) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'formal_practice_target_unverified',
          title: '正式练习只能使用已核验内容',
          message: '$label当前是${actualTarget.sourceStatus.label}，不能进入正式练习。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.verifyQuestions,
        ),
      );
    }

    if (actualTarget.citationIds.isEmpty) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'formal_practice_target_missing_citations',
          title: '正式练习缺少引用',
          message: '$label没有可追溯的来源引用。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.attachEvidence,
        ),
      );
    }

    if (actualTarget.knowledgePointId.isEmpty) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'formal_practice_target_missing_knowledge_point',
          title: '练习缺少知识点绑定',
          message: '$label没有绑定知识点，不能由当前学习范围执行。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.attachEvidence,
        ),
      );
    }

    return LearningAgentPolicyResult(issues: issues);
  }

  LearningAgentPolicyResult checkFormalPracticeQuestions(
    List<Question> questions, {
    String? contextLabel,
  }) {
    final issues = <LearningAgentPolicyIssue>[];
    final label = _targetLabel(contextLabel);

    if (questions.isEmpty) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'formal_practice_empty',
          title: '缺少已核验题目',
          message: '$label没有可进入正式练习的已核验题目。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.verifyQuestions,
        ),
      );
    }

    final nonVerified = questions
        .where((question) => question.sourceStatus != SourceStatus.verified)
        .toList();
    if (nonVerified.isNotEmpty) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'formal_practice_unverified_questions',
          title: '正式练习只能使用已核验题',
          message: '$label包含 ${nonVerified.length} 道未核验题目，不能进入正式练习。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.verifyQuestions,
        ),
      );
    }

    final missingCitations =
        questions.where((question) => question.citationIds.isEmpty).toList();
    if (missingCitations.isNotEmpty) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'formal_practice_missing_citations',
          title: '正式练习缺少引用',
          message: '$label包含 ${missingCitations.length} 道缺少引用依据的题目。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.attachEvidence,
        ),
      );
    }

    return LearningAgentPolicyResult(issues: issues);
  }

  LearningAgentPolicyResult checkEvidenceBoundAction({
    required LearningAgentStepType stepType,
    required List<SourceChunk> evidenceChunks,
    String? targetId,
    String? targetLabel,
  }) {
    final issues = <LearningAgentPolicyIssue>[];
    final label = _targetLabel(targetLabel);

    if (targetId == null || targetId.trim().isEmpty) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'evidence_action_missing_target',
          title: '缺少学习目标',
          message: '${_stepLabel(stepType)}需要先绑定一个知识点或学习目标。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.importSources,
        ),
      );
    }

    if (evidenceChunks.isEmpty) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'evidence_action_missing_chunks',
          title: '缺少来源证据',
          message: '$label没有真实来源片段，不能启动${_stepLabel(stepType)}。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.importSources,
        ),
      );
    }

    return LearningAgentPolicyResult(issues: issues);
  }

  LearningAgentPolicyResult checkGroundedContext(
    GroundedLearningContext context,
  ) {
    if (context.isExecutable) return LearningAgentPolicyResult.allow();
    final rejectionCodes = context.rejections
        .map((rejection) => rejection.code.value)
        .toSet()
        .join('、');
    return LearningAgentPolicyResult(
      issues: [
        LearningAgentPolicyIssue(
          code: 'grounded_context_not_executable',
          title: 'Grounded context 不可执行',
          message: rejectionCodes.isEmpty
              ? '当前目标没有合法来源片段。'
              : '当前目标的来源 context 被拒绝：$rejectionCodes。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.attachEvidence,
        ),
      ],
    );
  }

  LearningAgentPolicyResult checkQuestionEvidence({
    required Question question,
    List<SourceChunk> citationChunks = const [],
    bool requireVerified = false,
    bool requireCitationChunks = false,
  }) {
    final issues = <LearningAgentPolicyIssue>[];
    final citationIds = question.citationIds.toSet();
    final chunkIds = citationChunks.map((chunk) => chunk.id).toSet();

    if (requireVerified && question.sourceStatus != SourceStatus.verified) {
      issues.add(
        LearningAgentPolicyIssue(
          code: 'question_not_verified',
          title: '题目尚未核验',
          message: '这道题当前是${question.sourceStatus.label}，不能进入正式学习。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.verifyQuestions,
        ),
      );
    }

    if (question.sourceStatus == SourceStatus.noSource) {
      issues.add(
        const LearningAgentPolicyIssue(
          code: 'question_has_no_source',
          title: '题目没有来源',
          message: '无来源题目只能作为草稿，不能进入正式学习或来源约束回答。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.importSources,
        ),
      );
      return LearningAgentPolicyResult(issues: issues);
    }

    if (citationIds.isEmpty) {
      issues.add(
        const LearningAgentPolicyIssue(
          code: 'question_missing_citation_ids',
          title: '题目缺少引用',
          message: '题目没有保存引用 ID，需要补齐来源或重新核验。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.attachEvidence,
        ),
      );
      return LearningAgentPolicyResult(issues: issues);
    }

    if (requireCitationChunks && citationChunks.isEmpty) {
      issues.add(
        const LearningAgentPolicyIssue(
          code: 'question_unreadable_citation_chunks',
          title: '引用片段不可读取',
          message: '题目保存了引用 ID，但当前没有读取到对应来源片段。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.attachEvidence,
        ),
      );
    } else if (citationChunks.isNotEmpty) {
      final missingIds = citationIds.difference(chunkIds);
      if (missingIds.isNotEmpty) {
        issues.add(
          LearningAgentPolicyIssue(
            code: 'question_missing_citation_chunks',
            title: '引用片段缺失',
            message: '题目有 ${missingIds.length} 条引用片段无法读取，需要修复来源。',
            severity: LearningAgentPolicySeverity.blocker,
            suggestedAction: LearningAgentPolicyAction.attachEvidence,
          ),
        );
      }
    }

    if (question.sourceStatus == SourceStatus.pending) {
      issues.add(
        const LearningAgentPolicyIssue(
          code: 'question_pending_verification',
          title: '题目仍待核验',
          message: '题目已有引用，但还需要人工确认后才能进入正式学习。',
          severity: LearningAgentPolicySeverity.warning,
          suggestedAction: LearningAgentPolicyAction.verifyQuestions,
        ),
      );
    }

    return LearningAgentPolicyResult(issues: issues);
  }

  LearningAgentPolicyResult checkStateEvidence(
    LearningAgentState state, {
    String? targetLabel,
  }) {
    if (state.phase == LearningAgentPhase.plan || state.isTerminal) {
      return LearningAgentPolicyResult.allow();
    }

    if (state.focusPointId == null || state.evidenceChunkIds.isNotEmpty) {
      return LearningAgentPolicyResult.allow();
    }

    return LearningAgentPolicyResult(
      issues: [
        LearningAgentPolicyIssue(
          code: 'state_missing_evidence',
          title: '运行状态缺少证据',
          message:
              '${_targetLabel(targetLabel)}进入${state.phase.label}阶段前需要绑定来源片段。',
          severity: LearningAgentPolicySeverity.blocker,
          suggestedAction: LearningAgentPolicyAction.attachEvidence,
        ),
      ],
    );
  }

  String _stepLabel(LearningAgentStepType stepType) {
    switch (stepType) {
      case LearningAgentStepType.importSources:
        return '导入来源';
      case LearningAgentStepType.verifyQuestions:
        return '题目核验';
      case LearningAgentStepType.handleFollowUps:
        return '历史追问';
      case LearningAgentStepType.tutor:
        return '导师模式';
      case LearningAgentStepType.interview:
        return '面试模式';
      case LearningAgentStepType.practice:
        return '正式练习';
      case LearningAgentStepType.review:
        return '复习模式';
    }
  }

  String _targetLabel(String? targetLabel) {
    final value = targetLabel?.trim();
    if (value == null || value.isEmpty) return '当前目标';
    return '“$value”';
  }
}
