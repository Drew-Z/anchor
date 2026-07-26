import 'learning_agent_planner_service.dart';
import 'learning_agent_resume_policy.dart';
import 'learning_agent_state.dart';
import 'learning_agent_tool_registry.dart';
import 'learning_agent_trace.dart';

List<String> learningAgentRuntimeContractChecklistLines({
  LearningAgentPlan? plan,
  LearningAgentState? state,
  LearningAgentToolDefinition? selectedTool,
  List<LearningAgentTraceEvent> traceEvents = const [],
  LearningAgentResumePolicy resumePolicy = const LearningAgentResumePolicy(),
}) {
  final readiness = resumePolicy.evaluate(state, selectedTool: selectedTool);
  final tool = selectedTool ?? _toolFromState(state);
  final evidenceRequirement = tool?.evidenceRequirement.label ?? '未记录';
  final stateEvidenceCount = state?.evidenceChunkIds.length;
  final traceEvidenceCount = _traceEvidenceCount(traceEvents);
  final evidenceCount = stateEvidenceCount == null || stateEvidenceCount == 0
      ? traceEvidenceCount
      : stateEvidenceCount;
  final traceCount = traceEvents.isEmpty
      ? state?.traceEventIds.length ?? 0
      : traceEvents.length;

  return [
    'Agent Runtime Contract:',
    'Contract 状态模型: ${state == null ? '未绑定' : state.phase.label}',
    'Contract 学习目标: ${plan?.goal.label ?? state?.goal.label ?? '未记录'}',
    'Contract 工具: ${tool == null ? '未匹配' : '${tool.title} (${tool.toolId})'}',
    'Contract 来源约束: $evidenceRequirement',
    'Contract 证据上下文: $evidenceCount',
    'Contract Trace: $traceCount',
    'Contract Resume: ${readiness.status.label} / ${readiness.canResume ? '可恢复' : '不可恢复'}',
    'Contract Provider 边界: runtime/executor provider',
    'Contract Feature 入口: learning_agent_runtime_contracts.dart',
  ];
}

bool isLearningAgentRuntimeContractChecklistLine(String line) {
  return line.startsWith('Agent Runtime Contract:') ||
      line.startsWith('Contract 状态模型:') ||
      line.startsWith('Contract 学习目标:') ||
      line.startsWith('Contract 工具:') ||
      line.startsWith('Contract 来源约束:') ||
      line.startsWith('Contract 证据上下文:') ||
      line.startsWith('Contract Trace:') ||
      line.startsWith('Contract Resume:') ||
      line.startsWith('Contract Provider 边界:') ||
      line.startsWith('Contract Feature 入口:');
}

LearningAgentToolDefinition? _toolFromState(LearningAgentState? state) {
  final toolId = state?.selectedToolId;
  if (toolId == null || toolId.isEmpty) return null;
  return const LearningAgentToolRegistry().toolForIdValue(toolId);
}

int _traceEvidenceCount(List<LearningAgentTraceEvent> traceEvents) {
  return traceEvents
      .expand((event) => event.evidenceChunkIds)
      .where((id) => id.isNotEmpty)
      .toSet()
      .length;
}
