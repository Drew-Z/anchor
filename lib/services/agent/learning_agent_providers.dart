import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'learning_agent_executor.dart';

final learningAgentExecutorProvider = Provider<LearningAgentExecutor>((ref) {
  return const DefaultLearningAgentExecutor();
});
