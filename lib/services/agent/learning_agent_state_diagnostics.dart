import 'learning_agent_state.dart';
import 'learning_agent_tool_registry.dart';

List<String> learningAgentStateDiagnosticLines(
  LearningAgentState? state, {
  LearningAgentToolDefinition? selectedTool,
  LearningAgentToolRegistry toolRegistry = const LearningAgentToolRegistry(),
}) {
  if (state == null) return const ['Agent 状态: 未记录'];

  return [
    'Agent 阶段: ${state.phase.label}',
    'Agent 工具: ${_selectedToolLabel(state, selectedTool, toolRegistry)}',
    'Agent 可用工具: ${state.availableToolIds.length}',
    'Agent 证据片段: ${state.evidenceChunkIds.length}',
    'Agent 策略警告: ${_listCountLabel(state.policyWarnings)}',
    'Agent Trace 事件: ${state.traceEventIds.length}',
    if (state.targetId != null && state.targetId!.isNotEmpty)
      'Agent 目标 ID: ${state.targetId}',
    if (state.focusPointId != null && state.focusPointId!.isNotEmpty)
      'Agent 焦点 ID: ${state.focusPointId}',
    if (state.activeToolOperationId != null)
      'Agent 工具 operation: ${state.activeToolOperationId}',
    if (state.activeToolInputSnapshot != null)
      'Agent 工具输入: ${state.activeToolInputSnapshot!.toStorageValue()}',
    if (state.pendingUserDecision != null)
      'Agent 待决策: ${state.pendingUserDecision!.prompt}',
    if (state.pendingUserDecision != null)
      'Agent 待决策原因: ${state.pendingUserDecision!.reason.label}',
    if (state.pendingUserDecision?.attemptId != null)
      'Agent 工具 attempt: ${state.pendingUserDecision!.attemptId}',
  ];
}

bool isLearningAgentStateDiagnosticLine(String line) {
  return line.startsWith('Agent 状态:') ||
      line.startsWith('Agent 阶段:') ||
      line.startsWith('Agent 工具:') ||
      line.startsWith('Agent 可用工具:') ||
      line.startsWith('Agent 证据片段:') ||
      line.startsWith('Agent 策略警告:') ||
      line.startsWith('Agent Trace 事件:') ||
      line.startsWith('Agent 目标 ID:') ||
      line.startsWith('Agent 焦点 ID:') ||
      line.startsWith('Agent 工具 operation:') ||
      line.startsWith('Agent 工具输入:') ||
      line.startsWith('Agent 待决策:') ||
      line.startsWith('Agent 待决策原因:') ||
      line.startsWith('Agent 工具 attempt:');
}

String _selectedToolLabel(
  LearningAgentState state,
  LearningAgentToolDefinition? selectedTool,
  LearningAgentToolRegistry toolRegistry,
) {
  final tool = selectedTool ??
      (state.selectedToolId == null
          ? null
          : toolRegistry.toolForIdValue(state.selectedToolId!));
  if (tool != null) return '${tool.title} (${tool.toolId})';
  return state.selectedToolId ?? '未记录';
}

String _listCountLabel(List<String> values) {
  if (values.isEmpty) return '无';
  return '${values.length} (${values.join('、')})';
}
