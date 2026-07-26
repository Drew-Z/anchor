import 'package:dlg_q/services/agent/hybrid_knowledge_search_service.dart';
import 'package:dlg_q/services/agent/model_search_query_variant_provider.dart';
import 'package:dlg_q/services/ai/ai_api_protocol.dart';
import 'package:dlg_q/services/ai/ai_completion_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sends only the explicit query and parses strict variants', () async {
    final client = _RecordingClient(
      '{"queries":[{"query":"checkpoint failure recovery",'
      '"reason":"English technical wording"}]}',
    );
    final provider = ModelSearchQueryVariantProvider(client: client);

    final variants = await provider.variants('为什么需要保存检查点');

    expect(client.userContents, ['为什么需要保存检查点']);
    expect(client.systemPrompts.single, contains('不要索取'));
    expect(client.systemPrompts.single, contains('corpus'));
    expect(variants.single.source, SearchQueryVariantSource.modelRewrite);
    expect(variants.single.query, 'checkpoint failure recovery');
  });

  test('accepts fenced JSON but not prose or array roots', () async {
    final fenced = ModelSearchQueryVariantProvider(
      client: _RecordingClient(
        '```json\n{"queries":[{"query":"tool execution",'
        '"reason":"term"}]}\n```',
      ),
    );
    final prose = ModelSearchQueryVariantProvider(
      client: _RecordingClient('Here is a query: tool execution'),
    );
    final array = ModelSearchQueryVariantProvider(
      client: _RecordingClient('[{"query":"tool execution"}]'),
    );

    expect((await fenced.variants('工具调用')).single.query, 'tool execution');
    expect(await prose.variants('工具调用'), isEmpty);
    expect(await array.variants('工具调用'), isEmpty);
  });

  test('blocks credential and private-path shaped queries before transport',
      () async {
    final client = _RecordingClient('{"queries":[]}');
    final provider = ModelSearchQueryVariantProvider(client: client);

    await expectLater(
      provider.variants('debug ' 'sk-' '1234567890abcdefghijklmnop'),
      throwsA(isA<SearchQueryPrivacyException>()),
    );
    await expectLater(
      provider.variants(r'解释 C:\Users\private\secret.dart'),
      throwsA(isA<SearchQueryPrivacyException>()),
    );
    expect(client.userContents, isEmpty);
  });
}

class _RecordingClient implements AiCompletionClient {
  final String output;
  final List<String> systemPrompts = [];
  final List<String> userContents = [];

  _RecordingClient(this.output);

  @override
  Future<AiCompletionResult> generateCompletion({
    required String systemPrompt,
    required String userContent,
    String? imageBase64,
    double? temperature,
    bool bypassAcceptanceGate = false,
  }) async {
    systemPrompts.add(systemPrompt);
    userContents.add(userContent);
    return AiCompletionResult(
      text: output,
      requestedModel: 'fake',
      resolvedModel: 'fake',
      protocol: AiApiProtocol.responses,
      latency: const Duration(milliseconds: 1),
    );
  }
}
