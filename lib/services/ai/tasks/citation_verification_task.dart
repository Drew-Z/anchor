import 'dart:convert';

import '../../../data/models/question.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';

enum CitationVerificationStatus {
  verifiedCandidate('verified_candidate', '候选可信'),
  weakEvidence('weak_evidence', '证据较弱'),
  noSource('no_source', '无来源');

  final String value;
  final String label;
  const CitationVerificationStatus(this.value, this.label);

  static CitationVerificationStatus fromString(String value) {
    return CitationVerificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CitationVerificationStatus.noSource,
    );
  }
}

class CitationVerificationResult {
  final CitationVerificationStatus status;
  final String reason;
  final List<String> supportedCitationIds;
  final List<String> missingCitationIds;

  CitationVerificationResult({
    required this.status,
    required this.reason,
    this.supportedCitationIds = const [],
    this.missingCitationIds = const [],
  });

  CitationVerificationResult copyWith({
    CitationVerificationStatus? status,
    String? reason,
    List<String>? supportedCitationIds,
    List<String>? missingCitationIds,
  }) {
    return CitationVerificationResult(
      status: status ?? this.status,
      reason: reason ?? this.reason,
      supportedCitationIds: supportedCitationIds ?? this.supportedCitationIds,
      missingCitationIds: missingCitationIds ?? this.missingCitationIds,
    );
  }

  factory CitationVerificationResult.noSource(String reason) {
    return CitationVerificationResult(
      status: CitationVerificationStatus.noSource,
      reason: reason,
    );
  }

  factory CitationVerificationResult.fromJson(Map<String, dynamic> json) {
    return CitationVerificationResult(
      status: CitationVerificationStatus.fromString(
        json['status'] as String? ?? CitationVerificationStatus.noSource.value,
      ),
      reason: json['reason'] as String? ?? '',
      supportedCitationIds: (json['supported_citation_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      missingCitationIds: (json['missing_citation_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          [],
    );
  }
}

class CitationVerificationTask {
  static const String _systemPrompt = '''
你是一个来源核验助手。你的任务是判断题目的答案和解析是否能由给定 citation source chunks 支撑。

规则：
1. 只看用户提供的题目和 citation chunks。
2. 如果答案能从 citation chunks 直接推出，status = "verified_candidate"。
3. 如果答案部分可推出，但解析扩展过多或依据不充分，status = "weak_evidence"。
4. 如果没有可用来源或答案无法由来源推出，status = "no_source"。
5. 不要用常识或外部知识补证据。
6. supported_citation_ids 和 missing_citation_ids 必须来自提供的 citation chunks id。
7. 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "status": "verified_candidate",
  "reason": "简短说明",
  "supported_citation_ids": ["chunk_id"],
  "missing_citation_ids": []
}
''';

  final OpenAIService _openai;

  CitationVerificationTask(this._openai);

  Future<AiTaskResult<CitationVerificationResult>> run({
    required Question question,
    required List<SourceChunk> citedChunks,
  }) async {
    if (question.citationIds.isEmpty || citedChunks.isEmpty) {
      return AiTaskResult.success(
        CitationVerificationResult.noSource('题目没有可核验的来源引用'),
      );
    }

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(question, citedChunks),
        temperature: 0.0,
      );

      CitationVerificationResult result;
      try {
        result = _parseResponse(response);
      } catch (e) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: e.toString(),
          rawResponse: response,
        );
      }

      result = _sanitizeResult(
        result: result,
        citedChunks: citedChunks,
      );

      return AiTaskResult.success(result, rawResponse: response);
    } catch (e) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: e.toString(),
      );
    }
  }

  CitationVerificationResult _sanitizeResult({
    required CitationVerificationResult result,
    required List<SourceChunk> citedChunks,
  }) {
    final knownCitationIds = citedChunks.map((chunk) => chunk.id).toSet();
    final supportedCitationIds = result.supportedCitationIds
        .where(knownCitationIds.contains)
        .toSet()
        .toList();
    final missingCitationIds = result.missingCitationIds
        .where(knownCitationIds.contains)
        .where((id) => !supportedCitationIds.contains(id))
        .toSet()
        .toList();

    if (result.status == CitationVerificationStatus.noSource ||
        supportedCitationIds.isEmpty) {
      return result.copyWith(
        status: CitationVerificationStatus.noSource,
        supportedCitationIds: const [],
        missingCitationIds: missingCitationIds,
      );
    }

    return result.copyWith(
      supportedCitationIds: supportedCitationIds,
      missingCitationIds: missingCitationIds,
    );
  }

  String _buildUserContent(Question question, List<SourceChunk> citedChunks) {
    final buffer = StringBuffer();
    buffer.writeln('--- question ---');
    buffer.writeln('type: ${question.type.value}');
    buffer.writeln('content: ${question.content}');
    if (question.options.isNotEmpty) {
      buffer.writeln('options: ${question.options.join(' | ')}');
    }
    buffer.writeln('answer: ${question.answer}');
    if (question.explanation != null && question.explanation!.isNotEmpty) {
      buffer.writeln('explanation: ${question.explanation}');
    }
    buffer.writeln('citation_ids: ${question.citationIds.join(', ')}');
    buffer.writeln();

    buffer.writeln('--- citation_chunks ---');
    for (final chunk in citedChunks) {
      buffer.writeln('id: ${chunk.id}');
      if (chunk.locator != null && chunk.locator!.isNotEmpty) {
        buffer.writeln('locator: ${chunk.locator}');
      }
      buffer.writeln('content:');
      buffer.writeln(chunk.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  CitationVerificationResult _parseResponse(String response) {
    try {
      return CitationVerificationResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return CitationVerificationResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
