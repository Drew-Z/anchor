import 'dart:convert';

import '../ai/ai_completion_result.dart';
import '../privacy/privacy_redactor.dart';
import 'hybrid_knowledge_search_service.dart';

class SearchQueryPrivacyException implements Exception {
  final String code;

  const SearchQueryPrivacyException(this.code);
}

class ModelSearchQueryVariantProvider implements SearchQueryVariantProvider {
  final AiCompletionClient client;
  final PrivacyRedactor redactor;

  const ModelSearchQueryVariantProvider({
    required this.client,
    this.redactor = const PrivacyRedactor(),
  });

  @override
  Future<List<SearchQueryVariant>> variants(String originalQuery) async {
    final query = originalQuery.trim();
    if (query.isEmpty) return const [];
    if (redactor.redact(query) != query) {
      throw const SearchQueryPrivacyException('sensitive_query_blocked');
    }

    final completion = await client.generateCompletion(
      systemPrompt: _systemPrompt,
      userContent: query,
      temperature: 0,
    );
    final decoded = _decodeObject(completion.text);
    final items = decoded?['queries'];
    if (items is! List) return const [];

    return items.whereType<Map>().map((item) {
      return SearchQueryVariant(
        query: item['query']?.toString() ?? '',
        source: SearchQueryVariantSource.modelRewrite,
        reason: item['reason']?.toString() ?? '',
      );
    }).toList(growable: false);
  }

  static Map<String, dynamic>? _decodeObject(String value) {
    var normalized = value.trim();
    if (normalized.startsWith('```') && normalized.endsWith('```')) {
      normalized = normalized
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }
    try {
      final decoded = jsonDecode(normalized);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static const _systemPrompt = '''
你是本地知识库的搜索查询改写器。
你只会收到用户明确输入的一条查询；不要索取、假设或输出知识库正文、来源片段、文件内容、路径、历史记录、凭据或 corpus。
生成最多 3 个简短、互补的检索查询，优先补充中英文技术表达，但不要回答问题。
只输出严格 JSON：{"queries":[{"query":"...","reason":"..."}]}。
''';
}
