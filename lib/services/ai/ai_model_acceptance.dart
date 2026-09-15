import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ai_api_protocol.dart';
import 'ai_completion_result.dart';
import 'ai_provider_diagnostics.dart';

enum AiAcceptanceCaseKind {
  structuredJson,
  chinesePoem,
  dartCoding,
  claimGrounding,
  evidenceRefusal,
}

extension AiAcceptanceCaseKindDetails on AiAcceptanceCaseKind {
  String get value => name;

  String get label {
    switch (this) {
      case AiAcceptanceCaseKind.structuredJson:
        return '结构化 JSON';
      case AiAcceptanceCaseKind.chinesePoem:
        return '中文七言绝句';
      case AiAcceptanceCaseKind.dartCoding:
        return 'Dart 编程';
      case AiAcceptanceCaseKind.claimGrounding:
        return '主张与引用绑定';
      case AiAcceptanceCaseKind.evidenceRefusal:
        return '证据不足拒答';
    }
  }
}

enum AiAcceptanceCaseStatus { passed, failed, skipped }

class AiModelConfiguration {
  final String providerId;
  final String endpoint;
  final String model;
  final AiApiProtocol protocol;

  AiModelConfiguration({
    required String providerId,
    required String baseUrl,
    required String model,
    required this.protocol,
  })  : providerId = providerId.trim().toLowerCase(),
        endpoint = _sanitizeEndpoint(baseUrl),
        model = model.trim();

  String get signature => '$providerId|$endpoint|$model|${protocol.value}';

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'endpoint': endpoint,
      'model': model,
      'protocol': protocol.value,
    };
  }

  factory AiModelConfiguration.fromJson(Map<String, dynamic> json) {
    return AiModelConfiguration(
      providerId: json['provider_id']?.toString() ?? 'custom',
      baseUrl: json['endpoint']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      protocol: AiApiProtocol.fromString(json['protocol']?.toString()),
    );
  }

  static String _sanitizeEndpoint(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return trimmed.split(RegExp(r'[?#]')).first;
    }
    return Uri(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      port: uri.hasPort ? uri.port : null,
      path: uri.path.replaceFirst(RegExp(r'/+$'), ''),
    ).toString();
  }
}

class AiAcceptanceCaseResult {
  final AiAcceptanceCaseKind kind;
  final AiAcceptanceCaseStatus status;
  final String detail;
  final int latencyMs;
  final AiTokenUsage usage;
  final String? resolvedModel;
  final AiProviderFailureKind? failureKind;

  const AiAcceptanceCaseResult({
    required this.kind,
    required this.status,
    required this.detail,
    this.latencyMs = 0,
    this.usage = const AiTokenUsage(),
    this.resolvedModel,
    this.failureKind,
  });

  bool get passed => status == AiAcceptanceCaseStatus.passed;

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.value,
      'status': status.name,
      'detail': detail,
      'latency_ms': latencyMs,
      'usage': usage.toJson(),
      'resolved_model': resolvedModel,
      'failure_kind': failureKind?.name,
    };
  }

  factory AiAcceptanceCaseResult.fromJson(Map<String, dynamic> json) {
    return AiAcceptanceCaseResult(
      kind: AiAcceptanceCaseKind.values.firstWhere(
        (kind) => kind.value == json['kind'],
        orElse: () => AiAcceptanceCaseKind.structuredJson,
      ),
      status: AiAcceptanceCaseStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => AiAcceptanceCaseStatus.failed,
      ),
      detail: json['detail']?.toString() ?? '',
      latencyMs: int.tryParse(json['latency_ms']?.toString() ?? '') ?? 0,
      usage: AiTokenUsage.fromJson(
        Map<String, dynamic>.from(json['usage'] as Map? ?? const {}),
      ),
      resolvedModel: json['resolved_model']?.toString(),
      failureKind: AiProviderFailureKind.values
          .cast<AiProviderFailureKind?>()
          .firstWhere(
            (kind) => kind?.name == json['failure_kind'],
            orElse: () => null,
          ),
    );
  }
}

class AiModelAcceptanceReport {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final AiModelConfiguration configuration;
  final DateTime runAt;
  final List<AiAcceptanceCaseResult> cases;
  final double? estimatedCostUsd;
  final String? pricingSource;

  const AiModelAcceptanceReport({
    required this.configuration,
    required this.runAt,
    required this.cases,
    this.schemaVersion = currentSchemaVersion,
    this.estimatedCostUsd,
    this.pricingSource,
  });

  bool get passed =>
      cases.length == AiAcceptanceCaseKind.values.length &&
      cases.every((result) => result.passed);

  int get passedCount => cases.where((result) => result.passed).length;

  int get attemptedCount => cases
      .where((result) => result.status != AiAcceptanceCaseStatus.skipped)
      .length;

  int get totalLatencyMs => cases.fold(0, (sum, item) => sum + item.latencyMs);

  int? get totalTokens {
    final values =
        cases.map((item) => item.usage.effectiveTotalTokens).whereType<int>();
    if (values.isEmpty) return null;
    return values.fold<int>(0, (sum, value) => sum + value);
  }

  AiProviderFailureKind? get blockingFailure {
    for (final result in cases) {
      if (result.failureKind != null) return result.failureKind;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'configuration': configuration.toJson(),
      'run_at': runAt.toUtc().toIso8601String(),
      'cases': cases.map((result) => result.toJson()).toList(),
      'estimated_cost_usd': estimatedCostUsd,
      'pricing_source': pricingSource,
    };
  }

  factory AiModelAcceptanceReport.fromJson(Map<String, dynamic> json) {
    return AiModelAcceptanceReport(
      schemaVersion:
          int.tryParse(json['schema_version']?.toString() ?? '') ?? 1,
      configuration: AiModelConfiguration.fromJson(
        Map<String, dynamic>.from(json['configuration'] as Map? ?? const {}),
      ),
      runAt: DateTime.tryParse(json['run_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      cases: (json['cases'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AiAcceptanceCaseResult.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      estimatedCostUsd:
          double.tryParse(json['estimated_cost_usd']?.toString() ?? ''),
      pricingSource: json['pricing_source']?.toString(),
    );
  }
}

abstract class AiModelAcceptanceStore {
  Future<List<AiModelAcceptanceReport>> readAll();

  Future<void> save(AiModelAcceptanceReport report);

  Future<AiModelAcceptanceReport?> latestFor(
    AiModelConfiguration configuration,
  );

  Future<bool> isAccepted(AiModelConfiguration configuration);
}

class SharedPreferencesAiModelAcceptanceStore
    implements AiModelAcceptanceStore {
  static const String _reportsKey = 'ai_model_acceptance_reports_v1';
  static const int _maxReports = 20;

  final Future<SharedPreferences> Function() _preferencesLoader;

  SharedPreferencesAiModelAcceptanceStore({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  @override
  Future<List<AiModelAcceptanceReport>> readAll() async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(_reportsKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => AiModelAcceptanceReport.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(AiModelAcceptanceReport report) async {
    final reports = await readAll();
    reports.removeWhere((item) =>
        item.configuration.signature == report.configuration.signature);
    reports.insert(0, report);
    if (reports.length > _maxReports) {
      reports.removeRange(_maxReports, reports.length);
    }
    final prefs = await _preferencesLoader();
    await prefs.setString(
      _reportsKey,
      jsonEncode(reports.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<AiModelAcceptanceReport?> latestFor(
    AiModelConfiguration configuration,
  ) async {
    final reports = await readAll();
    for (final report in reports) {
      if (report.configuration.signature == configuration.signature) {
        return report;
      }
    }
    return null;
  }

  @override
  Future<bool> isAccepted(AiModelConfiguration configuration) async {
    return (await latestFor(configuration))?.passed == true;
  }
}

class AiModelTokenPricing {
  final double inputUsdPerMillionTokens;
  final double outputUsdPerMillionTokens;
  final String source;

  const AiModelTokenPricing({
    required this.inputUsdPerMillionTokens,
    required this.outputUsdPerMillionTokens,
    required this.source,
  });

  double estimate(Iterable<AiAcceptanceCaseResult> cases) {
    var inputTokens = 0;
    var outputTokens = 0;
    for (final result in cases) {
      inputTokens += result.usage.inputTokens ?? 0;
      outputTokens += result.usage.outputTokens ?? 0;
    }
    return inputTokens / 1000000 * inputUsdPerMillionTokens +
        outputTokens / 1000000 * outputUsdPerMillionTokens;
  }
}

class AiModelPricingCatalog {
  static const String openAiPricingSource =
      'https://developers.openai.com/api/docs/pricing';

  static AiModelTokenPricing? forConfiguration(
    AiModelConfiguration configuration,
  ) {
    if (configuration.providerId != 'openai' ||
        Uri.tryParse(configuration.endpoint)?.host != 'api.openai.com') {
      return null;
    }
    switch (configuration.model) {
      case 'gpt-5.6':
      case 'gpt-5.6-sol':
        return const AiModelTokenPricing(
          inputUsdPerMillionTokens: 5,
          outputUsdPerMillionTokens: 30,
          source: openAiPricingSource,
        );
      case 'gpt-5.6-terra':
        return const AiModelTokenPricing(
          inputUsdPerMillionTokens: 2.5,
          outputUsdPerMillionTokens: 15,
          source: openAiPricingSource,
        );
      case 'gpt-5.6-luna':
        return const AiModelTokenPricing(
          inputUsdPerMillionTokens: 1,
          outputUsdPerMillionTokens: 6,
          source: openAiPricingSource,
        );
      case 'gpt-5.5':
        return const AiModelTokenPricing(
          inputUsdPerMillionTokens: 5,
          outputUsdPerMillionTokens: 30,
          source: openAiPricingSource,
        );
      default:
        return null;
    }
  }
}

class AiModelAcceptanceRunner {
  static const String methodologySource =
      'https://developers.openai.com/api/docs/guides/evals';

  final AiCompletionClient _client;
  final AiModelAcceptanceStore _store;
  final DateTime Function() _clock;
  final Duration _caseTimeout;
  final Duration _dartCodingCaseTimeout;
  final Duration _runTimeout;

  AiModelAcceptanceRunner({
    required AiCompletionClient client,
    AiModelAcceptanceStore? store,
    DateTime Function()? clock,
    // The configured relay has produced valid non-streaming responses in the
    // 2-3 minute range. Keep the client-side budget above that observed tail
    // so a late but valid response is not reported as a false failure.
    Duration caseTimeout = const Duration(minutes: 3),
    Duration dartCodingCaseTimeout = const Duration(minutes: 4),
    Duration runTimeout = const Duration(minutes: 12),
  })  : assert(caseTimeout > Duration.zero),
        assert(dartCodingCaseTimeout > Duration.zero),
        assert(runTimeout > Duration.zero),
        _client = client,
        _store = store ?? SharedPreferencesAiModelAcceptanceStore(),
        _clock = clock ?? DateTime.now,
        _caseTimeout = caseTimeout,
        _dartCodingCaseTimeout = dartCodingCaseTimeout,
        _runTimeout = runTimeout;

  Future<AiModelAcceptanceReport> run(
    AiModelConfiguration configuration,
  ) async {
    final results = <AiAcceptanceCaseResult>[];
    final runStopwatch = Stopwatch()..start();
    var blocked = false;
    for (final testCase in _cases) {
      if (blocked) {
        results.add(AiAcceptanceCaseResult(
          kind: testCase.kind,
          status: AiAcceptanceCaseStatus.skipped,
          detail: '前置供应商错误使后续任务无法可靠执行',
        ));
        continue;
      }
      final remaining = _runTimeout - runStopwatch.elapsed;
      if (remaining <= Duration.zero) {
        results.add(AiAcceptanceCaseResult(
          kind: testCase.kind,
          status: AiAcceptanceCaseStatus.failed,
          detail: '整轮验收超过 ${_durationLabel(_runTimeout)}',
          latencyMs: runStopwatch.elapsedMilliseconds,
          failureKind: AiProviderFailureKind.timeout,
        ));
        blocked = true;
        continue;
      }
      final caseBudget = testCase.kind == AiAcceptanceCaseKind.dartCoding
          ? _dartCodingCaseTimeout
          : _caseTimeout;
      final timeout = remaining < caseBudget ? remaining : caseBudget;
      final caseStopwatch = Stopwatch()..start();
      try {
        final result = await _client
            .generateCompletion(
              systemPrompt: testCase.systemPrompt,
              userContent: testCase.userPrompt,
              temperature: 0,
              bypassAcceptanceGate: true,
            )
            .timeout(timeout);
        caseStopwatch.stop();
        final evaluation = testCase.evaluate(result.text);
        results.add(AiAcceptanceCaseResult(
          kind: testCase.kind,
          status: evaluation.passed
              ? AiAcceptanceCaseStatus.passed
              : AiAcceptanceCaseStatus.failed,
          detail: evaluation.detail,
          latencyMs: result.latency.inMilliseconds,
          usage: result.usage,
          resolvedModel: result.resolvedModel,
        ));
      } on TimeoutException {
        caseStopwatch.stop();
        results.add(AiAcceptanceCaseResult(
          kind: testCase.kind,
          status: AiAcceptanceCaseStatus.failed,
          detail: '请求超时: 单项验收超过 ${_durationLabel(timeout)}。'
              '供应商仍可能稍后完成并计费，但迟到响应不计为通过',
          latencyMs: caseStopwatch.elapsedMilliseconds,
          failureKind: AiProviderFailureKind.timeout,
        ));
        blocked = true;
      } on AiProviderDiagnostic catch (error) {
        caseStopwatch.stop();
        results.add(AiAcceptanceCaseResult(
          kind: testCase.kind,
          status: AiAcceptanceCaseStatus.failed,
          detail: _boundedDetail('${error.kind.label}: ${error.message}'),
          latencyMs: caseStopwatch.elapsedMilliseconds,
          failureKind: error.kind,
        ));
        blocked = _blocksRemainingCases(error.kind);
      } catch (error) {
        caseStopwatch.stop();
        results.add(AiAcceptanceCaseResult(
          kind: testCase.kind,
          status: AiAcceptanceCaseStatus.failed,
          detail: _boundedDetail(error.toString()),
          latencyMs: caseStopwatch.elapsedMilliseconds,
          failureKind: AiProviderFailureKind.unknown,
        ));
        blocked = true;
      }
    }

    final pricing = AiModelPricingCatalog.forConfiguration(configuration);
    final hasBillableUsage = results.any((result) =>
        result.usage.inputTokens != null || result.usage.outputTokens != null);
    final report = AiModelAcceptanceReport(
      configuration: configuration,
      runAt: _clock().toUtc(),
      cases: results,
      estimatedCostUsd: pricing != null && hasBillableUsage
          ? pricing.estimate(results)
          : null,
      pricingSource: pricing?.source,
    );
    await _store.save(report);
    return report;
  }

  static String _durationLabel(Duration duration) {
    if (duration.inSeconds >= 60 && duration.inSeconds % 60 == 0) {
      return '${duration.inMinutes} 分钟';
    }
    return '${duration.inSeconds} 秒';
  }

  bool _blocksRemainingCases(AiProviderFailureKind kind) {
    return kind != AiProviderFailureKind.malformedResponse &&
        kind != AiProviderFailureKind.unknown;
  }

  static String _boundedDetail(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length <= 240
        ? normalized
        : '${normalized.substring(0, 237)}...';
  }

  static final List<_AcceptanceCase> _cases = [
    _AcceptanceCase(
      kind: AiAcceptanceCaseKind.structuredJson,
      systemPrompt: '你正在参加模型兼容性验收。只输出要求的 JSON，不使用 Markdown。',
      userPrompt: '只输出这个 JSON 对象，不增加字段：'
          '{"topic":"binary_search","requires_sorted_input":true,'
          '"complexity":"O(log n)"}',
      evaluate: (text) {
        final json = _decodeObject(text);
        final passed = json?['topic'] == 'binary_search' &&
            json?['requires_sorted_input'] == true &&
            json?['complexity'] == 'O(log n)' &&
            json?.length == 3;
        return _Evaluation(passed, passed ? 'JSON 结构和字段均正确' : '未返回严格目标 JSON');
      },
    ),
    _AcceptanceCase(
      kind: AiAcceptanceCaseKind.chinesePoem,
      systemPrompt: '你正在参加中文生成验收。只输出 JSON，不使用 Markdown。',
      userPrompt: '写一首原创七言绝句，主题是雨后山中学习。'
          '输出 {"title":"标题","lines":["第一句","第二句","第三句","第四句"]}。'
          '每句正文必须恰好七个汉字，标点可省略。',
      evaluate: (text) {
        final json = _decodeObject(text);
        final lines =
            (json?['lines'] as List? ?? const []).whereType<String>().toList();
        final validLines =
            lines.length == 4 && lines.every(_isSevenCharacterLine);
        final passed =
            (json?['title']?.toString().trim().isNotEmpty ?? false) &&
                validLines;
        return _Evaluation(passed, passed ? '四句均为七个汉字' : '诗句数量或七言格式不符合要求');
      },
    ),
    _AcceptanceCase(
      kind: AiAcceptanceCaseKind.dartCoding,
      systemPrompt: '你正在参加 Dart 编程验收。只输出 JSON，不使用 Markdown。',
      userPrompt: '实现 Dart 函数 int sumEven(List<int> values)，返回所有偶数之和。'
          '输出 {"language":"dart","code":"完整函数源码",'
          '"examples":[{"input":[1,2,3,4],"output":6},'
          '{"input":[-2,3,10],"output":8}]}。',
      evaluate: (text) {
        final json = _decodeObject(text);
        final code = json?['code']?.toString() ?? '';
        final compact = code.replaceAll(RegExp(r'\s+'), ' ');
        final examples = json?['examples'] as List? ?? const [];
        final hasEvenCheck = compact.contains('.isEven') ||
            RegExp(r'%\s*2\s*==\s*0').hasMatch(compact);
        final hasAccumulation = compact.contains('fold') ||
            compact.contains('+=') ||
            compact.contains('sum = sum +');
        final passed = json?['language'] == 'dart' &&
            compact.contains('sumEven') &&
            hasEvenCheck &&
            hasAccumulation &&
            _containsExample(examples, const [1, 2, 3, 4], 6) &&
            _containsExample(examples, const [-2, 3, 10], 8);
        return _Evaluation(passed, passed ? '函数与两个固定样例均完整' : '代码或固定样例不满足验收条件');
      },
    ),
    _AcceptanceCase(
      kind: AiAcceptanceCaseKind.claimGrounding,
      systemPrompt: '你正在参加来源绑定验收。只输出 JSON，不使用 Markdown。',
      userPrompt: '证据 S1：二分查找要求输入序列已经按比较规则有序。每轮会排除当前搜索区间的一半。\n'
          '只依据证据回答“二分查找的前提和每轮变化是什么？”。输出 '
          '{"status":"answered","claims":[{"text":"主张",'
          '"citation_id":"S1","quote":"证据中的逐字原文"}]}。',
      evaluate: (text) {
        const evidence = '二分查找要求输入序列已经按比较规则有序。每轮会排除当前搜索区间的一半。';
        final json = _decodeObject(text);
        final claims = json?['claims'] as List? ?? const [];
        final grounded = claims.isNotEmpty &&
            claims.whereType<Map>().every((claim) {
              final quote = claim['quote']?.toString().trim() ?? '';
              return claim['citation_id'] == 'S1' &&
                  quote.isNotEmpty &&
                  evidence.contains(quote);
            });
        final passed = json?['status'] == 'answered' && grounded;
        return _Evaluation(
            passed, passed ? '每个主张都绑定 S1 逐字引文' : '存在越界引用、伪造引文或空主张');
      },
    ),
    _AcceptanceCase(
      kind: AiAcceptanceCaseKind.evidenceRefusal,
      systemPrompt: '你正在参加证据不足拒答验收。只输出 JSON，不使用 Markdown。',
      userPrompt: '证据 S1：Dart 的 List 保持元素插入顺序。\n'
          '问题：Python 的 GIL 在多线程 CPU 密集任务中如何工作？\n'
          '证据无法回答时，输出 {"status":"refused","claims":[]}。',
      evaluate: (text) {
        final json = _decodeObject(text);
        final claims = json?['claims'] as List?;
        final passed =
            json?['status'] == 'refused' && claims != null && claims.isEmpty;
        return _Evaluation(passed, passed ? '正确拒绝证据外问题' : '未在证据不足时严格拒答');
      },
    ),
  ];

  static Map<String, dynamic>? _decodeObject(String text) {
    var normalized = text.trim();
    if (normalized.startsWith('```')) {
      normalized = normalized.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      normalized = normalized.replaceFirst(RegExp(r'\s*```$'), '');
    }
    try {
      final decoded = jsonDecode(normalized);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static bool _isSevenCharacterLine(String line) {
    final characters = RegExp(r'[\u3400-\u9fff]')
        .allMatches(line)
        .map((match) => match.group(0))
        .whereType<String>()
        .length;
    return characters == 7;
  }

  static bool _containsExample(
      List<dynamic> examples, List<int> input, int output) {
    return examples.whereType<Map>().any((example) {
      final actualInput = (example['input'] as List? ?? const [])
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toList();
      return _sameInts(actualInput, input) &&
          int.tryParse(example['output']?.toString() ?? '') == output;
    });
  }

  static bool _sameInts(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

abstract class AiProviderDiagnostic implements Exception {
  AiProviderFailureKind get kind;

  String get message;
}

class _AcceptanceCase {
  final AiAcceptanceCaseKind kind;
  final String systemPrompt;
  final String userPrompt;
  final _Evaluation Function(String text) evaluate;

  const _AcceptanceCase({
    required this.kind,
    required this.systemPrompt,
    required this.userPrompt,
    required this.evaluate,
  });
}

class _Evaluation {
  final bool passed;
  final String detail;

  const _Evaluation(this.passed, this.detail);
}
