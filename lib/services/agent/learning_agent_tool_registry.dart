import 'learning_agent_next_action.dart';
import 'learning_agent_planner_service.dart';

const _listSeparator = '\x00';

enum LearningAgentToolId {
  importSources(LearningAgentToolRouteIds.importSources),
  verifyPendingQuestions(LearningAgentToolRouteIds.verifyPendingQuestions),
  handleFollowUps(LearningAgentToolRouteIds.handleFollowUps),
  searchKnowledgeBase(LearningAgentToolRouteIds.searchKnowledgeBase),
  openTutorSession(LearningAgentToolRouteIds.openTutorSession),
  openInterviewSession(LearningAgentToolRouteIds.openInterviewSession),
  startVerifiedPractice(LearningAgentToolRouteIds.startVerifiedPractice),
  startReviewSession(LearningAgentToolRouteIds.startReviewSession),
  saveAgentReflection(LearningAgentToolRouteIds.saveAgentReflection);

  final String value;
  const LearningAgentToolId(this.value);

  static LearningAgentToolId fromString(String value) {
    return LearningAgentToolId.values.firstWhere(
      (id) => id.value == value,
      orElse: () => LearningAgentToolId.searchKnowledgeBase,
    );
  }
}

enum LearningAgentToolCapability {
  sourceImport('source_import', '来源导入'),
  questionVerification('question_verification', '题目核验'),
  sessionMemory('session_memory', '会话记忆'),
  knowledgeSearch('knowledge_search', '知识检索'),
  tutorSession('tutor_session', '导师会话'),
  interviewSession('interview_session', '面试会话'),
  verifiedPractice('verified_practice', '已核验练习'),
  reviewSession('review_session', '复习会话'),
  reflectionPersistence('reflection_persistence', '复盘保存'),
  navigation('navigation', '页面导航');

  final String value;
  final String label;
  const LearningAgentToolCapability(this.value, this.label);
}

enum LearningAgentToolEvidenceRequirement {
  none('none', '不需要来源证据'),
  optionalContext('optional_context', '可使用上下文但不强制'),
  sessionMemory('session_memory', '需要历史会话上下文'),
  targetEvidenceChunks('target_evidence_chunks', '需要目标来源片段'),
  verifiedQuestionCitations(
    'verified_question_citations',
    '需要已核验练习引用',
  );

  final String value;
  final String label;
  const LearningAgentToolEvidenceRequirement(this.value, this.label);
}

class LearningAgentToolDefinition {
  final LearningAgentToolId id;
  final String title;
  final String description;
  final LearningAgentStepType? stepType;
  final List<LearningAgentToolCapability> requiredCapabilities;
  final LearningAgentToolEvidenceRequirement evidenceRequirement;
  final String failureDiagnosticTitle;
  final Set<LearningAgentGoal> supportedGoals;

  const LearningAgentToolDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredCapabilities,
    required this.evidenceRequirement,
    required this.failureDiagnosticTitle,
    this.stepType,
    this.supportedGoals = const {},
  });

  String get toolId => id.value;
  bool get isPlanStepTool => stepType != null;

  bool supportsGoal(LearningAgentGoal goal) {
    return supportedGoals.isEmpty || supportedGoals.contains(goal);
  }

  bool supportsStep(LearningAgentStepType stepType) {
    return this.stepType == stepType;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.value,
      'title': title,
      'description': description,
      'step_type': stepType?.name,
      'required_capabilities': _joinValues(
        requiredCapabilities.map((capability) => capability.value),
      ),
      'evidence_requirement': evidenceRequirement.value,
      'failure_diagnostic_title': failureDiagnosticTitle,
      'supported_goals': _joinValues(
        supportedGoals.map((goal) => goal.value),
      ),
    };
  }
}

class LearningAgentToolRegistry {
  final List<LearningAgentToolDefinition> tools;

  const LearningAgentToolRegistry({
    this.tools = defaultLearningAgentTools,
  });

  List<LearningAgentToolDefinition> all() {
    return List.unmodifiable(tools);
  }

  LearningAgentToolDefinition? toolForId(LearningAgentToolId id) {
    for (final tool in tools) {
      if (tool.id == id) return tool;
    }
    return null;
  }

  LearningAgentToolDefinition? toolForIdValue(String id) {
    for (final tool in tools) {
      if (tool.id.value == id) return tool;
    }
    return null;
  }

  LearningAgentToolDefinition? toolForStep(LearningAgentStepType stepType) {
    for (final tool in tools) {
      if (tool.supportsStep(stepType)) return tool;
    }
    return null;
  }

  List<LearningAgentToolDefinition> toolsForGoal(LearningAgentGoal goal) {
    return tools
        .where((tool) => tool.supportsGoal(goal))
        .toList(growable: false);
  }

  List<LearningAgentToolDefinition> toolsForPlan(LearningAgentPlan plan) {
    final planTools = <LearningAgentToolDefinition>[];
    for (final step in plan.steps) {
      final tool = toolForStep(step.type);
      if (tool != null && tool.supportsGoal(plan.goal)) {
        planTools.add(tool);
      }
    }
    return List.unmodifiable(planTools);
  }

  List<LearningAgentToolDefinition> toolsRequiringEvidence(
    LearningAgentToolEvidenceRequirement evidenceRequirement,
  ) {
    return tools
        .where((tool) => tool.evidenceRequirement == evidenceRequirement)
        .toList(growable: false);
  }
}

const defaultLearningAgentTools = <LearningAgentToolDefinition>[
  LearningAgentToolDefinition(
    id: LearningAgentToolId.importSources,
    stepType: LearningAgentStepType.importSources,
    title: '导入来源',
    description: '打开来源导入流程，把项目、官方文档或课程资料转成可引用片段。',
    requiredCapabilities: [
      LearningAgentToolCapability.sourceImport,
      LearningAgentToolCapability.navigation,
    ],
    evidenceRequirement: LearningAgentToolEvidenceRequirement.none,
    failureDiagnosticTitle: 'Agent 来源导入启动失败',
  ),
  LearningAgentToolDefinition(
    id: LearningAgentToolId.verifyPendingQuestions,
    stepType: LearningAgentStepType.verifyQuestions,
    title: '核验待确认内容',
    description: '打开指定普通题、编程练习或待核验列表，由用户确认哪些内容可以进入正式学习。',
    requiredCapabilities: [
      LearningAgentToolCapability.questionVerification,
      LearningAgentToolCapability.navigation,
    ],
    evidenceRequirement: LearningAgentToolEvidenceRequirement.optionalContext,
    failureDiagnosticTitle: 'Agent 内容核验启动失败',
  ),
  LearningAgentToolDefinition(
    id: LearningAgentToolId.handleFollowUps,
    stepType: LearningAgentStepType.handleFollowUps,
    title: '处理历史追问',
    description: '打开当前目标的未处理追问历史，延续上一轮学习留下的问题。',
    requiredCapabilities: [
      LearningAgentToolCapability.sessionMemory,
      LearningAgentToolCapability.navigation,
    ],
    evidenceRequirement: LearningAgentToolEvidenceRequirement.sessionMemory,
    failureDiagnosticTitle: 'Agent 历史追问启动失败',
  ),
  LearningAgentToolDefinition(
    id: LearningAgentToolId.searchKnowledgeBase,
    title: '检索知识库',
    description: '在本地知识库中检索来源、片段、知识点和题目，返回可引用上下文。',
    requiredCapabilities: [
      LearningAgentToolCapability.knowledgeSearch,
    ],
    evidenceRequirement: LearningAgentToolEvidenceRequirement.optionalContext,
    failureDiagnosticTitle: 'Agent 知识库检索失败',
  ),
  LearningAgentToolDefinition(
    id: LearningAgentToolId.openTutorSession,
    stepType: LearningAgentStepType.tutor,
    title: '启动导师模式',
    description: '围绕带来源知识点生成分层解释、追问和自测问题。',
    requiredCapabilities: [
      LearningAgentToolCapability.tutorSession,
      LearningAgentToolCapability.navigation,
    ],
    evidenceRequirement:
        LearningAgentToolEvidenceRequirement.targetEvidenceChunks,
    failureDiagnosticTitle: 'Agent 导师模式启动失败',
  ),
  LearningAgentToolDefinition(
    id: LearningAgentToolId.openInterviewSession,
    stepType: LearningAgentStepType.interview,
    title: '启动面试模式',
    description: '围绕来源约束知识点追问项目细节、实现边界和工程取舍。',
    requiredCapabilities: [
      LearningAgentToolCapability.interviewSession,
      LearningAgentToolCapability.navigation,
    ],
    evidenceRequirement:
        LearningAgentToolEvidenceRequirement.targetEvidenceChunks,
    failureDiagnosticTitle: 'Agent 面试模式启动失败',
    supportedGoals: {
      LearningAgentGoal.aiInterviewPrep,
      LearningAgentGoal.projectWalkthrough,
    },
  ),
  LearningAgentToolDefinition(
    id: LearningAgentToolId.startVerifiedPractice,
    stepType: LearningAgentStepType.practice,
    title: '完成已核验练习',
    description: '启动 planner 选中的已核验普通题或编程练习。',
    requiredCapabilities: [
      LearningAgentToolCapability.verifiedPractice,
      LearningAgentToolCapability.navigation,
    ],
    evidenceRequirement:
        LearningAgentToolEvidenceRequirement.verifiedQuestionCitations,
    failureDiagnosticTitle: 'Agent 已核验练习启动失败',
  ),
  LearningAgentToolDefinition(
    id: LearningAgentToolId.startReviewSession,
    stepType: LearningAgentStepType.review,
    title: '启动复习模式',
    description: '启动由已核验普通题、编程练习和复习调度驱动的薄弱点复习。',
    requiredCapabilities: [
      LearningAgentToolCapability.reviewSession,
      LearningAgentToolCapability.navigation,
    ],
    evidenceRequirement:
        LearningAgentToolEvidenceRequirement.verifiedQuestionCitations,
    failureDiagnosticTitle: 'Agent 复习模式启动失败',
  ),
  LearningAgentToolDefinition(
    id: LearningAgentToolId.saveAgentReflection,
    title: '保存 Agent 复盘',
    description: '保存成功标准、复盘笔记和下一轮追问到本地学习记录。',
    requiredCapabilities: [
      LearningAgentToolCapability.reflectionPersistence,
    ],
    evidenceRequirement: LearningAgentToolEvidenceRequirement.optionalContext,
    failureDiagnosticTitle: 'Agent Session 复盘保存失败',
  ),
];

String _joinValues(Iterable<String> values) {
  return values.where((value) => value.isNotEmpty).join(_listSeparator);
}
