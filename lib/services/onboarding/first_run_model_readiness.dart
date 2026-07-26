import '../ai/ai_model_acceptance.dart';
import '../openai_service.dart';

class FirstRunModelReadiness {
  final AiModelConfiguration configuration;
  final bool hasCredential;
  final AiModelAcceptanceReport? acceptanceReport;

  const FirstRunModelReadiness({
    required this.configuration,
    required this.hasCredential,
    required this.acceptanceReport,
  });

  bool get isReady => hasCredential && acceptanceReport?.passed == true;
}

class FirstRunModelReadinessService {
  final OpenAIService _openAIService;
  final AiModelAcceptanceStore _acceptanceStore;

  const FirstRunModelReadinessService({
    required OpenAIService openAIService,
    required AiModelAcceptanceStore acceptanceStore,
  })  : _openAIService = openAIService,
        _acceptanceStore = acceptanceStore;

  Future<FirstRunModelReadiness> load() async {
    final providerId = await _openAIService.getProviderId();
    final baseUrl = await _openAIService.getBaseUrl();
    final model = await _openAIService.getModel();
    final protocol = await _openAIService.getApiProtocol();
    final configuration = AiModelConfiguration(
      providerId: providerId,
      baseUrl: baseUrl,
      model: model,
      protocol: protocol,
    );
    final values = await Future.wait<Object?>([
      _openAIService.hasApiKey(providerId: providerId),
      _acceptanceStore.latestFor(configuration),
    ]);
    return FirstRunModelReadiness(
      configuration: configuration,
      hasCredential: values[0] == true,
      acceptanceReport: values[1] as AiModelAcceptanceReport?,
    );
  }
}
