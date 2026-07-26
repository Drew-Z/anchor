String? followUpQuestionFromLearningSessionSummary(String? summary) {
  if (summary == null || summary.isEmpty) return null;
  for (final line in summary.split('\n')) {
    final value = line.trim();
    if (!value.startsWith('本轮追问:')) continue;
    final question = value.substring('本轮追问:'.length).trim();
    if (question.isNotEmpty) return question;
  }
  return null;
}
