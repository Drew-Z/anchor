import '../../data/models/programming_exercise.dart';
import '../../data/models/question.dart';

enum LearningAgentPracticeTargetType {
  question('question', '普通题'),
  programmingExercise('programming_exercise', '编程练习');

  final String value;
  final String label;

  const LearningAgentPracticeTargetType(this.value, this.label);

  static LearningAgentPracticeTargetType fromString(String value) {
    for (final type in LearningAgentPracticeTargetType.values) {
      if (type.value == value) return type;
    }
    throw FormatException('Unknown learning agent practice target: $value');
  }
}

class LearningAgentPracticeTarget {
  final LearningAgentPracticeTargetType type;
  final String id;
  final String knowledgePointId;
  final String title;
  final SourceStatus sourceStatus;
  final List<String> citationIds;

  const LearningAgentPracticeTarget({
    required this.type,
    required this.id,
    required this.knowledgePointId,
    required this.title,
    required this.sourceStatus,
    required this.citationIds,
  });

  factory LearningAgentPracticeTarget.fromQuestion(Question question) {
    return LearningAgentPracticeTarget(
      type: LearningAgentPracticeTargetType.question,
      id: question.id.trim(),
      knowledgePointId: question.knowledgePointId?.trim() ?? '',
      title: question.content.trim(),
      sourceStatus: question.sourceStatus,
      citationIds: _normalizedIds(question.citationIds),
    );
  }

  factory LearningAgentPracticeTarget.fromProgrammingExercise(
    ProgrammingExercise exercise,
  ) {
    return LearningAgentPracticeTarget(
      type: LearningAgentPracticeTargetType.programmingExercise,
      id: exercise.id.trim(),
      knowledgePointId: exercise.knowledgePointId.trim(),
      title: exercise.prompt.trim(),
      sourceStatus: exercise.sourceStatus,
      citationIds: _normalizedIds(exercise.citationIds),
    );
  }

  bool get isExecutable {
    return id.isNotEmpty &&
        knowledgePointId.isNotEmpty &&
        title.isNotEmpty &&
        sourceStatus == SourceStatus.verified &&
        citationIds.isNotEmpty;
  }

  String get routingId => '${type.value}:$id';
  String get displayLabel => '${type.label}：$title';

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'id': id,
      'knowledge_point_id': knowledgePointId,
      'title': title,
      'source_status': sourceStatus.value,
      'citation_ids': citationIds,
    };
  }

  factory LearningAgentPracticeTarget.fromMap(Map<String, dynamic> map) {
    return LearningAgentPracticeTarget(
      type: LearningAgentPracticeTargetType.fromString(map['type'] as String),
      id: map['id'] as String,
      knowledgePointId: map['knowledge_point_id'] as String,
      title: map['title'] as String,
      sourceStatus: SourceStatus.fromString(map['source_status'] as String),
      citationIds: List<String>.from(map['citation_ids'] as List? ?? const []),
    );
  }
}

List<String> _normalizedIds(Iterable<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    result.add(trimmed);
  }
  return List.unmodifiable(result);
}
