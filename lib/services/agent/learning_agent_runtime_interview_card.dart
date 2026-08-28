import 'learning_agent_planner_service.dart';
import 'learning_agent_state.dart';
import 'learning_agent_tool_registry.dart';
import 'learning_agent_trace.dart';

class LearningAgentRuntimeInterviewCard {
  final String title;
  final String summary;
  final String answerScript;
  final List<LearningAgentRuntimePracticeStep> practiceSteps;
  final List<LearningAgentRuntimeAnswerRubricItem> answerRubric;
  final List<String> badges;
  final List<LearningAgentRuntimeGlossaryTerm> glossaryTerms;
  final List<String> talkingPoints;
  final List<LearningAgentRuntimeAnswerFrame> answerFrames;
  final List<LearningAgentRuntimeChallengeResponse> challengeResponses;
  final List<LearningAgentRuntimeExperienceStory> experienceStories;
  final List<LearningAgentRuntimeMockInterviewRound> mockInterviewRounds;
  final List<LearningAgentRuntimeMockInterviewScoreRule>
      mockInterviewScoreRules;
  final List<LearningAgentRuntimeMockInterviewRepairDrill>
      mockInterviewRepairDrills;
  final List<LearningAgentFrameworkMapping> frameworkMappings;
  final List<LearningAgentRuntimeFrameworkSelection> frameworkSelections;
  final List<LearningAgentRuntimeDecisionRecord> decisionRecords;
  final List<LearningAgentRuntimeBoundaryNote> boundaryNotes;
  final List<LearningAgentRuntimeMaturityLevel> maturityLevels;
  final List<LearningAgentRuntimePitfall> pitfalls;
  final List<LearningAgentRuntimeEvolutionStep> evolutionSteps;
  final List<LearningAgentRuntimeMigrationTrigger> migrationTriggers;
  final List<LearningAgentRuntimeCodeWalkthroughStep> codeWalkthroughSteps;
  final List<LearningAgentRuntimeDebugScenario> debugScenarios;
  final List<LearningAgentRuntimeDemoStep> demoSteps;
  final List<LearningAgentRuntimeSourceGroundingCheck> sourceGroundingChecks;
  final List<LearningAgentRuntimeEvidenceAnchor> evidenceAnchors;
  final List<LearningAgentRuntimeSourceReference> frameworkSourceReferences;
  final List<LearningAgentInterviewPrompt> prompts;
  final List<String> sourceNotes;

  const LearningAgentRuntimeInterviewCard({
    required this.title,
    required this.summary,
    required this.answerScript,
    required this.practiceSteps,
    required this.answerRubric,
    required this.badges,
    required this.glossaryTerms,
    required this.talkingPoints,
    required this.answerFrames,
    required this.challengeResponses,
    required this.experienceStories,
    required this.mockInterviewRounds,
    required this.mockInterviewScoreRules,
    required this.mockInterviewRepairDrills,
    required this.frameworkMappings,
    required this.frameworkSelections,
    required this.decisionRecords,
    required this.boundaryNotes,
    required this.maturityLevels,
    required this.pitfalls,
    required this.evolutionSteps,
    required this.migrationTriggers,
    required this.codeWalkthroughSteps,
    required this.debugScenarios,
    required this.demoSteps,
    required this.sourceGroundingChecks,
    required this.evidenceAnchors,
    required this.frameworkSourceReferences,
    required this.prompts,
    required this.sourceNotes,
  });
}

class LearningAgentRuntimePitfall {
  final String riskyClaim;
  final String saferClaim;
  final String reason;

  const LearningAgentRuntimePitfall({
    required this.riskyClaim,
    required this.saferClaim,
    required this.reason,
  });
}

class LearningAgentRuntimeEvolutionStep {
  final String milestone;
  final String currentFoundation;
  final String nextUpgrade;
  final String interviewClaim;

  const LearningAgentRuntimeEvolutionStep({
    required this.milestone,
    required this.currentFoundation,
    required this.nextUpgrade,
    required this.interviewClaim,
  });
}

class LearningAgentRuntimeDecisionRecord {
  final String decision;
  final String rationale;
  final String tradeoff;
  final String interviewClaim;

  const LearningAgentRuntimeDecisionRecord({
    required this.decision,
    required this.rationale,
    required this.tradeoff,
    required this.interviewClaim,
  });
}

class LearningAgentRuntimeMigrationTrigger {
  final String trigger;
  final String currentSignal;
  final String upgradeAction;
  final String interviewClaim;

  const LearningAgentRuntimeMigrationTrigger({
    required this.trigger,
    required this.currentSignal,
    required this.upgradeAction,
    required this.interviewClaim,
  });
}

class LearningAgentRuntimeMaturityLevel {
  final String level;
  final String implementedSignal;
  final String missingCapability;
  final String nextMilestone;
  final String interviewClaim;

  const LearningAgentRuntimeMaturityLevel({
    required this.level,
    required this.implementedSignal,
    required this.missingCapability,
    required this.nextMilestone,
    required this.interviewClaim,
  });
}

class LearningAgentRuntimeFrameworkSelection {
  final String framework;
  final String bestFit;
  final String whyNotNow;
  final String adoptionPath;
  final String interviewClaim;

  const LearningAgentRuntimeFrameworkSelection({
    required this.framework,
    required this.bestFit,
    required this.whyNotNow,
    required this.adoptionPath,
    required this.interviewClaim,
  });
}

class LearningAgentRuntimeCodeWalkthroughStep {
  final String step;
  final String fileReference;
  final String whatToShow;
  final String interviewNarration;

  const LearningAgentRuntimeCodeWalkthroughStep({
    required this.step,
    required this.fileReference,
    required this.whatToShow,
    required this.interviewNarration,
  });
}

class LearningAgentRuntimeDebugScenario {
  final String scenario;
  final String likelyCause;
  final String inspectionPath;
  final String fixStrategy;
  final String interviewClaim;

  const LearningAgentRuntimeDebugScenario({
    required this.scenario,
    required this.likelyCause,
    required this.inspectionPath,
    required this.fixStrategy,
    required this.interviewClaim,
  });
}

class LearningAgentRuntimeDemoStep {
  final String moment;
  final String appAction;
  final String narration;
  final String proofPoint;

  const LearningAgentRuntimeDemoStep({
    required this.moment,
    required this.appAction,
    required this.narration,
    required this.proofPoint,
  });
}

class LearningAgentRuntimeSourceGroundingCheck {
  final String check;
  final String verificationPath;
  final String passSignal;
  final String failureResponse;
  final String interviewClaim;

  const LearningAgentRuntimeSourceGroundingCheck({
    required this.check,
    required this.verificationPath,
    required this.passSignal,
    required this.failureResponse,
    required this.interviewClaim,
  });
}

class LearningAgentRuntimeGlossaryTerm {
  final String term;
  final String definition;
  final String interviewUse;

  const LearningAgentRuntimeGlossaryTerm({
    required this.term,
    required this.definition,
    required this.interviewUse,
  });
}

class LearningAgentRuntimePracticeStep {
  final String title;
  final String action;
  final String successSignal;

  const LearningAgentRuntimePracticeStep({
    required this.title,
    required this.action,
    required this.successSignal,
  });
}

class LearningAgentRuntimeAnswerFrame {
  final String questionType;
  final String openingClaim;
  final String evidenceToMention;
  final String boundaryToState;
  final String closingMove;

  const LearningAgentRuntimeAnswerFrame({
    required this.questionType,
    required this.openingClaim,
    required this.evidenceToMention,
    required this.boundaryToState,
    required this.closingMove,
  });
}

class LearningAgentRuntimeChallengeResponse {
  final String challenge;
  final String conciseResponse;
  final String evidenceToShow;
  final String boundary;
  final String bridgeBack;

  const LearningAgentRuntimeChallengeResponse({
    required this.challenge,
    required this.conciseResponse,
    required this.evidenceToShow,
    required this.boundary,
    required this.bridgeBack,
  });
}

class LearningAgentRuntimeExperienceStory {
  final String prompt;
  final String situation;
  final String action;
  final String technicalChoice;
  final String proof;
  final String outcome;

  const LearningAgentRuntimeExperienceStory({
    required this.prompt,
    required this.situation,
    required this.action,
    required this.technicalChoice,
    required this.proof,
    required this.outcome,
  });
}

class LearningAgentRuntimeMockInterviewRound {
  final String round;
  final String interviewerPrompt;
  final String pressureFollowUp;
  final String expectedEvidence;
  final String passSignal;

  const LearningAgentRuntimeMockInterviewRound({
    required this.round,
    required this.interviewerPrompt,
    required this.pressureFollowUp,
    required this.expectedEvidence,
    required this.passSignal,
  });
}

class LearningAgentRuntimeMockInterviewScoreRule {
  final String criterion;
  final String fullCreditSignal;
  final String weakSignal;
  final String repairAction;

  const LearningAgentRuntimeMockInterviewScoreRule({
    required this.criterion,
    required this.fullCreditSignal,
    required this.weakSignal,
    required this.repairAction,
  });
}

class LearningAgentRuntimeMockInterviewRepairDrill {
  final String weakness;
  final String reviewTarget;
  final String practiceAction;
  final String retryPrompt;
  final String doneSignal;

  const LearningAgentRuntimeMockInterviewRepairDrill({
    required this.weakness,
    required this.reviewTarget,
    required this.practiceAction,
    required this.retryPrompt,
    required this.doneSignal,
  });
}

class LearningAgentFrameworkMapping {
  final String framework;
  final String borrowedPattern;
  final String localComponent;

  const LearningAgentFrameworkMapping({
    required this.framework,
    required this.borrowedPattern,
    required this.localComponent,
  });
}

class LearningAgentRuntimeBoundaryNote {
  final String topic;
  final String currentBoundary;
  final String interviewClaim;

  const LearningAgentRuntimeBoundaryNote({
    required this.topic,
    required this.currentBoundary,
    required this.interviewClaim,
  });
}

class LearningAgentRuntimeEvidenceAnchor {
  final String claim;
  final String codeReference;
  final String support;

  const LearningAgentRuntimeEvidenceAnchor({
    required this.claim,
    required this.codeReference,
    required this.support,
  });
}

class LearningAgentRuntimeAnswerRubricItem {
  final String criterion;
  final String passSignal;
  final String watchOut;

  const LearningAgentRuntimeAnswerRubricItem({
    required this.criterion,
    required this.passSignal,
    required this.watchOut,
  });
}

class LearningAgentRuntimeSourceReference {
  final String title;
  final String reference;
  final String sourceType;
  final String supports;
  final String trustNote;
  final String verifiedAt;
  final String evidenceNote;

  const LearningAgentRuntimeSourceReference({
    required this.title,
    required this.reference,
    required this.sourceType,
    required this.supports,
    required this.trustNote,
    required this.verifiedAt,
    required this.evidenceNote,
  });
}

class LearningAgentInterviewPrompt {
  final String question;
  final String outline;
  final String sampleAnswer;
  final String selfCheck;
  final String evidenceHint;

  const LearningAgentInterviewPrompt({
    required this.question,
    required this.outline,
    required this.sampleAnswer,
    required this.selfCheck,
    required this.evidenceHint,
  });
}

String learningAgentRuntimeInterviewCardCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# ${card.title}',
    '',
    card.summary,
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '练习流程:',
    for (final step in card.practiceSteps) _practiceStepCopyLine(step),
    '',
    '60 秒讲法:',
    card.answerScript,
    '',
    '回答检查:',
    for (final item in card.answerRubric) _rubricItemCopyLine(item),
    '',
    '标签:',
    ...card.badges.map((badge) => '- $badge'),
    '',
    '术语速记:',
    for (final term in card.glossaryTerms) _glossaryTermCopyLine(term),
    '',
    '讲法:',
    for (var i = 0; i < card.talkingPoints.length; i += 1)
      '${i + 1}. ${card.talkingPoints[i]}',
    '',
    '回答框架:',
    for (final frame in card.answerFrames) _answerFrameCopyLine(frame),
    '',
    '追问应对:',
    for (final response in card.challengeResponses)
      _challengeResponseCopyLine(response),
    '',
    '项目经历:',
    for (final story in card.experienceStories) _experienceStoryCopyLine(story),
    '',
    '模拟面试轮次:',
    for (final round in card.mockInterviewRounds)
      _mockInterviewRoundCopyLine(round),
    '',
    '模拟面试评分:',
    for (final rule in card.mockInterviewScoreRules)
      _mockInterviewScoreRuleCopyLine(rule),
    '',
    '模拟面试修复路线:',
    for (final drill in card.mockInterviewRepairDrills)
      _mockInterviewRepairDrillCopyLine(drill),
    '',
    '框架借鉴:',
    for (final mapping in card.frameworkMappings)
      _frameworkMappingCopyLine(mapping),
    '',
    '框架选型:',
    for (final selection in card.frameworkSelections)
      _frameworkSelectionCopyLine(selection),
    '',
    '架构决策:',
    for (final record in card.decisionRecords) _decisionRecordCopyLine(record),
    '',
    '当前边界:',
    for (final note in card.boundaryNotes) _boundaryNoteCopyLine(note),
    '',
    '成熟度阶梯:',
    for (final level in card.maturityLevels) _maturityLevelCopyLine(level),
    '',
    '避坑清单:',
    for (final pitfall in card.pitfalls) _pitfallCopyLine(pitfall),
    '',
    '演进路线:',
    for (final step in card.evolutionSteps) _evolutionStepCopyLine(step),
    '',
    '迁移触发条件:',
    for (final trigger in card.migrationTriggers)
      _migrationTriggerCopyLine(trigger),
    '',
    '代码走读路线:',
    for (final step in card.codeWalkthroughSteps)
      _codeWalkthroughStepCopyLine(step),
    '',
    '调试场景:',
    for (final scenario in card.debugScenarios)
      _debugScenarioCopyLine(scenario),
    '',
    '演示脚本:',
    for (final step in card.demoSteps) _demoStepCopyLine(step),
    '',
    '来源核验清单:',
    for (final check in card.sourceGroundingChecks)
      _sourceGroundingCheckCopyLine(check),
    '',
    '代码依据:',
    for (final anchor in card.evidenceAnchors) _evidenceAnchorCopyLine(anchor),
    '',
    '外部来源:',
    for (final reference in card.frameworkSourceReferences)
      _sourceReferenceCopyLine(reference),
    '',
    '自测追问:',
    for (var i = 0; i < card.prompts.length; i += 1) ...[
      '${i + 1}. ${card.prompts[i].question}',
      '   提纲: ${card.prompts[i].outline}',
      '   参考答法: ${card.prompts[i].sampleAnswer}',
      '   自评: ${card.prompts[i].selfCheck}',
      '   证据: ${card.prompts[i].evidenceHint}',
    ],
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeAnswerScriptCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# 60 秒讲法：${card.title}',
    '',
    card.answerScript,
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '回答检查:',
    for (final item in card.answerRubric) _rubricItemCopyLine(item),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
    for (final reference in card.frameworkSourceReferences)
      _sourceReferenceCopyLine(reference),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeQuestionAnswerPackCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# 面试 Q&A 练习包：${card.title}',
    '',
    '练习方式: 先遮住提纲自答，再用回答检查、代码依据和外部来源补齐。',
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '练习流程:',
    for (final step in card.practiceSteps) _practiceStepCopyLine(step),
    '',
    '60 秒总答:',
    card.answerScript,
    '',
    '术语速记:',
    for (final term in card.glossaryTerms) _glossaryTermCopyLine(term),
    '',
    '回答框架:',
    for (final frame in card.answerFrames) _answerFrameCopyLine(frame),
    '',
    '追问应对:',
    for (final response in card.challengeResponses)
      _challengeResponseCopyLine(response),
    '',
    '项目经历:',
    for (final story in card.experienceStories) _experienceStoryCopyLine(story),
    '',
    '模拟面试轮次:',
    for (final round in card.mockInterviewRounds)
      _mockInterviewRoundCopyLine(round),
    '',
    '模拟面试评分:',
    for (final rule in card.mockInterviewScoreRules)
      _mockInterviewScoreRuleCopyLine(rule),
    '',
    '模拟面试修复路线:',
    for (final drill in card.mockInterviewRepairDrills)
      _mockInterviewRepairDrillCopyLine(drill),
    '',
    '自测问答:',
    for (var i = 0; i < card.prompts.length; i += 1) ...[
      '${i + 1}. Q: ${card.prompts[i].question}',
      '   A 提纲: ${card.prompts[i].outline}',
      '   A 参考: ${card.prompts[i].sampleAnswer}',
      '   自评标准: ${card.prompts[i].selfCheck}',
      '   证据提示: ${card.prompts[i].evidenceHint}',
    ],
    '',
    '回答检查:',
    for (final item in card.answerRubric) _rubricItemCopyLine(item),
    '',
    '框架选型:',
    for (final selection in card.frameworkSelections)
      _frameworkSelectionCopyLine(selection),
    '',
    '架构决策:',
    for (final record in card.decisionRecords) _decisionRecordCopyLine(record),
    '',
    '成熟度阶梯:',
    for (final level in card.maturityLevels) _maturityLevelCopyLine(level),
    '',
    '避坑清单:',
    for (final pitfall in card.pitfalls) _pitfallCopyLine(pitfall),
    '',
    '演进路线:',
    for (final step in card.evolutionSteps) _evolutionStepCopyLine(step),
    '',
    '迁移触发条件:',
    for (final trigger in card.migrationTriggers)
      _migrationTriggerCopyLine(trigger),
    '',
    '代码走读路线:',
    for (final step in card.codeWalkthroughSteps)
      _codeWalkthroughStepCopyLine(step),
    '',
    '调试场景:',
    for (final scenario in card.debugScenarios)
      _debugScenarioCopyLine(scenario),
    '',
    '演示脚本:',
    for (final step in card.demoSteps) _demoStepCopyLine(step),
    '',
    '来源核验清单:',
    for (final check in card.sourceGroundingChecks)
      _sourceGroundingCheckCopyLine(check),
    '',
    '代码依据:',
    for (final anchor in card.evidenceAnchors) _evidenceAnchorCopyLine(anchor),
    '',
    '外部来源:',
    for (final reference in card.frameworkSourceReferences)
      _sourceReferenceCopyLine(reference),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeBlindDrillCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# 面试盲练稿：${card.title}',
    '',
    '练习方式: 先只看问题、提纲和自评标准作答，再回到 Q&A 包对照修正。',
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '练习流程:',
    for (final step in card.practiceSteps) _practiceStepCopyLine(step),
    '',
    '回答框架:',
    for (final frame in card.answerFrames) _answerFrameCopyLine(frame),
    '',
    '追问应对:',
    for (final response in card.challengeResponses)
      _challengeResponseCopyLine(response),
    '',
    '项目经历:',
    for (final story in card.experienceStories) _experienceStoryCopyLine(story),
    '',
    '模拟面试轮次:',
    for (final round in card.mockInterviewRounds)
      _mockInterviewRoundCopyLine(round),
    '',
    '模拟面试评分:',
    for (final rule in card.mockInterviewScoreRules)
      _mockInterviewScoreRuleCopyLine(rule),
    '',
    '模拟面试修复路线:',
    for (final drill in card.mockInterviewRepairDrills)
      _mockInterviewRepairDrillCopyLine(drill),
    '',
    '盲练题:',
    for (var i = 0; i < card.prompts.length; i += 1) ...[
      '${i + 1}. Q: ${card.prompts[i].question}',
      '   提纲: ${card.prompts[i].outline}',
      '   我的回答:',
      '   自评标准: ${card.prompts[i].selfCheck}',
      '   证据提示: ${card.prompts[i].evidenceHint}',
      '   修正后答案:',
    ],
    '',
    '回答检查:',
    for (final item in card.answerRubric) _rubricItemCopyLine(item),
    '',
    '框架选型:',
    for (final selection in card.frameworkSelections)
      _frameworkSelectionCopyLine(selection),
    '',
    '架构决策:',
    for (final record in card.decisionRecords) _decisionRecordCopyLine(record),
    '',
    '成熟度阶梯:',
    for (final level in card.maturityLevels) _maturityLevelCopyLine(level),
    '',
    '避坑清单:',
    for (final pitfall in card.pitfalls) _pitfallCopyLine(pitfall),
    '',
    '演进路线:',
    for (final step in card.evolutionSteps) _evolutionStepCopyLine(step),
    '',
    '迁移触发条件:',
    for (final trigger in card.migrationTriggers)
      _migrationTriggerCopyLine(trigger),
    '',
    '代码走读路线:',
    for (final step in card.codeWalkthroughSteps)
      _codeWalkthroughStepCopyLine(step),
    '',
    '调试场景:',
    for (final scenario in card.debugScenarios)
      _debugScenarioCopyLine(scenario),
    '',
    '演示脚本:',
    for (final step in card.demoSteps) _demoStepCopyLine(step),
    '',
    '来源核验清单:',
    for (final check in card.sourceGroundingChecks)
      _sourceGroundingCheckCopyLine(check),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeChallengeDrillCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# 面试追问练习：${card.title}',
    '',
    '练习方式: 先只看质疑，用自己的话短答，再对照证据、边界和拉回主线修正。',
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '追问盲练:',
    for (var i = 0; i < card.challengeResponses.length; i += 1) ...[
      '${i + 1}. 质疑: ${card.challengeResponses[i].challenge}',
      '   我的短答:',
      '   参考短答: ${card.challengeResponses[i].conciseResponse}',
      '   证据: ${card.challengeResponses[i].evidenceToShow}',
      '   边界: ${card.challengeResponses[i].boundary}',
      '   拉回主线: ${card.challengeResponses[i].bridgeBack}',
      '   修正后复述:',
    ],
    '',
    '回答框架:',
    for (final frame in card.answerFrames) _answerFrameCopyLine(frame),
    '',
    '代码依据:',
    for (final anchor in card.evidenceAnchors) _evidenceAnchorCopyLine(anchor),
    '',
    '外部来源:',
    for (final reference in card.frameworkSourceReferences)
      _sourceReferenceCopyLine(reference),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeDebugDrillCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# Agent runtime 调试练习：${card.title}',
    '',
    '练习方式: 先只看故障现象，用自己的话说可能原因、排查路径和修复策略，再对照参考讲法修正。',
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '调试盲练:',
    for (var i = 0; i < card.debugScenarios.length; i += 1) ...[
      '${i + 1}. 故障: ${card.debugScenarios[i].scenario}',
      '   我的判断:',
      '   可能原因: ${card.debugScenarios[i].likelyCause}',
      '   排查路径: ${card.debugScenarios[i].inspectionPath}',
      '   修复策略: ${card.debugScenarios[i].fixStrategy}',
      '   面试讲法: ${card.debugScenarios[i].interviewClaim}',
      '   修正后复述:',
    ],
    '',
    '代码走读路线:',
    for (final step in card.codeWalkthroughSteps)
      _codeWalkthroughStepCopyLine(step),
    '',
    '代码依据:',
    for (final anchor in card.evidenceAnchors) _evidenceAnchorCopyLine(anchor),
    '',
    '来源核验清单:',
    for (final check in card.sourceGroundingChecks)
      _sourceGroundingCheckCopyLine(check),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeExperienceDrillCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# 项目经历练习：${card.title}',
    '',
    '练习方式: 先只看经历提示，用自己的话讲 60-90 秒，再对照背景、行动、技术取舍、证据和结果修正。',
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '项目经历盲练:',
    for (var i = 0; i < card.experienceStories.length; i += 1) ...[
      '${i + 1}. 提示: ${card.experienceStories[i].prompt}',
      '   我的回答:',
      '   背景: ${card.experienceStories[i].situation}',
      '   行动: ${card.experienceStories[i].action}',
      '   技术取舍: ${card.experienceStories[i].technicalChoice}',
      '   证据: ${card.experienceStories[i].proof}',
      '   结果: ${card.experienceStories[i].outcome}',
      '   修正后复述:',
    ],
    '',
    '回答框架:',
    for (final frame in card.answerFrames) _answerFrameCopyLine(frame),
    '',
    '代码依据:',
    for (final anchor in card.evidenceAnchors) _evidenceAnchorCopyLine(anchor),
    '',
    '外部来源:',
    for (final reference in card.frameworkSourceReferences)
      _sourceReferenceCopyLine(reference),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeMockInterviewDrillCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# 模拟面试练习：${card.title}',
    '',
    '练习方式: 按轮次限时作答，先答主问题，再答压力追问，最后用预期证据和通过信号复盘。',
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '模拟面试轮次:',
    for (var i = 0; i < card.mockInterviewRounds.length; i += 1) ...[
      '${i + 1}. ${card.mockInterviewRounds[i].round}',
      '   面试官问题: ${card.mockInterviewRounds[i].interviewerPrompt}',
      '   我的主回答:',
      '   压力追问: ${card.mockInterviewRounds[i].pressureFollowUp}',
      '   我的追问短答:',
      '   预期证据: ${card.mockInterviewRounds[i].expectedEvidence}',
      '   通过信号: ${card.mockInterviewRounds[i].passSignal}',
      '   证据核对:',
      '   修正后复述:',
    ],
    '',
    '评分规则:',
    for (final rule in card.mockInterviewScoreRules)
      _mockInterviewScoreRuleCopyLine(rule),
    '',
    '回答框架:',
    for (final frame in card.answerFrames) _answerFrameCopyLine(frame),
    '',
    '追问应对:',
    for (final response in card.challengeResponses)
      _challengeResponseCopyLine(response),
    '',
    '项目经历:',
    for (final story in card.experienceStories) _experienceStoryCopyLine(story),
    '',
    '代码依据:',
    for (final anchor in card.evidenceAnchors) _evidenceAnchorCopyLine(anchor),
    '',
    '外部来源:',
    for (final reference in card.frameworkSourceReferences)
      _sourceReferenceCopyLine(reference),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeMockInterviewScoreSheetCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# 模拟面试评分复盘：${card.title}',
    '',
    '使用方式: 完成一轮模拟面试后逐项打分，记录失分原因，再按修复动作回到对应材料重练。',
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '评分复盘表:',
    for (var i = 0; i < card.mockInterviewScoreRules.length; i += 1) ...[
      '${i + 1}. ${card.mockInterviewScoreRules[i].criterion}',
      '   我的分数/5:',
      '   满分信号: ${card.mockInterviewScoreRules[i].fullCreditSignal}',
      '   失分信号: ${card.mockInterviewScoreRules[i].weakSignal}',
      '   我的失分原因:',
      '   修复动作: ${card.mockInterviewScoreRules[i].repairAction}',
      '   修复记录:',
      '   下次复测结果:',
    ],
    '',
    '模拟面试轮次:',
    for (final round in card.mockInterviewRounds)
      _mockInterviewRoundCopyLine(round),
    '',
    '修复路线:',
    for (final drill in card.mockInterviewRepairDrills)
      _mockInterviewRepairDrillCopyLine(drill),
    '',
    '回答框架:',
    for (final frame in card.answerFrames) _answerFrameCopyLine(frame),
    '',
    '代码依据:',
    for (final anchor in card.evidenceAnchors) _evidenceAnchorCopyLine(anchor),
    '',
    '外部来源:',
    for (final reference in card.frameworkSourceReferences)
      _sourceReferenceCopyLine(reference),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeMockInterviewRepairDrillCopyText(
  LearningAgentRuntimeInterviewCard card,
) {
  final lines = <String>[
    '# 模拟面试修复练习：${card.title}',
    '',
    '练习方式: 先定位失分症状，按回看材料补证据，再用复测问题重答，最后用完成信号确认是否修好。',
    '',
    '证据覆盖:',
    learningAgentRuntimeEvidenceCoverageSummary(card),
    '',
    '修复练习:',
    for (var i = 0; i < card.mockInterviewRepairDrills.length; i += 1) ...[
      '${i + 1}. 失分症状: ${card.mockInterviewRepairDrills[i].weakness}',
      '   原失败回答:',
      '   回看材料: ${card.mockInterviewRepairDrills[i].reviewTarget}',
      '   练习动作: ${card.mockInterviewRepairDrills[i].practiceAction}',
      '   重练回答:',
      '   复测问题: ${card.mockInterviewRepairDrills[i].retryPrompt}',
      '   复测回答:',
      '   完成信号: ${card.mockInterviewRepairDrills[i].doneSignal}',
      '   证据核对:',
      '   完成确认:',
    ],
    '',
    '评分规则:',
    for (final rule in card.mockInterviewScoreRules)
      _mockInterviewScoreRuleCopyLine(rule),
    '',
    '模拟面试轮次:',
    for (final round in card.mockInterviewRounds)
      _mockInterviewRoundCopyLine(round),
    '',
    '回答框架:',
    for (final frame in card.answerFrames) _answerFrameCopyLine(frame),
    '',
    '代码依据:',
    for (final anchor in card.evidenceAnchors) _evidenceAnchorCopyLine(anchor),
    '',
    '外部来源:',
    for (final reference in card.frameworkSourceReferences)
      _sourceReferenceCopyLine(reference),
    '',
    '依据:',
    ...card.sourceNotes.map((note) => '- $note'),
  ];
  return lines.join('\n');
}

String learningAgentRuntimeEvidenceCoverageSummary(
  LearningAgentRuntimeInterviewCard card,
) {
  final sampleAnswerCount = card.prompts
      .where((prompt) => prompt.sampleAnswer.trim().isNotEmpty)
      .length;
  final selfCheckCount =
      card.prompts.where((prompt) => prompt.selfCheck.trim().isNotEmpty).length;
  final promptedEvidenceCount = card.prompts
      .where((prompt) => prompt.evidenceHint.trim().isNotEmpty)
      .length;

  return '${card.evidenceAnchors.length} 个代码依据 · '
      '${card.frameworkSourceReferences.length} 条外部来源 · '
      '${card.answerFrames.length} 个回答框架 · '
      '${card.challengeResponses.length} 个追问应对 · '
      '${card.experienceStories.length} 个项目经历 · '
      '${card.mockInterviewRounds.length} 个模拟面试轮次 · '
      '${card.mockInterviewScoreRules.length} 条模拟面试评分规则 · '
      '${card.mockInterviewRepairDrills.length} 条模拟面试修复路线 · '
      '${card.frameworkSelections.length} 个框架选型项 · '
      '${card.decisionRecords.length} 条架构决策 · '
      '${card.maturityLevels.length} 个成熟度层级 · '
      '${card.migrationTriggers.length} 个迁移触发条件 · '
      '${card.codeWalkthroughSteps.length} 步代码走读 · '
      '${card.debugScenarios.length} 个调试场景 · '
      '${card.demoSteps.length} 步演示脚本 · '
      '${card.sourceGroundingChecks.length} 项来源核验 · '
      '$sampleAnswerCount/${card.prompts.length} 个自测题带参考答法 · '
      '$selfCheckCount/${card.prompts.length} 个自测题带自评标准 · '
      '$promptedEvidenceCount/${card.prompts.length} 个自测题带证据提示';
}

String _frameworkMappingCopyLine(LearningAgentFrameworkMapping mapping) {
  return '- ${mapping.framework}: ${mapping.borrowedPattern} -> '
      '${mapping.localComponent}';
}

String _frameworkSelectionCopyLine(
  LearningAgentRuntimeFrameworkSelection selection,
) {
  return '- ${selection.framework}: 适合 ${selection.bestFit} '
      '暂不采用 ${selection.whyNotNow} '
      '接入路径 ${selection.adoptionPath} '
      '面试讲法: ${selection.interviewClaim}';
}

String _practiceStepCopyLine(LearningAgentRuntimePracticeStep step) {
  return '- ${step.title}: ${step.action} 达标: ${step.successSignal}';
}

String _glossaryTermCopyLine(LearningAgentRuntimeGlossaryTerm term) {
  return '- ${term.term}: ${term.definition} 面试用法: ${term.interviewUse}';
}

String _answerFrameCopyLine(LearningAgentRuntimeAnswerFrame frame) {
  return '- ${frame.questionType}: 开场 ${frame.openingClaim} '
      '证据 ${frame.evidenceToMention} 边界 ${frame.boundaryToState} '
      '收束 ${frame.closingMove}';
}

String _challengeResponseCopyLine(
  LearningAgentRuntimeChallengeResponse response,
) {
  return '- ${response.challenge}: 短答 ${response.conciseResponse} '
      '证据 ${response.evidenceToShow} 边界 ${response.boundary} '
      '拉回主线 ${response.bridgeBack}';
}

String _experienceStoryCopyLine(LearningAgentRuntimeExperienceStory story) {
  return '- ${story.prompt}: 背景 ${story.situation} 行动 ${story.action} '
      '技术取舍 ${story.technicalChoice} 证据 ${story.proof} '
      '结果 ${story.outcome}';
}

String _mockInterviewRoundCopyLine(
  LearningAgentRuntimeMockInterviewRound round,
) {
  return '- ${round.round}: 问题 ${round.interviewerPrompt} '
      '追问 ${round.pressureFollowUp} 证据 ${round.expectedEvidence} '
      '通过信号 ${round.passSignal}';
}

String _mockInterviewScoreRuleCopyLine(
  LearningAgentRuntimeMockInterviewScoreRule rule,
) {
  return '- ${rule.criterion}: 满分 ${rule.fullCreditSignal} '
      '失分 ${rule.weakSignal} 修复 ${rule.repairAction}';
}

String _mockInterviewRepairDrillCopyLine(
  LearningAgentRuntimeMockInterviewRepairDrill drill,
) {
  return '- ${drill.weakness}: 回看 ${drill.reviewTarget} '
      '练习 ${drill.practiceAction} 复测 ${drill.retryPrompt} '
      '完成信号 ${drill.doneSignal}';
}

String _boundaryNoteCopyLine(LearningAgentRuntimeBoundaryNote note) {
  return '- ${note.topic}: ${note.currentBoundary} '
      '面试讲法: ${note.interviewClaim}';
}

String _pitfallCopyLine(LearningAgentRuntimePitfall pitfall) {
  return '- 避免: ${pitfall.riskyClaim} 改说: ${pitfall.saferClaim} '
      '原因: ${pitfall.reason}';
}

String _evolutionStepCopyLine(LearningAgentRuntimeEvolutionStep step) {
  return '- ${step.milestone}: 当前基础 ${step.currentFoundation} '
      '下一步 ${step.nextUpgrade} 面试讲法: ${step.interviewClaim}';
}

String _decisionRecordCopyLine(LearningAgentRuntimeDecisionRecord record) {
  return '- ${record.decision}: 原因 ${record.rationale} '
      '代价 ${record.tradeoff} 面试讲法: ${record.interviewClaim}';
}

String _migrationTriggerCopyLine(
  LearningAgentRuntimeMigrationTrigger trigger,
) {
  return '- ${trigger.trigger}: 当前信号 ${trigger.currentSignal} '
      '升级动作 ${trigger.upgradeAction} 面试讲法: ${trigger.interviewClaim}';
}

String _maturityLevelCopyLine(LearningAgentRuntimeMaturityLevel level) {
  return '- ${level.level}: 已有 ${level.implementedSignal} '
      '缺口 ${level.missingCapability} 下一层 ${level.nextMilestone} '
      '面试讲法: ${level.interviewClaim}';
}

String _codeWalkthroughStepCopyLine(
  LearningAgentRuntimeCodeWalkthroughStep step,
) {
  return '- ${step.step}: ${step.fileReference} '
      '看点 ${step.whatToShow} 面试讲法: ${step.interviewNarration}';
}

String _debugScenarioCopyLine(
  LearningAgentRuntimeDebugScenario scenario,
) {
  return '- ${scenario.scenario}: 可能原因 ${scenario.likelyCause} '
      '排查路径 ${scenario.inspectionPath} 修复策略 ${scenario.fixStrategy} '
      '面试讲法: ${scenario.interviewClaim}';
}

String _demoStepCopyLine(LearningAgentRuntimeDemoStep step) {
  return '- ${step.moment}: 操作 ${step.appAction} '
      '讲法 ${step.narration} 证据点: ${step.proofPoint}';
}

String _sourceGroundingCheckCopyLine(
  LearningAgentRuntimeSourceGroundingCheck check,
) {
  return '- ${check.check}: 核验 ${check.verificationPath} '
      '通过信号 ${check.passSignal} 失败处理 ${check.failureResponse} '
      '面试讲法: ${check.interviewClaim}';
}

String _evidenceAnchorCopyLine(LearningAgentRuntimeEvidenceAnchor anchor) {
  return '- ${anchor.claim}: ${anchor.codeReference} - ${anchor.support}';
}

String _rubricItemCopyLine(LearningAgentRuntimeAnswerRubricItem item) {
  return '- ${item.criterion}: 达标 ${item.passSignal}; '
      '避免 ${item.watchOut}';
}

String _sourceReferenceCopyLine(LearningAgentRuntimeSourceReference reference) {
  return '- [${reference.sourceType}] ${reference.title}: '
      '${reference.reference} - ${reference.supports} '
      '可信度: ${reference.trustNote} '
      '核验: ${reference.verifiedAt}; ${reference.evidenceNote}';
}

LearningAgentRuntimeInterviewCard learningAgentRuntimeInterviewCard({
  required LearningAgentPlan plan,
  LearningAgentState? state,
  LearningAgentToolDefinition? selectedTool,
  List<LearningAgentTraceEvent> traceEvents = const [],
  LearningAgentToolRegistry toolRegistry = const LearningAgentToolRegistry(),
}) {
  final tool = selectedTool ?? _toolForPlan(plan, state, toolRegistry);
  final nextStep = plan.sessionSummary.nextStep;
  final phase = state?.phase.label ?? '规划';
  final traceCount = traceEvents.isEmpty
      ? state?.traceEventIds.length ?? 0
      : traceEvents.length;
  final evidenceCount =
      state?.evidenceChunkIds.length ?? _traceEvidenceCount(traceEvents);
  final toolLabel = tool?.title ?? nextStep?.title ?? '当前工具';

  return LearningAgentRuntimeInterviewCard(
    title: '面试讲法：本地学习 Agent',
    summary:
        '我把它做成 Flutter 本地 runtime：planner 给出下一步，policy 检查来源约束，executor 调用本地工具，state 和 trace 记录每次决策。',
    answerScript: '这个项目里的学习 Agent 不是自由聊天机器人，而是本地优先的学习 runtime。'
        '当前目标是“${plan.goal.label}”，它会根据 planner 选择“$toolLabel”，'
        '再由 policy 检查来源约束；检查通过后，executor 会先持久化包含 tool_started 的 checkpoint，成功后才启动本地工具。'
        '运行状态会记录在 phase=$phase 的 state 里，本轮 trace 有 $traceCount 条，'
        '证据上下文有 $evidenceCount 个片段。'
        '所以我面试时会强调：我先把 state、tool、policy、trace 和来源闭环做扎实，'
        '后续再把 planner 或 executor 迁移到更重的 agent 框架。',
    practiceSteps: const [
      LearningAgentRuntimePracticeStep(
        title: '1. 先自答',
        action: '遮住参考答法，只看问题和提纲，用自己的话在 60 秒内讲一遍。',
        successSignal: '能说出本地 runtime、来源约束、工具边界或恢复边界中的至少三点。',
      ),
      LearningAgentRuntimePracticeStep(
        title: '2. 对照参考',
        action: '打开参考答法，补齐漏掉的 runtime 组件，同时删掉夸大当前能力的表达。',
        successSignal: '回答保留个人表达，但能对齐参考答法里的关键架构判断。',
      ),
      LearningAgentRuntimePracticeStep(
        title: '3. 核对证据',
        action: '按证据提示回看代码文件、架构文档和外部来源，确认每个说法能落到依据。',
        successSignal: '每个核心 claim 都能对应到代码依据、文档依据或框架来源。',
      ),
      LearningAgentRuntimePracticeStep(
        title: '4. 压缩复述',
        action: '用回答检查 rubric 修剪答案，把最终版本压缩成清晰的面试口径。',
        successSignal: '最终回答能在 60 到 90 秒内讲完，并且不牺牲来源和边界说明。',
      ),
    ],
    answerRubric: const [
      LearningAgentRuntimeAnswerRubricItem(
        criterion: '本地优先',
        passSignal: '说清楚 Flutter、SQLite 和本地 runtime 是第一阶段基础。',
        watchOut: '只说“用了大模型”而不解释为什么先不接后端框架。',
      ),
      LearningAgentRuntimeAnswerRubricItem(
        criterion: '来源约束',
        passSignal: '提到 verified questions、source chunks 和 policy gate。',
        watchOut: '把 AI 生成内容当作正式来源或核验结果。',
      ),
      LearningAgentRuntimeAnswerRubricItem(
        criterion: 'Runtime contract',
        passSignal: '能串起 state、tool registry、executor、trace 和 provider 边界。',
        watchOut: '只描述页面跳转，没有解释 agent runtime 的组件边界。',
      ),
      LearningAgentRuntimeAnswerRubricItem(
        criterion: '诚实边界',
        passSignal: '承认还没有完全自治、长工具中间 checkpoint、向量检索或外部 agent 框架。',
        watchOut: '把当前实现夸成已经完整接入 LangGraph/RAG/多 agent。',
      ),
    ],
    badges: [
      plan.goal.label,
      tool?.title ?? nextStep?.title ?? '未匹配工具',
      '阶段 $phase',
      'Trace $traceCount',
    ],
    glossaryTerms: const [
      LearningAgentRuntimeGlossaryTerm(
        term: 'Planner',
        definition: '根据目标、知识状态和历史追问决定下一步学习动作。',
        interviewUse: '强调它负责选择方向，不负责绕过来源约束或直接生成正式学习内容。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Policy gate',
        definition: '在执行工具前检查来源、引用、题目状态和学习边界。',
        interviewUse: '用它解释这个 agent 如何避免把无依据输出带入正式学习。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Tool registry',
        definition: '把导入、核验、导师、面试、练习、复习等能力声明成工具元数据。',
        interviewUse: '用它说明 UI 不直接散落业务分发，而是通过 tool contract 描述能力。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Executor',
        definition: '读取 tool metadata，经过 policy gate 后启动本地页面或返回阻断原因。',
        interviewUse: '用它区分“工具声明”和“真正执行”的边界。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Trace',
        definition: '记录 agent 为什么选择某一步、用了哪些证据、是否被策略拦截。',
        interviewUse: '用它说明系统可复盘、可诊断，而不是一次性黑盒跳转。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Runtime state',
        definition: '保存 phase、目标、选中工具、证据片段和 trace id 等运行上下文。',
        interviewUse: '用它解释当前 checkpoint 恢复，以及未来迁移后端时哪些 contract 可以保持不变。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Optimistic concurrency control',
        definition: '保存时携带读取到的 revision，只有数据库仍是该 revision 才推进下一版。',
        interviewUse: '用它解释为什么旧页面、重复恢复或重复用户决策不能覆盖最新 checkpoint。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Durable tool-call boundary',
        definition:
            'Policy 通过后先持久化包含 tool_started 的 checkpoint，保存成功才允许进入真实工具调用。',
        interviewUse: '用它说明 checkpoint 写失败时工具不会启动，同时明确这还不等于 exactly-once。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Tool operation identity',
        definition:
            'operation id 表示一次逻辑工具操作并在人工重试时保持稳定；attempt id 表示一次真实调用，每次重试都会变化。',
        interviewUse: '用它解释为什么可以关联多次调用，又不能把客户端身份直接说成服务端幂等执行。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Tool input snapshot',
        definition:
            '为一次 active operation 保存版本化、可读的 routing input；重试前比较 tool、target、focus 和 evidence ids。',
        interviewUse:
            '用它解释 same request id / different intent 的客户端防线，同时明确它不是完整请求体或服务端结果缓存。',
      ),
      LearningAgentRuntimeGlossaryTerm(
        term: 'Unknown tool outcome',
        definition:
            '工具已经越过 durable start 边界，但进程退出前没有保存完成或失败结果，因此系统不能断言副作用是否发生。',
        interviewUse:
            '用 operation id 关联逻辑操作、attempt id 关联 tool_started，并让用户选择重新执行、确认已完成或结束会话。',
      ),
    ],
    talkingPoints: [
      '状态机：一次 Agent Session 会记录 phase、target、tool、evidence 和 trace ids，并通过本地 checkpoint 支持解释和恢复。',
      '工具循环：UI 通过 provider 调用 executor，executor 只选择并启动本地工具，不在页面里散落业务分发。',
      '持久调用边界：policy 通过后先保存 tool_started，再执行真实工具；保存失败不会越过副作用边界。',
      '未知结果恢复：tool-start checkpoint 同时保存稳定 operation id、单次 attempt id 和人工决策请求。',
      '输入一致性：同 operation 重试前比较 routing input snapshot，变化时在 tool_started 前拒绝。',
      '来源约束：${plan.sessionSummary.evidenceConstraint}',
      '可追踪：本轮已有 $traceCount 条 trace，证据上下文 $evidenceCount 个片段。',
    ],
    answerFrames: const [
      LearningAgentRuntimeAnswerFrame(
        questionType: '项目总览类问题',
        openingClaim: '我把这个项目从刷题 app 重建成本地优先的 source-grounded learning agent。',
        evidenceToMention:
            '讲 planner、policy、executor、state、trace，再指向 Agent Session 准备页和代码依据。',
        boundaryToState: '说明当前是轻量 Flutter/Dart runtime，还不是完全自治多 agent 系统。',
        closingMove: '收束到“先保证学习正确性和可复盘，再升级更重 agent 框架”。',
      ),
      LearningAgentRuntimeAnswerFrame(
        questionType: '为什么不直接用 LangGraph 或 Agents SDK',
        openingClaim: '当前用户价值先在本地学习闭环和来源正确性，所以我先做可替换的 runtime contract。',
        evidenceToMention:
            '引用 framework selection、migration triggers、state/trace contract 和 ToolRegistry。',
        boundaryToState:
            '承认没有真实接入 LangGraph 或 Agents SDK，只是借鉴状态图、tool loop 和 tracing 思想。',
        closingMove: '说明当恢复、重试、结构化工具和评估需求变强时，再迁移 executor 或 graph 层。',
      ),
      LearningAgentRuntimeAnswerFrame(
        questionType: '如何保证知识正确有来源',
        openingClaim:
            '我把 AI 输出放在草稿层，正式学习必须经过 source chunks、verified questions 和 policy gate。',
        evidenceToMention:
            '引用 source-grounding audit checklist、LearningAgentPolicy、citation IDs 和外部来源核验日期。',
        boundaryToState: '说明当前还不是完整 RAG，没有向量检索，但已有来源闭环和引用约束。',
        closingMove: '强调后续可以替换检索层，但不能放松 source-grounding contract。',
      ),
      LearningAgentRuntimeAnswerFrame(
        questionType: '如何调试 agent 行为',
        openingClaim: '我会先按 planner、policy、executor、state、trace 的顺序定位问题。',
        evidenceToMention:
            '引用 debugScenarios、policy_checked/tool_started/tool_failed trace 和 state diagnostics。',
        boundaryToState: '不把所有问题都归因给模型，而是先检查输入、规则、工具映射和证据 ID 链路。',
        closingMove: '用 trace 复盘说明这个 runtime 是可解释、可诊断的。',
      ),
      LearningAgentRuntimeAnswerFrame(
        questionType: '未来演进类问题',
        openingClaim: '我会沿着状态图、工具循环、检索层和评估系统四条线渐进升级。',
        evidenceToMention:
            '引用 evolutionSteps、maturityLevels、migrationTriggers 和外部框架来源。',
        boundaryToState: '明确当前没有云同步、向量数据库、长工具内部 checkpoint 或多 agent 协作。',
        closingMove: '把下一步落到可验证里程碑，而不是泛泛说“接一个框架”。',
      ),
    ],
    challengeResponses: const [
      LearningAgentRuntimeChallengeResponse(
        challenge: '这是不是只是普通页面流程，不算 agent？',
        conciseResponse:
            '当前不是完全自治 agent，但已经把学习流程抽成 planner、tool、policy、executor、state 和 trace 的 runtime contract。',
        evidenceToShow:
            '展示 LearningAgentState、LearningAgentToolRegistry、LearningAgentExecutor 和 LearningAgentTraceEvent。',
        boundary: '说明已有 SQLite checkpoint 和跨重启恢复，但还没有开放式自主循环、模型驱动规划和分支回放。',
        bridgeBack: '把重点拉回“先把本地学习 agent 的可控性、来源约束和可复盘性做好”。',
      ),
      LearningAgentRuntimeChallengeResponse(
        challenge: '为什么不直接接 LangGraph 或 OpenAI Agents SDK？',
        conciseResponse: '因为当前核心风险不是框架能力不足，而是学习材料是否有来源、是否能在 Flutter 本地闭环。',
        evidenceToShow: '展示框架选型矩阵、迁移触发条件和架构决策记录。',
        boundary: '明确现在只是借鉴状态图、tool loop 和 tracing，不宣称已经接入这些框架。',
        bridgeBack: '说明当工具失败、恢复、结构化 schema 和评估需求变强时再替换 runtime 层。',
      ),
      LearningAgentRuntimeChallengeResponse(
        challenge: 'AI 生成内容怎么保证不胡说？',
        conciseResponse:
            '我没有让 AI 输出直接进入正式学习，而是通过 source chunks、verified questions、citation IDs 和 policy gate 控制。',
        evidenceToShow: '展示来源核验清单、LearningAgentPolicy 和证据覆盖摘要。',
        boundary: '承认当前还没有完整向量 RAG 和 citation rerank，但已有可核验来源闭环。',
        bridgeBack: '强调后续可以升级检索层，但 source-grounding contract 不能放松。',
      ),
      LearningAgentRuntimeChallengeResponse(
        challenge: '你真的理解 vibe coding 生成的代码吗？',
        conciseResponse:
            '我会按代码走读路线从 UI 入口讲到 planner、tool registry、policy、executor、state 和 trace。',
        evidenceToShow: '展示代码走读路线、调试场景和演示脚本中的证据点。',
        boundary: '不说每个历史实现都是一次写对，而是强调通过 Trellis 小步重建和文档化把系统理解补齐。',
        bridgeBack: '把回答拉回“能按文件解释设计取舍、故障路径和后续迁移”。',
      ),
      LearningAgentRuntimeChallengeResponse(
        challenge: '这个设计以后怎么扩展到真正知识库 agent？',
        conciseResponse:
            '会先保留 source-grounding、tool contract 和 trace contract，再替换检索层、恢复层和执行层。',
        evidenceToShow: '展示演进路线、成熟度阶梯、迁移触发条件和外部框架来源。',
        boundary: '承认当前没有云同步、向量数据库、多 agent 协作和完整评估系统。',
        bridgeBack: '把未来计划收束为可验证里程碑，而不是一次性推倒重写。',
      ),
    ],
    experienceStories: const [
      LearningAgentRuntimeExperienceStory(
        prompt: '讲一个你把模糊想法落成产品结构的经历',
        situation:
            '原项目更像 AI 拆题和游戏化刷题工具，但目标变成准备 AI 应用开发面试、讲清 vibe coding 项目和学习编程知识。',
        action:
            '我用 Trellis 把目标拆成 source、knowledge point、verified question、Agent Session 和 runtime interview card 等小 leaf。',
        technicalChoice:
            '先保留 Flutter 本地体验和 SQLite 数据闭环，再逐步加 source-grounding、agent runtime contract 和面试材料层。',
        proof:
            '可以展示 trellis-execution-map.md、Agent tab、Knowledge Base、Agent Session 准备页和 runtime 面试卡。',
        outcome: '项目从单纯刷题变成能导入资料、核验来源、练面试、走读 runtime 和复盘 trace 的学习 agent 雏形。',
      ),
      LearningAgentRuntimeExperienceStory(
        prompt: '讲一个你做过的架构抽象',
        situation: '一开始 Agent Session 容易被理解成页面跳转，面试时讲不清为什么它算 agent runtime。',
        action:
            '我把 planner、tool registry、policy gate、executor、state 和 trace 明确成 runtime contract。',
        technicalChoice: '没有急着接重框架，而是在 Dart 本地先做可解释、可替换的轻量 runtime。',
        proof:
            '可以走读 learning_agent_planner_service.dart、learning_agent_tool_registry.dart、learning_agent_executor.dart、learning_agent_state.dart 和 learning_agent_trace.dart。',
        outcome: '现在能诚实地说它不是完全自治 agent，但已有标准 agent 架构里最关键的状态、工具、策略和可观测边界。',
      ),
      LearningAgentRuntimeExperienceStory(
        prompt: '讲一个你如何控制 AI 输出质量的例子',
        situation: '学习 app 最怕 AI 生成内容看起来合理但没有来源，最后把错误知识带进正式练习。',
        action:
            '我把 AI 输出放在草稿层，正式学习必须通过 source chunks、verified questions、citation IDs 和 policy gate。',
        technicalChoice:
            '先做本地 source-grounding 和人工核验，再考虑 embedding index、vector retrieval 或 citation rerank。',
        proof:
            '可以展示来源核验清单、LearningAgentPolicy、question sourceStatus、citation IDs 和外部来源核验日期。',
        outcome: '面试时可以把“防幻觉”讲成工程约束，而不是只说 prompt 写得更严格。',
      ),
      LearningAgentRuntimeExperienceStory(
        prompt: '讲一个你如何让系统可调试的例子',
        situation: 'agent 出错时如果只看到页面没跳转，很难判断是 planner、policy、工具执行还是证据链路的问题。',
        action: '我引入 trace event、state diagnostics、调试场景和追问练习，让每次决策都能复盘。',
        technicalChoice:
            '先让本地 runtime 产生可复制的 trace，再把 trace 作为未来 replay、evaluation 和框架迁移的基础。',
        proof:
            '可以展示 debugScenarios、LearningAgentTraceEvent、policy_checked/tool_failed 事件和准备页 trace 复盘。',
        outcome: '系统从黑盒跳转变成可解释的学习流程，也让项目经历能讲清故障定位和后续演进。',
      ),
    ],
    mockInterviewRounds: const [
      LearningAgentRuntimeMockInterviewRound(
        round: '第一轮：项目总览',
        interviewerPrompt: '请用 90 秒讲清这个 app 从刷题工具重建成学习 agent 的目标和核心能力。',
        pressureFollowUp: '这和普通刷题 app、普通笔记 app 的区别到底在哪里？',
        expectedEvidence:
            '展示 Agent tab、Knowledge Base、source-grounding 规则、runtime interview card 和 Trellis 文档。',
        passSignal: '回答能同时覆盖用户目标、学习闭环、来源约束和本地 agent runtime，而不是只列功能。',
      ),
      LearningAgentRuntimeMockInterviewRound(
        round: '第二轮：Agent 架构',
        interviewerPrompt: '为什么你说这里有 agent runtime，而不只是页面跳转和条件判断？',
        pressureFollowUp: '没有直接接 LangGraph 或 OpenAI Agents SDK，这个说法会不会夸大？',
        expectedEvidence:
            '走读 planner、tool registry、policy gate、executor、state 和 trace 的文件与页面表现。',
        passSignal: '能诚实区分当前轻量 runtime、借鉴的标准 agent pattern 和未来迁移路径。',
      ),
      LearningAgentRuntimeMockInterviewRound(
        round: '第三轮：来源正确性',
        interviewerPrompt: 'AI 生成学习内容时，你怎么避免用户学到没有依据或错误的知识？',
        pressureFollowUp: '如果还没有完整 RAG 和向量数据库，来源正确性凭什么可信？',
        expectedEvidence:
            '展示 source chunks、verified questions、citation IDs、LearningAgentPolicy 和来源核验清单。',
        passSignal: '能把防幻觉讲成数据状态、策略阻断、引用检查和人工核验的组合约束。',
      ),
      LearningAgentRuntimeMockInterviewRound(
        round: '第四轮：代码走读和调试',
        interviewerPrompt: '现场请你从一次 Agent Session 启动讲到 trace 复盘，说明关键代码路径。',
        pressureFollowUp: '如果 planner 选错工具、policy 误拦截或 trace 不一致，你怎么定位？',
        expectedEvidence:
            '展示 codeWalkthroughSteps、debugScenarios、LearningAgentTraceEvent 和准备页诊断信息。',
        passSignal:
            '能按 planner -> policy -> executor -> state -> trace 的顺序定位问题，并给出修复策略。',
      ),
      LearningAgentRuntimeMockInterviewRound(
        round: '第五轮：演进取舍',
        interviewerPrompt: '如果要把它继续扩成自己的知识库学习 agent，你会优先升级哪些部分？',
        pressureFollowUp: '什么时候该接重 agent 框架，什么时候继续保持 Flutter 本地轻量实现？',
        expectedEvidence:
            '展示 framework selection、maturity ladder、migration triggers、evolution steps 和外部框架来源。',
        passSignal: '回答能落到检索层、恢复层、工具层、评估层的可验证里程碑，而不是泛泛说以后接框架。',
      ),
    ],
    mockInterviewScoreRules: const [
      LearningAgentRuntimeMockInterviewScoreRule(
        criterion: '结构完整',
        fullCreditSignal: '回答能按背景、核心设计、证据、边界和下一步组织，而不是散列功能点。',
        weakSignal: '只说页面、按钮或“用了 AI”，没有讲清学习闭环和 agent runtime contract。',
        repairAction: '回到回答框架 section，把开场 claim、证据、边界和收束各补一句。',
      ),
      LearningAgentRuntimeMockInterviewScoreRule(
        criterion: '证据可展示',
        fullCreditSignal: '每个核心 claim 都能指向代码文件、页面区块、trace、Trellis 文档或外部来源。',
        weakSignal: '说法听起来合理，但回答时找不到对应文件、来源或页面证据。',
        repairAction: '补看代码走读路线、代码依据、外部来源和来源核验清单，再重答一遍。',
      ),
      LearningAgentRuntimeMockInterviewScoreRule(
        criterion: '边界诚实',
        fullCreditSignal: '能区分当前已实现、架构借鉴和未来迁移，不把轻量 runtime 夸成完整自治 agent。',
        weakSignal: '把当前实现说成已经接入 LangGraph、RAG、多 agent 或完整评估系统。',
        repairAction: '用避坑清单和当前边界 section 改写答案，把夸大的词换成可证明的说法。',
      ),
      LearningAgentRuntimeMockInterviewScoreRule(
        criterion: '调试路径清楚',
        fullCreditSignal:
            '遇到失败能按 planner、policy、executor、state、trace 的顺序排查，并说明修复策略。',
        weakSignal: '把问题泛泛归因给模型或页面 bug，没有定位到 runtime contract 的哪一层。',
        repairAction: '按调试场景 section 复述一次故障、可能原因、排查路径、修复策略和面试讲法。',
      ),
      LearningAgentRuntimeMockInterviewScoreRule(
        criterion: '表达可压缩',
        fullCreditSignal: '主回答能在 60-90 秒内讲完，压力追问能在 20 秒内短答并拉回主线。',
        weakSignal: '回答过长、绕远，或者被追问后开始补大量背景而没有直接回应质疑。',
        repairAction: '先复制模拟面试练习包，只保留主回答三句和追问短答两句，再补证据核对。',
      ),
    ],
    mockInterviewRepairDrills: const [
      LearningAgentRuntimeMockInterviewRepairDrill(
        weakness: '回答像功能清单',
        reviewTarget: '回答框架、项目经历、架构决策',
        practiceAction: '把答案改成“为什么重建、核心 runtime、来源约束、当前边界、下一步”五句。',
        retryPrompt: '请用 90 秒讲清这个 app 和普通刷题/笔记 app 的区别。',
        doneSignal: '听起来像一条产品和架构主线，而不是页面列表。',
      ),
      LearningAgentRuntimeMockInterviewRepairDrill(
        weakness: '证据说不出来',
        reviewTarget: '代码走读路线、代码依据、外部来源、来源核验清单',
        practiceAction: '每个 claim 后面补一个“我会展示...”句子，并指出文件、页面或文档。',
        retryPrompt: '请指出三个能证明 agent runtime 和来源约束真实存在的证据。',
        doneSignal: '每个核心说法都能落到代码、页面、trace、Trellis 或外部来源。',
      ),
      LearningAgentRuntimeMockInterviewRepairDrill(
        weakness: '边界说得过满',
        reviewTarget: '当前边界、避坑清单、框架选型、迁移触发条件',
        practiceAction: '把“已经实现完整 agent/RAG”改成“当前已实现、借鉴了什么、何时迁移”。',
        retryPrompt: '为什么现在不直接接 LangGraph、OpenAI Agents SDK 或向量数据库？',
        doneSignal: '回答能明确区分已实现能力、架构借鉴和未来升级。',
      ),
      LearningAgentRuntimeMockInterviewRepairDrill(
        weakness: '调试路径混乱',
        reviewTarget: '调试场景、代码走读路线、trace 复盘、来源核验清单',
        practiceAction: '按 planner、policy、executor、state、trace 顺序重写一次排查步骤。',
        retryPrompt: '如果 planner 选错工具或 policy 误拦截，你怎么定位并修复？',
        doneSignal: '能先定位 runtime 层，再讲具体检查数据和修复策略。',
      ),
      LearningAgentRuntimeMockInterviewRepairDrill(
        weakness: '追问时回答太长',
        reviewTarget: '追问应对、模拟面试轮次、模拟面试评分',
        practiceAction: '每个压力追问只保留两句：一句直接短答，一句证据或边界，再拉回主线。',
        retryPrompt: '这是不是只是页面流程，不算真正 agent？请 20 秒回答。',
        doneSignal: '短答能先回应质疑，再给证据或边界，不重新讲完整背景。',
      ),
    ],
    frameworkMappings: const [
      LearningAgentFrameworkMapping(
        framework: 'LangGraph',
        borrowedPattern: '状态图和可恢复执行',
        localComponent:
            'LearningAgentState + LearningAgentStateTransitionPolicy',
      ),
      LearningAgentFrameworkMapping(
        framework: 'OpenAI Agents SDK',
        borrowedPattern: '工具循环、guardrails、sessions 和 tracing',
        localComponent:
            'LearningAgentToolRegistry + LearningAgentExecutor + Trace',
      ),
      LearningAgentFrameworkMapping(
        framework: 'Parlant',
        borrowedPattern: '行为准则和来源边界',
        localComponent: 'LearningAgentPolicy source-grounding rules',
      ),
      LearningAgentFrameworkMapping(
        framework: 'AgentScope',
        borrowedPattern: '事件、权限意识和运行轨迹',
        localComponent:
            'LearningAgentTraceEvent + runtime contract diagnostics',
      ),
    ],
    frameworkSelections: const [
      LearningAgentRuntimeFrameworkSelection(
        framework: 'LangGraph',
        bestFit: '需要长任务状态图、checkpoint、分支恢复、人类参与和复杂 agent workflow。',
        whyNotNow:
            '当前已有 Flutter 本地单 session checkpoint/resume 和工具中断后的继续/结束决策，但还没有后端 graph runtime、分支恢复和任意节点审批。',
        adoptionPath:
            '先把 LearningAgentState 和 transition policy 抽成 graph node contract，再迁移到 LangGraph 后端。',
        interviewClaim: '我把状态和 trace 先按可迁移到 LangGraph 的边界设计，但没有把设计借鉴说成已接入。',
      ),
      LearningAgentRuntimeFrameworkSelection(
        framework: 'OpenAI Agents SDK',
        bestFit: '需要模型驱动的 tool loop、guardrails、sessions、handoff 和 tracing。',
        whyNotNow: '当前 executor 是确定性本地工具编排，还不需要开放式模型工具选择。',
        adoptionPath:
            '先补结构化 tool schema、重试和模型选择，再把 executor 替换为 Agents SDK 风格 loop。',
        interviewClaim: '我先复刻 tool、policy、trace contract，等工具链复杂后再接标准 SDK。',
      ),
      LearningAgentRuntimeFrameworkSelection(
        framework: 'Parlant',
        bestFit: '需要把 agent 行为准则、话术边界和业务 policy 显式化。',
        whyNotNow: '当前重点是学习来源正确性，policy 先落在 Dart 本地规则里。',
        adoptionPath:
            '把 LearningAgentPolicy 的来源约束、正式学习边界和导师边界整理成可配置 guideline。',
        interviewClaim: 'Parlant 更像我未来治理 agent 行为的参考，而不是当前 runtime 依赖。',
      ),
      LearningAgentRuntimeFrameworkSelection(
        framework: 'AgentScope',
        bestFit: '需要多 agent 实验、消息事件、权限意识和运行过程观测。',
        whyNotNow: '当前还是单用户本地学习 agent，没有多 agent 协作和远程事件总线。',
        adoptionPath:
            '保留 LearningAgentTraceEvent 作为事件语义，未来多 agent 化时再映射到 AgentScope 风格事件。',
        interviewClaim: '我借鉴它的事件和可观测思想，但现阶段先不引入多 agent 复杂度。',
      ),
    ],
    decisionRecords: const [
      LearningAgentRuntimeDecisionRecord(
        decision: '先做 Flutter/Dart 本地 runtime',
        rationale: '学习数据、页面流转和复盘都在 Flutter app 内，本地 contract 能最快闭合用户体验和来源正确性。',
        tradeoff: '暂时拿不到 LangGraph/Agents SDK 的后端持久执行、模型工具循环和生态组件。',
        interviewClaim:
            '这是分阶段架构：先让 state、tool、policy、trace 稳定，再把 executor 或 planner 替换成标准 agent 框架。',
      ),
      LearningAgentRuntimeDecisionRecord(
        decision: '先用确定性 planner + policy gate',
        rationale: '正式学习需要可解释、可阻断、可复盘，不能让模型自由连续行动后直接改学习材料。',
        tradeoff: '当前自治程度有限，更多像受控学习编排，而不是开放式 autonomous agent。',
        interviewClaim: '我把自主性放在来源约束之后，先保证学习 agent 不会牺牲正确性。',
      ),
      LearningAgentRuntimeDecisionRecord(
        decision: '先做 source-grounded learning，再升级 RAG',
        rationale: '项目目标是学得正确，所以先建立 source chunks、verified questions 和引用约束。',
        tradeoff: '当前检索还不是 embedding/vector retrieval，复杂语义召回能力有限。',
        interviewClaim: '这个顺序能让后续向量检索只替换检索层，不破坏来源核验和正式学习规则。',
      ),
      LearningAgentRuntimeDecisionRecord(
        decision: '优先把 trace 和诊断做成一等能力',
        rationale: '面试复盘、失败定位和未来 resume 都需要知道 agent 为什么选择某个工具。',
        tradeoff: '前期代码会多一些 contract 和 formatter，但换来更强的可解释性。',
        interviewClaim: 'trace-first 让这个 agent 不是黑盒跳转，而是能说明、能复盘、能迁移的 runtime。',
      ),
      LearningAgentRuntimeDecisionRecord(
        decision: 'checkpoint 使用 revision 乐观并发控制',
        rationale: '事务原子性只能避免半份 checkpoint，无法阻止旧页面或重复决策覆盖更新后的 state/trace。',
        tradeoff: '发生冲突时先拒绝并刷新最新会话，不自动合并两个执行分支。',
        interviewClaim:
            '我用 expected revision 的条件更新把 stale write 变成显式冲突，而不是 last-write-wins。',
      ),
      LearningAgentRuntimeDecisionRecord(
        decision: '先持久化 tool_started，再允许工具副作用',
        rationale:
            '只有 plan checkpoint 时，进程可能在工具已经启动后退出，却没有 durable trace 说明调用已经越过边界。',
        tradeoff:
            '每次工具启动会增加一次 checkpoint 写入；如果进程在工具启动后、结果保存前退出，会进入人工 unknown-outcome 恢复。',
        interviewClaim:
            '我把 durable write 放在真实工具调用之前，写入失败就不启动工具，但不把它夸成 exactly-once。',
      ),
      LearningAgentRuntimeDecisionRecord(
        decision: '未知工具结果由用户显式协调，不自动重试',
        rationale: '超时或进程退出后，调用方可能不知道副作用是否已经发生；没有服务端幂等契约时自动重试可能重复执行。',
        tradeoff: '恢复需要用户判断实际结果，交互成本高于自动重试；operation/attempt 身份只支持关联和审计。',
        interviewClaim:
            '我区分稳定 operation identity 和逐次变化的 attempt identity；等工具端真正消费幂等键后再开放安全自动重试。',
      ),
      LearningAgentRuntimeDecisionRecord(
        decision: '同一 operation 的重试必须保持 routing input 一致',
        rationale:
            '复用 request identity 却改变参数表示新的意图；AWS 和 Stripe 的正式幂等契约都会拒绝这种用法。',
        tradeoff:
            '当前只比较 tool、target、focus 和 evidence ids，页面内部后续读取的数据还不在 snapshot 中。',
        interviewClaim:
            '我先用可读 input snapshot 拒绝已知参数漂移，但把完整请求校验和结果缓存留给真正的工具端幂等层。',
      ),
    ],
    boundaryNotes: const [
      LearningAgentRuntimeBoundaryNote(
        topic: '自治程度',
        currentBoundary: '当前是确定性 planner + executor 工具编排，不让模型自由连续行动。',
        interviewClaim: '我先把 agent contract 做可靠，再逐步替换 planner 或 executor。',
      ),
      LearningAgentRuntimeBoundaryNote(
        topic: '恢复能力',
        currentBoundary:
            '当前已有 SQLite v12 checkpoint、revision 乐观并发控制、plan snapshot、durable tool_started checkpoint、operation/attempt 身份和 routing-input snapshot。',
        interviewClaim:
            '工具调用边界和 unknown-outcome 人工协调已经实现；但工具内部进度、服务端幂等键、安全自动重试、自动 merge 和分支回放仍是后续能力。',
      ),
      LearningAgentRuntimeBoundaryNote(
        topic: '知识检索',
        currentBoundary: '当前使用本地 source chunks 和可核验题目，还没有引入向量数据库或远程 RAG。',
        interviewClaim: '本地来源闭环先保证正确性，未来可把检索实现替换成 vector retrieval。',
      ),
      LearningAgentRuntimeBoundaryNote(
        topic: '框架依赖',
        currentBoundary: '当前借鉴 LangGraph/Agents SDK 等框架思想，但没有直接接入外部 agent 框架。',
        interviewClaim: '这是为了保持 Flutter 本地优先，同时保留后续迁移到后端框架的边界。',
      ),
    ],
    maturityLevels: const [
      LearningAgentRuntimeMaturityLevel(
        level: 'Level 1：受控学习编排器',
        implementedSignal:
            '已有 planner、tool registry、policy gate、executor、trace、工具调用前 durable checkpoint 和未知结果人工恢复，把学习动作编排成可解释流程。',
        missingCapability:
            '还没有模型自由选择工具、连续自主行动、工具内部进度 checkpoint、服务端幂等自动重试或分支回放。',
        nextMilestone:
            '补结构化工具输入输出、服务端 idempotency contract、失败重试和工具内部 checkpoint。',
        interviewClaim: '当前是可靠的本地学习 runtime，而不是开放式 autonomous agent。',
      ),
      LearningAgentRuntimeMaturityLevel(
        level: 'Level 2：来源约束学习 agent',
        implementedSignal:
            '已有 source chunks、verified questions、formal learning policy 和引用约束。',
        missingCapability:
            '还没有 embedding index、vector retrieval、citation rerank 或远程 RAG 服务。',
        nextMilestone: '在保留 source-grounding contract 的前提下升级检索层。',
        interviewClaim: '我先把正确性和来源闭环做好，再把召回能力升级成真正 RAG。',
      ),
      LearningAgentRuntimeMaturityLevel(
        level: 'Level 3：可恢复状态图 runtime',
        implementedSignal:
            '已有 LearningAgentState、SQLite v12 revision checkpoint、版本化 plan/decision/input snapshot、ResumePolicy、durable tool-start boundary 和 operation/attempt 两层身份。',
        missingCapability:
            '还没有工具内部进度 checkpoint、外部结果自动核验、幂等执行、任意 graph node 审批、分支回放或真正 graph node 执行入口。',
        nextMilestone: '把状态迁移抽成 graph node contract，并增加节点级 checkpoint 和分支恢复。',
        interviewClaim: '状态设计已经为 LangGraph 风格迁移留好边界，但当前还没宣称已接入。',
      ),
      LearningAgentRuntimeMaturityLevel(
        level: 'Level 4：可评估 agent 系统',
        implementedSignal: '已有 trace event、diagnostic lines 和可复制的运行轨迹。',
        missingCapability: '还没有 trace replay、质量指标、批量评估和跨 session 对比。',
        nextMilestone: '把 trace 升级成 replay + evaluation，用数据判断 agent 决策质量。',
        interviewClaim: '当系统进入规模化使用时，我会用 trace-first 基础做 agent evaluation。',
      ),
    ],
    pitfalls: const [
      LearningAgentRuntimePitfall(
        riskyClaim: '我已经接入 LangGraph 或 OpenAI Agents SDK。',
        saferClaim:
            '我借鉴了 LangGraph 的状态图和 OpenAI Agents SDK 的工具循环，但当前实现是 Flutter/Dart 本地 runtime。',
        reason:
            '避免把架构借鉴说成真实依赖，面试时要区分 design reference 和 production dependency。',
      ),
      LearningAgentRuntimePitfall(
        riskyClaim: '这是一个完全自治、能自由连续行动的 agent。',
        saferClaim:
            '当前是确定性 planner + executor 工具编排，先把 state、tool、policy、trace contract 做可靠。',
        reason: '当前没有开放式自主行动循环，这样说更符合本地优先和可控学习流程。',
      ),
      LearningAgentRuntimePitfall(
        riskyClaim: '项目已经有完整 RAG 或向量数据库。',
        saferClaim:
            '当前使用本地 source chunks、引用核验和来源约束，未来可以替换检索层接入 vector retrieval。',
        reason: '避免把 source-grounded learning 夸成完整向量检索系统。',
      ),
      LearningAgentRuntimePitfall(
        riskyClaim: 'AI 生成内容可以直接进入正式学习。',
        saferClaim:
            'AI 输出只作为草稿，正式学习必须经过 verified questions、source chunks 和 policy gate。',
        reason: '这能突出项目对正确性和来源依据的重视。',
      ),
      LearningAgentRuntimePitfall(
        riskyClaim: '工具调用已经具备 exactly-once。',
        saferClaim:
            '当前在 tool_started 前保存 operation/attempt 和 routing-input snapshot，并拒绝已知输入漂移；仍没有服务端结果缓存与重复副作用抑制。',
        reason: '客户端只覆盖结构化 routing input，未来远程工具还必须校验完整请求并按 key 保存、重放结果。',
      ),
    ],
    evolutionSteps: const [
      LearningAgentRuntimeEvolutionStep(
        milestone: '1. 状态图标准化',
        currentFoundation:
            '已有 LearningAgentState、transition policy、SQLite v12 revision checkpoint、operation/attempt/input snapshot、基础 HITL 和 unknown-outcome 人工恢复。',
        nextUpgrade:
            '把状态迁移抽成可替换 graph node contract，并补服务端幂等键、工具内部 checkpoint 与分支回放。',
        interviewClaim: '当前不是直接接 LangGraph，但状态边界已经按可迁移到状态图的方式设计。',
      ),
      LearningAgentRuntimeEvolutionStep(
        milestone: '2. 工具循环增强',
        currentFoundation:
            '已有 ToolRegistry、Executor、Policy gate 和 trace 记录工具执行。',
        nextUpgrade: '加入模型选择、结构化工具输入输出和失败重试策略，再考虑迁移到 Agents SDK 风格后端。',
        interviewClaim:
            '我先在 Flutter 本地复刻工具循环 contract，后续能把 executor 替换成标准 agent loop。',
      ),
      LearningAgentRuntimeEvolutionStep(
        milestone: '3. 来源检索升级',
        currentFoundation:
            '已有 source chunks、verified questions 和 formal learning policy。',
        nextUpgrade: '在本地来源闭环稳定后，再加入 embedding index 或 vector retrieval。',
        interviewClaim: '先保证来源正确性和引用约束，再把检索层升级成真正 RAG。这个顺序更稳。',
      ),
      LearningAgentRuntimeEvolutionStep(
        milestone: '4. 可观测复盘',
        currentFoundation:
            '已有 LearningAgentTraceEvent、diagnostic lines 和可复制 trace 文本。',
        nextUpgrade: '增加 session replay、失败路径复盘和跨学习目标的 trace 汇总。',
        interviewClaim: 'trace-first 让 agent 行为可解释，也为以后接入更重框架保留调试依据。',
      ),
    ],
    migrationTriggers: const [
      LearningAgentRuntimeMigrationTrigger(
        trigger: '需要恢复长工具和分支任务',
        currentSignal:
            '已有本地单 session revision checkpoint、plan snapshot、ResumePolicy、工具中断决策、跨重启恢复入口、工具调用前 durable checkpoint 和未知结果人工协议，但没有工具内部进度或服务端幂等协议。',
        upgradeAction:
            '把状态迁移抽成 graph node contract，增加节点级 checkpoint、任意节点审批和 LangGraph 风格分支恢复。',
        interviewClaim: '当学习任务需要跨天恢复和分支回放时，我会把本地 state machine 升级成真正可恢复的状态图。',
      ),
      LearningAgentRuntimeMigrationTrigger(
        trigger: '工具数量和失败路径明显增多',
        currentSignal: 'ToolRegistry 和 Executor 已经集中工具元数据、policy gate 和 trace。',
        upgradeAction: '加入结构化工具 schema、重试策略和模型选择，再迁移到 Agents SDK 风格 tool loop。',
        interviewClaim: '当工具链复杂到需要统一重试、handoff 和 tracing 时，就值得引入标准 agent loop。',
      ),
      LearningAgentRuntimeMigrationTrigger(
        trigger: '来源语义召回成为瓶颈',
        currentSignal: '当前依靠 source chunks、verified questions 和显式引用保证正确性。',
        upgradeAction:
            '在不放松来源约束的前提下增加 embedding index、vector retrieval 和 citation rerank。',
        interviewClaim:
            '我会先保留 source-grounding contract，再替换检索层，而不是为了 RAG 牺牲可核验性。',
      ),
      LearningAgentRuntimeMigrationTrigger(
        trigger: '需要比较多轮 agent 决策质量',
        currentSignal: '已有 trace event、diagnostic lines 和复制 trace 文本。',
        upgradeAction:
            '增加 trace replay、质量指标和跨 session 评估，再接入更成熟的 observability 工具。',
        interviewClaim: '当问题从“能不能执行”变成“执行得好不好”时，trace 数据就可以升级成评估系统。',
      ),
    ],
    codeWalkthroughSteps: const [
      LearningAgentRuntimeCodeWalkthroughStep(
        step: '1. 入口页面如何准备 Agent Session',
        fileReference: 'lib/features/agent/agent_session_launch_screen.dart',
        whatToShow:
            '页面读取 plan、准备 runtime session、展示 runtime 面试卡，并通过 executor 启动本地工具。',
        interviewNarration:
            '我会先从 UI 入口讲起，说明页面不直接写散业务逻辑，而是把启动交给 runtime provider 和 executor。',
      ),
      LearningAgentRuntimeCodeWalkthroughStep(
        step: '2. Planner 如何选择下一步学习动作',
        fileReference: 'lib/services/agent/learning_agent_planner_service.dart',
        whatToShow: 'Planner 根据目标、知识状态、历史追问和 session summary 生成下一步计划。',
        interviewNarration: '这里说明 agent 的“决策入口”是受控 planner，不是让模型自由行动。',
      ),
      LearningAgentRuntimeCodeWalkthroughStep(
        step: '3. Tool registry 如何声明能力边界',
        fileReference: 'lib/services/agent/learning_agent_tool_registry.dart',
        whatToShow: 'Tool definition 把导入、核验、导师、面试、练习、复习等能力声明成统一元数据。',
        interviewNarration: '这一段用来解释为什么 UI 不需要到处 switch，工具能力先被 contract 化。',
      ),
      LearningAgentRuntimeCodeWalkthroughStep(
        step: '4. Policy gate 如何守住来源正确性',
        fileReference: 'lib/services/agent/learning_agent_policy.dart',
        whatToShow: 'Policy 集中检查正式学习、导师、面试和引用证据要求，阻断无依据流程。',
        interviewNarration: '我会强调这个项目把正确性放在自主性前面，AI 输出不能绕过来源约束。',
      ),
      LearningAgentRuntimeCodeWalkthroughStep(
        step: '5. Executor 如何执行工具并记录结果',
        fileReference: 'lib/services/agent/learning_agent_executor.dart',
        whatToShow:
            'Executor 读取 tool metadata，经过 policy gate 后记录 tool_started，并要求 callback 持久化成功后才进入工具 switch。',
        interviewNarration:
            '这里是 tool loop 的本地版本，durable write 位于真实调用之前；未来可以替换成 Agents SDK 风格 executor。',
      ),
      LearningAgentRuntimeCodeWalkthroughStep(
        step: '6. State 和 trace 如何支持复盘与迁移',
        fileReference:
            'lib/services/agent/learning_agent_state.dart + lib/services/agent/learning_agent_trace.dart',
        whatToShow:
            'State 保存 phase、tool、evidence、policy warnings；Trace 记录选择、阻断和执行事件。',
        interviewNarration:
            '最后用 state 和 trace 收束，说明系统不是黑盒跳转，而是可解释、可复盘、可迁移的 runtime。',
      ),
      LearningAgentRuntimeCodeWalkthroughStep(
        step: '7. Checkpoint 如何支持跨重启恢复',
        fileReference:
            'lib/data/database/database_helper.dart + lib/services/agent/learning_agent_checkpoint_store.dart + lib/services/agent/learning_agent_runtime.dart + lib/features/agent/agent_session_launch_screen.dart',
        whatToShow:
            'Checkpoint 原子保存 state、顺序 trace 和版本化 plan snapshot；tool_started 同时保存 operation、attempt、routing input 和 unknown-outcome request。',
        interviewNarration:
            '这一段说明恢复沿用原 session 和计划，工具调用前必须先保存最新 revision；未配对结果交给用户协调，冲突则刷新会话而不是静默覆盖。',
      ),
    ],
    debugScenarios: const [
      LearningAgentRuntimeDebugScenario(
        scenario: 'Planner 选择了错误工具',
        likelyCause:
            'readiness 或 memory 输入过期、可用步骤顺序不符合目标，或者 sessionSummary.nextStep 与 ToolRegistry 映射没有保持一致。',
        inspectionPath:
            '先看 learning_agent_planner_service.dart 的 buildPlan、_firstEnabledStep 和 startBlockReason，再看 learning_agent_tool_registry.dart 的 toolForStep。',
        fixStrategy:
            '固定同一组 planner 输入复现，核对第一个 enabled step、session summary 和 tool metadata；修正输入计算或单一映射，不在 UI 临时改选工具。',
        interviewClaim:
            '我会先验证决策输入和 step-to-tool contract，再修 planner 或 registry，而不是在页面层掩盖错误选择。',
      ),
      LearningAgentRuntimeDebugScenario(
        scenario: 'Policy gate 误拦截合法流程',
        likelyCause:
            'executor 在检查前没有加载完整 target、evidence chunks 或 verified questions，也可能是 policy issue code 对当前步骤定义得过宽。',
        inspectionPath:
            '从 learning_agent_executor.dart 的 _checkPolicyBeforeExecution 跟到 learning_agent_policy.dart 的 checkStep，并核对 policy_checked trace 的 issue codes。',
        fixStrategy:
            '先确认传入 policy 的真实数据，再针对具体 issue code 修复加载或规则；保留 gate，不用直接跳过来源检查。',
        interviewClaim:
            '调试 guardrail 时我先区分“输入缺失”和“规则错误”，避免为了通过流程而破坏 source-grounding。',
      ),
      LearningAgentRuntimeDebugScenario(
        scenario: 'Executor 启动或完成工具失败',
        likelyCause:
            'step 没有匹配 tool metadata、导航分支抛出异常、用户取消被误判，或工具结果没有正确进入完成复盘。',
        inspectionPath:
            '检查 learning_agent_executor.dart 的 execute 分支和 LearningAgentExecutionResult，再按 tool_selected、policy_checked、tool_started、tool_completed 或 tool_failed trace 定位断点。',
        fixStrategy:
            '保留失败诊断和 trace，逐个 step 验证工具映射、启动参数、取消状态和完成状态，不把异常统一吞成普通返回。',
        interviewClaim: 'Executor 是统一故障边界，我用结构化结果和事件时间线定位失败，而不是让每个页面各自处理异常。',
      ),
      LearningAgentRuntimeDebugScenario(
        scenario: 'Runtime state 和 trace 不一致',
        likelyCause:
            '事件绕过 LearningAgentTraceRecorder 写入、phase transition 选择错误，或已有事件没有合并进 state.traceEventIds。',
        inspectionPath:
            '检查 learning_agent_trace.dart 的 LearningAgentTraceRecorder.record、learning_agent_state_transition_policy.dart 和 learning_agent_state.dart 的 transitionTo。',
        fixStrategy:
            '让所有事件统一经过 recorder，并对照事件 phase、state phase、traceEventIds 和 evidenceChunkIds；状态迁移只由 transition policy 决定。',
        interviewClaim: '我把 state 与 trace 当作同一次原子记录来调试，保证运行状态和可观测事件能互相解释。',
      ),
      LearningAgentRuntimeDebugScenario(
        scenario: '来源引用或 evidence IDs 不完整',
        likelyCause:
            'focus point 对应的 source chunks 没有加载完整、question citation IDs 已失效，或 policy snapshot 的证据没有传入 trace recorder。',
        inspectionPath:
            '从 learning_agent_executor.dart 的证据加载和 _PolicyCheckSnapshot，跟到 learning_agent_policy.dart 的 evidence 检查，再比较 state 与 trace 的 evidenceChunkIds。',
        fixStrategy:
            '核验 target、source chunk 和 citation ID 的关联，过滤不存在的引用并要求重新核验；确认 policy、state、trace 使用同一组有效 evidence IDs。',
        interviewClaim:
            '来源问题不能靠补一段模型解释解决，我会沿 ID 链路验证证据从存储、policy 到 trace 是否完整传递。',
      ),
    ],
    demoSteps: const [
      LearningAgentRuntimeDemoStep(
        moment: '1. 从 Agent 目标入口开始',
        appAction: '打开 Agent tab，展示当前目标、下一步 Agent Session 和可执行状态。',
        narration: '我先说明它不是自由聊天入口，而是围绕 AI 面试、项目讲解或编程学习目标生成受控学习计划。',
        proofPoint:
            '指向 session summary、next step 和 planner 输出，说明行动来自目标状态而不是临时按钮。',
      ),
      LearningAgentRuntimeDemoStep(
        moment: '2. 展示来源约束和证据覆盖',
        appAction: '在准备页展示证据覆盖摘要、来源约束提示和当前目标绑定的知识点。',
        narration:
            '这里强调正式学习必须依赖 source chunks、verified questions 和 policy gate，AI 草稿不能直接进入学习闭环。',
        proofPoint: '指向证据覆盖摘要、policy 约束文案和代码依据中的 learning_agent_policy.dart。',
      ),
      LearningAgentRuntimeDemoStep(
        moment: '3. 启动一次受控工具执行',
        appAction:
            '点击开始 Agent Session，让 executor 按 planner 选中的工具进入导师、面试、复习或核验流程。',
        narration:
            '我会说明 UI 不直接散落业务 switch，而是通过 ToolRegistry、Policy 和 Executor 组合成轻量 tool loop。',
        proofPoint:
            '指向工具执行结果、policy_checked trace 和 learning_agent_executor.dart。',
      ),
      LearningAgentRuntimeDemoStep(
        moment: '4. 展开代码走读和调试场景',
        appAction: '回到 runtime 面试卡，展开“代码走读路线”和“调试场景”。',
        narration: '这一步把面试讲法落到文件和故障排查，不只说概念，还能说明从 planner 到 trace 的真实实现路径。',
        proofPoint: '指向代码走读文件列表、调试场景排查路径和 evidence anchors。',
      ),
      LearningAgentRuntimeDemoStep(
        moment: '5. 用 trace 收束复盘',
        appAction: '完成或中断一次 session 后展示本轮 trace 和复盘保存入口。',
        narration:
            '最后说明这个 agent runtime 的核心价值是可解释、可复盘、可迁移，后续接 LangGraph 或 Agents SDK 时 trace 仍然有用。',
        proofPoint:
            '指向 LearningAgentTraceEvent、runtime state diagnostics 和完成复盘中的 trace 文本。',
      ),
    ],
    sourceGroundingChecks: const [
      LearningAgentRuntimeSourceGroundingCheck(
        check: 'AI 生成内容仍是草稿',
        verificationPath:
            '查看 ingestion review、KnowledgeReviewScreen 和 question sourceStatus，确认 AI 输出先进入待确认或核验流程。',
        passSignal: '知识点、题目和引用在人工确认前不会被当作 verified learning content。',
        failureResponse: '把入口退回 review 或 verification，不允许直接进入正式学习和面试材料。',
        interviewClaim: '我把模型输出当成候选材料，真正进入学习闭环前必须经过来源和人工核验。',
      ),
      LearningAgentRuntimeSourceGroundingCheck(
        check: '正式练习只使用有引用的已核验普通题或编程练习',
        verificationPath:
            '检查 LearningAgentPolicy.checkFormalPracticeQuestions、verified study providers 和 quiz entry availability。',
        passSignal: '未核验、无来源或缺引用题目会被 policy 或入口状态拦住。',
        failureResponse: '引导用户回到核验题目或补齐引用，而不是降低正式学习门槛。',
        interviewClaim: '正式练习是强约束路径，只有 verified questions 才能参与掌握度更新。',
      ),
      LearningAgentRuntimeSourceGroundingCheck(
        check: '导师和面试必须绑定来源片段',
        verificationPath:
            '检查 executor 的 _checkPolicyBeforeExecution、LearningAgentPolicy.checkEvidenceBoundAction 和准备页来源片段展示。',
        passSignal:
            'tutor/interview step 有 targetId 和 evidenceChunks；缺证据时返回阻断或补来源动作。',
        failureResponse: '先补 source chunks 或重新选择有证据知识点，再启动导师或面试。',
        interviewClaim: '我把解释和追问绑定到真实 source chunks，避免 agent 凭空发挥。',
      ),
      LearningAgentRuntimeSourceGroundingCheck(
        check: '引用 ID 能读到真实片段',
        verificationPath:
            '检查 question citationIds、SourceChunkRepository、LearningAgentPolicy.checkQuestionEvidence 和证据详情页。',
        passSignal: '每个 citation id 都能打开对应 source chunk，缺失 ID 会被识别为证据问题。',
        failureResponse: '过滤不存在引用、要求重新核验或回到来源导入修复 chunk 关系。',
        interviewClaim: 'source-grounding 不只存文字，还要保证 citation id 能追到可读来源片段。',
      ),
      LearningAgentRuntimeSourceGroundingCheck(
        check: '外部框架说法有官方来源',
        verificationPath:
            '检查 frameworkSourceReferences、verifiedAt、trustNote 和 docs/agent-runtime-architecture.md 的 Smart Search evidence 记录。',
        passSignal: '每条框架映射能对应官方文档、官方 SDK 文档或项目仓库，并标注核验日期。',
        failureResponse: '没有来源的框架说法降级为个人推测，不能放进正式面试材料。',
        interviewClaim: '我会把外部框架借鉴和本地实现分开，并给框架说法保留可追溯来源。',
      ),
    ],
    evidenceAnchors: const [
      LearningAgentRuntimeEvidenceAnchor(
        claim: 'Agent Session 有显式状态机',
        codeReference: 'lib/services/agent/learning_agent_state.dart',
        support:
            'LearningAgentState 记录 phase、tool、evidence、policy warnings 和 trace ids。',
      ),
      LearningAgentRuntimeEvidenceAnchor(
        claim: '工具执行从 UI switch 迁到 executor',
        codeReference: 'lib/services/agent/learning_agent_executor.dart',
        support: 'LearningAgentExecutor 负责 policy gate、工具启动、结果状态和 trace。',
      ),
      LearningAgentRuntimeEvidenceAnchor(
        claim: '来源约束集中在 policy 层',
        codeReference: 'lib/services/agent/learning_agent_policy.dart',
        support: 'LearningAgentPolicy 统一检查正式学习、导师、面试和引用证据要求。',
      ),
      LearningAgentRuntimeEvidenceAnchor(
        claim: '执行过程可追踪且可复制',
        codeReference: 'lib/services/agent/learning_agent_trace.dart',
        support: 'LearningAgentTraceEvent 和 trace formatter 统一记录 agent 决策轨迹。',
      ),
      LearningAgentRuntimeEvidenceAnchor(
        claim: '未完成 Agent Session 可以跨重启安全恢复',
        codeReference:
            'lib/services/agent/learning_agent_checkpoint_store.dart + lib/services/agent/learning_agent_plan_codec.dart + lib/services/agent/learning_agent_user_decision.dart + lib/services/agent/learning_agent_runtime.dart + lib/features/agent/agent_home_screen.dart',
        support:
            'SQLite checkpoint 保存 state、trace、plan snapshot 和单调 revision；ResumePolicy、兼容性检查与 conditional update 共同约束首页恢复入口。',
      ),
      LearningAgentRuntimeEvidenceAnchor(
        claim: '真实工具调用前存在 durable checkpoint 边界',
        codeReference:
            'lib/services/agent/learning_agent_executor.dart + lib/features/agent/agent_session_launch_screen.dart',
        support:
            'Executor 在 tool_started 后、工具 switch 前等待持久化 callback；Session 使用当前 revision 保存并把返回 revision 继续传给结果 checkpoint。',
      ),
      LearningAgentRuntimeEvidenceAnchor(
        claim: '未知工具结果使用 operation/attempt identity 和人工恢复',
        codeReference:
            'lib/services/agent/learning_agent_user_decision.dart + lib/services/agent/learning_agent_checkpoint.dart + lib/services/agent/learning_agent_runtime.dart + lib/features/agent/agent_home_screen.dart',
        support:
            'tool-start checkpoint 保存稳定 operation id 和关联 tool_started trace 的 attempt id；重试只复用 operation，不自动猜测副作用结果。',
      ),
      LearningAgentRuntimeEvidenceAnchor(
        claim: '同一 operation 的 routing input 变化会在工具启动前被拒绝',
        codeReference:
            'lib/services/agent/learning_agent_tool_input_snapshot.dart + lib/services/agent/learning_agent_executor.dart + lib/services/agent/learning_agent_checkpoint.dart',
        support:
            'snapshot 保存 tool/target/focus/evidence；executor 比较重试输入，checkpoint 校验 snapshot 与 state 一致。',
      ),
    ],
    frameworkSourceReferences: const [
      LearningAgentRuntimeSourceReference(
        title: 'LangGraph overview',
        reference: 'https://docs.langchain.com/oss/python/langgraph/overview',
        sourceType: '官方文档',
        supports: '状态图、持久执行、人类参与、memory 和 trace 的架构借鉴。',
        trustNote: 'LangChain 官方文档，适合引用状态图和持久执行概念。',
        verifiedAt: '2026-07-09',
        evidenceNote:
            '记录于 docs/agent-runtime-architecture.md；Smart Search evidence: C:\\tmp\\smart-search-evidence\\agent-architecture-anchor-learning。',
      ),
      LearningAgentRuntimeSourceReference(
        title: 'LangGraph checkpointers',
        reference:
            'https://docs.langchain.com/oss/python/langgraph/checkpointers',
        sourceType: '官方文档',
        supports: '按步骤保存 graph state、从最后成功步骤恢复，以及 pending writes 避免重跑已成功任务。',
        trustNote:
            'LangChain 官方文档，适合说明 checkpoint 边界、故障恢复和 pending writes；本项目只借鉴语义，不宣称等价实现。',
        verifiedAt: '2026-07-14',
        evidenceNote:
            'Smart Search fetch evidence: C:\\tmp\\smart-search-evidence\\agent-architecture-anchor-learning\\langgraph-checkpointers.md。',
      ),
      LearningAgentRuntimeSourceReference(
        title:
            'AWS Builders’ Library: Making retries safe with idempotent APIs',
        reference:
            'https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/',
        sourceType: '官方架构文档',
        supports:
            '说明 unknown outcome、caller-provided request identifier，以及同 request id 参数变化应作为 different intent 返回 validation error。',
        trustNote:
            'AWS Builders’ Library 官方文章，适合说明 unknown outcome、重复副作用风险和幂等 API 边界。',
        verifiedAt: '2026-07-14',
        evidenceNote:
            'Smart Search fetch evidence: C:\\tmp\\smart-search-evidence\\agent-architecture-anchor-learning\\aws-making-retries-safe.md。',
      ),
      LearningAgentRuntimeSourceReference(
        title: 'Stripe idempotent requests',
        reference: 'https://docs.stripe.com/api/idempotent_requests',
        sourceType: '官方 API 文档',
        supports: '说明同 idempotency key 返回首次结果，并比较后续请求参数；参数不一致时拒绝以防误用。',
        trustNote:
            'Stripe 官方 API 文档，适合对照真正的服务端 idempotency contract；本项目当前尚未实现该契约。',
        verifiedAt: '2026-07-14',
        evidenceNote:
            'Smart Search fetch evidence: C:\\tmp\\smart-search-evidence\\agent-architecture-anchor-learning\\stripe-idempotent-requests.md。',
      ),
      LearningAgentRuntimeSourceReference(
        title: 'OpenAI Agents SDK',
        reference: 'https://openai.github.io/openai-agents-python/',
        sourceType: '官方 SDK 文档',
        supports: 'agent loop、function tools、guardrails、sessions 和 tracing 术语。',
        trustNote: 'OpenAI Agents SDK 文档，适合引用工具循环和 tracing 术语。',
        verifiedAt: '2026-07-09',
        evidenceNote:
            '记录于 docs/agent-runtime-architecture.md；Smart Search evidence: C:\\tmp\\smart-search-evidence\\agent-architecture-anchor-learning。',
      ),
      LearningAgentRuntimeSourceReference(
        title: 'Parlant agentic design',
        reference: 'https://www.parlant.io/docs/production/agentic-design',
        sourceType: '项目文档',
        supports: 'guideline、journey 和可靠行为边界对 policy 层的启发。',
        trustNote: 'Parlant 项目文档，适合引用 guideline 和行为边界设计。',
        verifiedAt: '2026-07-09',
        evidenceNote:
            '记录于 docs/agent-runtime-architecture.md；Smart Search evidence: C:\\tmp\\smart-search-evidence\\agent-architecture-anchor-learning。',
      ),
      LearningAgentRuntimeSourceReference(
        title: 'AgentScope GitHub',
        reference: 'https://github.com/agentscope-ai/agentscope',
        sourceType: '项目仓库',
        supports: '事件、权限、多 session、RAG 和 middleware 能力边界参考。',
        trustNote: 'AgentScope 项目仓库，适合引用事件、多 session 和工具边界能力。',
        verifiedAt: '2026-07-09',
        evidenceNote:
            '记录于 docs/agent-runtime-architecture.md；Smart Search evidence: C:\\tmp\\smart-search-evidence\\agent-architecture-anchor-learning。',
      ),
      LearningAgentRuntimeSourceReference(
        title: 'SQLite transaction and UPDATE',
        reference: 'https://www.sqlite.org/lang_transaction.html',
        sourceType: '官方数据库文档',
        supports: '事务原子读写、单写事务，以及条件 UPDATE 零行命中的冲突判定基础。',
        trustNote: 'SQLite 官方文档，适合说明 transaction 与 conditional update 语义。',
        verifiedAt: '2026-07-14',
        evidenceNote:
            'Smart Search fetch evidence: C:\\tmp\\smart-search-evidence\\agent-architecture-anchor-learning\\sqlite-transactions.md 与 sqlite-update.md。',
      ),
    ],
    prompts: [
      const LearningAgentInterviewPrompt(
        question:
            '为什么你没有直接接入 LangGraph 或 Python agent 框架，而是先做 Flutter 本地 runtime？',
        outline:
            '先讲本地优先和 SQLite 数据已在 Flutter 内，再讲用状态机、工具注册、policy 和 trace 复刻核心 agent contract，最后说明未来可迁移执行层。',
        sampleAnswer:
            '我没有一开始接 Python 框架，是因为这个 app 的数据、页面和学习流程都已经在 Flutter 本地侧，先把 agent 的 contract 做清楚更重要。'
            '现在我借鉴 LangGraph 的状态图、OpenAI Agents SDK 的工具循环、Parlant 的规则约束和 AgentScope 的事件 trace，但实现保持 Dart 本地优先。',
        selfCheck: '答到本地优先、复刻 agent contract、暂不引入重后端、未来可迁移四点，算合格。',
        evidenceHint:
            '引用 docs/agent-runtime-architecture.md 的框架取舍，以及 learning_agent_runtime_contracts.dart 的本地 runtime contract。',
      ),
      const LearningAgentInterviewPrompt(
        question: '如果面试官问“这个 agent 怎样避免胡说”，你如何用 policy 和来源约束回答？',
        outline:
            '强调正式学习必须使用 verified questions，导师/面试必须绑定 source chunks，AI 输出只作为草稿，trace 会记录证据和策略问题。',
        sampleAnswer:
            '我把防幻觉放在 policy 和来源链路里，而不是只靠 prompt。正式练习必须使用有引用的已核验普通题或编程练习，导师和面试必须绑定 source chunks，缺证据时就阻断或提示补来源。'
            'AI 生成内容只作为草稿，trace 会记录它用了哪些证据、被哪些策略检查过。',
        selfCheck:
            '答到 policy gate、verified questions、source chunks、AI 草稿和 trace 记录，算合格。',
        evidenceHint:
            '引用 learning_agent_policy.dart、来源片段约束和 Parlant guideline 对 policy 层的启发。',
      ),
      LearningAgentInterviewPrompt(
        question:
            '请用 $toolLabel 举例说明 executor、tool registry 和 UI provider 的边界。',
        outline:
            'tool registry 描述能力和证据要求，provider 暴露 executor 抽象，executor 做 policy gate 后启动本地页面或工具。',
        sampleAnswer:
            '以“$toolLabel”为例，tool registry 只声明这个工具是什么、需要什么证据、对应哪个学习步骤；provider 负责把 executor 暴露给 UI；executor 才真正做 policy gate、生成 trace，并决定是否启动页面或返回阻断原因。'
            '这样 UI 不需要知道每个工具的执行细节。',
        selfCheck:
            '答到 registry 描述能力、provider 提供依赖、executor 执行策略和 UI 不承载业务分发，算合格。',
        evidenceHint:
            '引用 learning_agent_tool_registry.dart、learning_agent_executor.dart 和 learning_agent_providers.dart。',
      ),
      const LearningAgentInterviewPrompt(
        question:
            '如果一次 Agent Session 中断，你会怎样用 state、trace 和 resume readiness 解释恢复方案？',
        outline:
            'checkpoint 原子保存 state、trace、plan 和 revision；工具前保存 operation/attempt/input；重试先校验 input，再创建新 attempt。',
        sampleAnswer:
            '我把 state、顺序 trace、plan snapshot 和单调 revision 原子写入 SQLite。Policy 通过后先保存 tool_started、稳定 operation id、单次 attempt id 和可读 routing-input snapshot。重试复用 operation，但先比较 tool、target、focus 和 evidence；不一致就记录 tool_input_rejected，真实工具不会启动。'
            '这仍只是客户端防线：snapshot 不是完整远程请求体，工具端也没有按 key 保存和重放结果，所以我仍要求人工协调，不声称 exactly-once。',
        selfCheck:
            '答到 durable boundary、operation/attempt/input 三层契约、参数漂移拒绝和服务端幂等边界，算合格。',
        evidenceHint:
            '引用 executor 的 tool-start callback、user decision/checkpoint invariant、database_helper.dart，以及 LangGraph、AWS 和 Stripe 官方资料。',
      ),
      const LearningAgentInterviewPrompt(
        question: '这套 runtime 以后要迁移到后端或接入向量检索，哪些 contract 可以保持不变？',
        outline:
            'planner 输出、tool metadata、policy 规则、state phase、trace event 和 resume readiness 都可保持，替换的是具体 tool executor。',
        sampleAnswer:
            '我会尽量保持 planner 输出、tool metadata、policy 规则、state phase、trace event 和 resume readiness 不变，因为这些是 agent 的契约。'
            '未来迁移到后端或加入向量检索时，主要替换 tool executor 和检索实现，而不是推翻用户看到的学习流程和证据规则。',
        selfCheck: '答到 contract 保持不变、替换 executor/检索实现、用户学习流程和证据规则不被推翻，算合格。',
        evidenceHint:
            '引用 planner、tool metadata、policy、state、trace contract，以及 LangGraph/OpenAI Agents SDK 外部来源。',
      ),
    ],
    sourceNotes: const [
      '依据: learning_agent_runtime_contracts.dart',
      '依据: docs/agent-runtime-architecture.md',
      '外部依据: LangGraph checkpointers，Smart Search 于 2026-07-14 核验。',
      '外部依据: AWS Builders’ Library 与 Stripe idempotent requests，Smart Search 于 2026-07-14 核验。',
    ],
  );
}

LearningAgentToolDefinition? _toolForPlan(
  LearningAgentPlan plan,
  LearningAgentState? state,
  LearningAgentToolRegistry toolRegistry,
) {
  final stateToolId = state?.selectedToolId;
  if (stateToolId != null && stateToolId.isNotEmpty) {
    final tool = toolRegistry.toolForIdValue(stateToolId);
    if (tool != null) return tool;
  }
  final nextStep = plan.sessionSummary.nextStep;
  if (nextStep == null) return null;
  return toolRegistry.toolForStep(nextStep.type);
}

int _traceEvidenceCount(List<LearningAgentTraceEvent> traceEvents) {
  return traceEvents
      .expand((event) => event.evidenceChunkIds)
      .where((id) => id.isNotEmpty)
      .toSet()
      .length;
}
