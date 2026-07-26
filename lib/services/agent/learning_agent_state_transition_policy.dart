import 'learning_agent_policy.dart';
import 'learning_agent_state.dart';
import 'learning_agent_user_decision.dart';

class LearningAgentStateTransitionPolicy {
  const LearningAgentStateTransitionPolicy();

  LearningAgentPhase afterPolicyCheck(LearningAgentPolicyResult result) {
    return result.isAllowed
        ? LearningAgentPhase.verify
        : LearningAgentPhase.blocked;
  }

  LearningAgentPhase afterToolStarted() {
    return LearningAgentPhase.act;
  }

  LearningAgentPhase afterToolResult({
    required bool isCanceled,
    required bool shouldShowCompletionReview,
  }) {
    if (isCanceled) return LearningAgentPhase.act;
    return shouldShowCompletionReview
        ? LearningAgentPhase.reflect
        : LearningAgentPhase.complete;
  }

  LearningAgentPhase afterToolFailure() {
    return LearningAgentPhase.blocked;
  }

  LearningAgentPhase afterUserDecision(
    LearningAgentPhase currentPhase,
    LearningAgentUserDecisionAction action,
  ) {
    switch (action) {
      case LearningAgentUserDecisionAction.continueSession:
        return currentPhase;
      case LearningAgentUserDecisionAction.confirmToolCompleted:
        return LearningAgentPhase.reflect;
      case LearningAgentUserDecisionAction.cancelSession:
        return LearningAgentPhase.canceled;
    }
  }

  LearningAgentPhase afterReflectionSaved() {
    return LearningAgentPhase.complete;
  }
}
