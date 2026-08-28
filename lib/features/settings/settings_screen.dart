import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/product_event.dart';
import '../../services/ai/ai_api_protocol.dart';
import '../../services/ai/ai_model_acceptance.dart';
import '../../services/ai/ai_provider_diagnostics.dart';
import '../../services/openai_service.dart';
import '../../services/privacy/product_event_recorder.dart';
import '../../shared/widgets/anchor_button.dart';
import 'privacy_data_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _customModelController = TextEditingController();

  String _selectedProviderId = 'openai';
  String _selectedModel = 'gpt-4o-mini';
  AiApiProtocol _selectedProtocol = AiApiProtocol.chatCompletions;
  bool _useCustomModel = false;
  bool _hasStoredApiKey = false;
  int _dailyGoal = 50;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRunningAcceptance = false;
  AiModelAcceptanceReport? _acceptanceReport;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final openai = ref.read(openaiServiceProvider);
    final providerId = await openai.getProviderId();
    final model = await openai.getModelForProvider(providerId);
    final baseUrl = await openai.getBaseUrlForProvider(providerId);
    final protocol = await openai.getApiProtocolForProvider(providerId);
    final hasStoredApiKey = await openai.hasApiKey(providerId: providerId);
    final acceptanceReport = await ref
        .read(aiModelAcceptanceStoreProvider)
        .latestFor(AiModelConfiguration(
          providerId: providerId,
          baseUrl: baseUrl,
          model: model,
          protocol: protocol,
        ));
    final stats = await ref.read(gamificationServiceProvider).getStats();

    setState(() {
      _apiKeyController.clear();
      _baseUrlController.text = baseUrl;
      _selectedProviderId = providerId;
      _hasStoredApiKey = hasStoredApiKey;
      _dailyGoal = stats.dailyGoal;
      _acceptanceReport = acceptanceReport;

      // 检查模型是否在当前厂商的预设列表中
      final provider = AIProviders.getById(providerId);
      _selectedProtocol = provider?.protocols.contains(protocol) == true
          ? protocol
          : provider?.defaultProtocol ?? AiApiProtocol.chatCompletions;
      if (provider != null && provider.models.contains(model)) {
        _selectedModel = model;
        _useCustomModel = false;
      } else {
        // 不在预设列表中，使用自定义模型
        _useCustomModel = true;
        _customModelController.text = model;
      }

      _isLoading = false;
    });
  }

  Future<void> _onProviderChanged(String? providerId) async {
    if (providerId == null) return;
    final provider = AIProviders.getById(providerId);
    if (provider == null) return;

    setState(() {
      _selectedProviderId = providerId;
      _baseUrlController.text = provider.baseUrl;
      if (provider.models.isNotEmpty) {
        _selectedModel = provider.models.first;
        _useCustomModel = false;
      } else {
        _useCustomModel = true;
        _customModelController.clear();
      }
      _selectedProtocol = provider.defaultProtocol;
      _apiKeyController.clear();
      _hasStoredApiKey = false;
      _acceptanceReport = null;
    });

    final openai = ref.read(openaiServiceProvider);
    final model = await openai.getModelForProvider(providerId);
    final baseUrl = await openai.getBaseUrlForProvider(providerId);
    final protocol = await openai.getApiProtocolForProvider(providerId);
    final hasKey = await openai.hasApiKey(providerId: providerId);
    final acceptanceReport = await ref
        .read(aiModelAcceptanceStoreProvider)
        .latestFor(AiModelConfiguration(
          providerId: providerId,
          baseUrl: baseUrl,
          model: model,
          protocol: protocol,
        ));
    if (!mounted || _selectedProviderId != providerId) return;
    setState(() {
      _baseUrlController.text = baseUrl;
      _selectedProtocol = provider.protocols.contains(protocol)
          ? protocol
          : provider.defaultProtocol;
      if (provider.models.contains(model)) {
        _selectedModel = model;
        _useCustomModel = false;
        _customModelController.clear();
      } else {
        _useCustomModel = true;
        _customModelController.text = model;
      }
      _hasStoredApiKey = hasKey;
      _acceptanceReport = acceptanceReport;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final enteredApiKey = await _persistAiConfiguration();
    await ref.read(userStatsProvider.notifier).setDailyGoal(_dailyGoal);
    final acceptanceReport = await ref
        .read(aiModelAcceptanceStoreProvider)
        .latestFor(_currentConfiguration);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _acceptanceReport = acceptanceReport;
      if (enteredApiKey) {
        _hasStoredApiKey = true;
        _apiKeyController.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('设置已保存'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<bool> _persistAiConfiguration() async {
    final openai = ref.read(openaiServiceProvider);
    final enteredApiKey = _apiKeyController.text.trim();
    if (enteredApiKey.isNotEmpty) {
      await openai.setApiKey(
        enteredApiKey,
        providerId: _selectedProviderId,
      );
    }
    final model =
        _useCustomModel ? _customModelController.text.trim() : _selectedModel;
    await openai.setBaseUrlForProvider(
      _selectedProviderId,
      _baseUrlController.text.trim(),
    );
    await openai.setApiProtocolForProvider(
      _selectedProviderId,
      _selectedProtocol,
    );
    await openai.setModelForProvider(_selectedProviderId, model);
    await openai.setProviderId(_selectedProviderId);
    return enteredApiKey.isNotEmpty;
  }

  Future<void> _runModelAcceptance() async {
    final model =
        _useCustomModel ? _customModelController.text.trim() : _selectedModel;
    final baseUrl = _baseUrlController.text.trim();
    if (model.isEmpty || baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 API 地址和模型名称')),
      );
      return;
    }
    final hasKey = _apiKeyController.text.trim().isNotEmpty || _hasStoredApiKey;
    if (!hasKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 API Key')),
      );
      return;
    }

    setState(() => _isRunningAcceptance = true);
    try {
      final enteredApiKey = await _persistAiConfiguration();
      final report = await ref
          .read(aiModelAcceptanceRunnerProvider)
          .run(_currentConfiguration);
      await ref.read(productEventRecorderProvider).recordBestEffort(
        ProductEventName.modelAcceptanceCompleted,
        flowId: 'model_setup',
        properties: {
          'passed': report.passed,
          'failure_category': report.blockingFailure?.name ?? 'none',
          'case_count': report.attemptedCount,
          'latency_bucket': ProductEventRecorder.durationBucket(
            Duration(milliseconds: report.totalLatencyMs),
          ),
        },
      );
      ref.invalidate(productEventListProvider);
      if (!mounted) return;
      setState(() {
        _isRunningAcceptance = false;
        _acceptanceReport = report;
        if (enteredApiKey) {
          _hasStoredApiKey = true;
          _apiKeyController.clear();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(report.passed ? '模型验收已通过' : '模型验收未通过'),
          backgroundColor: report.passed ? AppColors.green : AppColors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isRunningAcceptance = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模型验收失败：$error')),
      );
    }
  }

  Future<void> _clearApiKey() async {
    await ref
        .read(openaiServiceProvider)
        .clearApiKey(providerId: _selectedProviderId);
    if (!mounted) return;
    setState(() {
      _hasStoredApiKey = false;
      _apiKeyController.clear();
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  AIProviderPreset get _currentProvider =>
      AIProviders.getById(_selectedProviderId) ?? AIProviders.builtin.first;

  AiModelConfiguration get _currentConfiguration => AiModelConfiguration(
        providerId: _selectedProviderId,
        baseUrl: _baseUrlController.text,
        model: _useCustomModel
            ? _customModelController.text.trim()
            : _selectedModel,
        protocol: _selectedProtocol,
      );

  @override
  Widget build(BuildContext context) {
    final searchPreferencesAsync = ref.watch(searchPreferencesProvider);
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === AI 配置 ===
              const Text(
                'AI 接口配置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 厂商选择
                    const Text(
                      'AI 厂商',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedProviderId,
                          isExpanded: true,
                          items: AIProviders.builtin.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _onProviderChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // API Key
                    const Text(
                      'API Key',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: _hasStoredApiKey
                            ? '已安全保存，留空则保持不变'
                            : _currentProvider.keyHint,
                        hintStyle: const TextStyle(color: AppColors.textLight),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                            const Icon(Icons.key, color: AppColors.textLight),
                        suffixIcon: _hasStoredApiKey
                            ? IconButton(
                                tooltip: '清除 API Key',
                                onPressed: _clearApiKey,
                                icon: const Icon(Icons.delete_outline),
                              )
                            : null,
                      ),
                    ),
                    if (_hasStoredApiKey) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.greenDark,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '已保存到系统安全存储',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_currentProvider.keyHelpUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // 显示获取 Key 的提示
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '前往 ${_currentProvider.keyHelpUrl} 获取 API Key'),
                              backgroundColor: AppColors.blue,
                            ),
                          );
                        },
                        child: Text(
                          '在 ${_currentProvider.keyHelpUrl} 获取 API Key',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Base URL
                    const Text(
                      'API Base URL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _baseUrlController,
                      onChanged: (_) =>
                          setState(() => _acceptanceReport = null),
                      decoration: InputDecoration(
                        hintText: 'https://api.example.com/v1',
                        hintStyle: const TextStyle(color: AppColors.textLight),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                            const Icon(Icons.link, color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'API 协议',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<AiApiProtocol>(
                        segments: _currentProvider.protocols.map((protocol) {
                          return ButtonSegment<AiApiProtocol>(
                            value: protocol,
                            label: Text(
                              protocol == AiApiProtocol.responses
                                  ? 'Responses'
                                  : 'Chat',
                            ),
                          );
                        }).toList(),
                        selected: {_selectedProtocol},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedProtocol = selection.single;
                            _acceptanceReport = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 模型选择
                    const Text(
                      '模型',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentProvider.models.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                _useCustomModel ? '__custom__' : _selectedModel,
                            isExpanded: true,
                            items: [
                              ..._currentProvider.models
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600)),
                                      )),
                              const DropdownMenuItem(
                                value: '__custom__',
                                child: Text('自定义模型...',
                                    style: TextStyle(
                                        fontSize: 15, color: AppColors.blue)),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == '__custom__') {
                                setState(() {
                                  _useCustomModel = true;
                                  _acceptanceReport = null;
                                });
                              } else if (value != null) {
                                setState(() {
                                  _selectedModel = value;
                                  _useCustomModel = false;
                                  _acceptanceReport = null;
                                });
                              }
                            },
                          ),
                        ),
                      )
                    else
                      // 自定义厂商没有预设模型，直接显示输入框
                      TextField(
                        controller: _customModelController,
                        onChanged: (_) =>
                            setState(() => _acceptanceReport = null),
                        decoration: InputDecoration(
                          hintText: '输入模型名称',
                          hintStyle:
                              const TextStyle(color: AppColors.textLight),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    if (_useCustomModel &&
                        _currentProvider.models.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customModelController,
                        onChanged: (_) =>
                            setState(() => _acceptanceReport = null),
                        decoration: InputDecoration(
                          hintText: '输入模型名称',
                          hintStyle:
                              const TextStyle(color: AppColors.textLight),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.manage_search_outlined),
                        title: const Text('模型辅助搜索'),
                        subtitle: const Text('仅发送搜索框中的查询；失败时自动使用本地检索'),
                        value: searchPreferencesAsync
                                .valueOrNull?.modelAssistedSearchEnabled ??
                            false,
                        onChanged: searchPreferencesAsync.isLoading
                            ? null
                            : (value) => ref
                                .read(searchPreferencesProvider.notifier)
                                .setModelAssistedSearchEnabled(value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '模型验收',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (_acceptanceReport != null)
                          Icon(
                            _acceptanceReport!.passed
                                ? Icons.verified_outlined
                                : Icons.error_outline,
                            size: 20,
                            color: _acceptanceReport!.passed
                                ? AppColors.greenDark
                                : AppColors.red,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isRunningAcceptance ? null : _runModelAcceptance,
                        icon: _isRunningAcceptance
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.science_outlined),
                        label: Text(
                          _isRunningAcceptance ? '验收运行中' : '运行五项固定验收',
                        ),
                      ),
                    ),
                    if (_acceptanceReport != null) ...[
                      const SizedBox(height: 14),
                      _buildAcceptanceSummary(_acceptanceReport!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === 学习目标 ===
              const Text(
                '学习目标',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '每日 XP 目标',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [10, 20, 30, 50, 100].map((goal) {
                        final isSelected = _dailyGoal == goal;
                        return GestureDetector(
                          onTap: () => setState(() => _dailyGoal = goal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.green
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.green
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '$goal XP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // === 保存按钮 ===
              AnchorButton(
                label: _isSaving ? '保存中...' : '保存设置',
                color: AppColors.green,
                width: double.infinity,
                height: 56,
                icon: Icons.check,
                onPressed: _isSaving ? null : _saveSettings,
              ),
              const SizedBox(height: 16),

              // === 数据管理 ===
              const Text(
                '数据管理',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _SettingItem(
                icon: Icons.privacy_tip_outlined,
                title: '本地数据与隐私',
                color: AppColors.blue,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyDataScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptanceSummary(AiModelAcceptanceReport report) {
    final tokenText = report.totalTokens == null
        ? 'Token：网关未返回'
        : 'Token：${report.totalTokens}';
    final costText = report.estimatedCostUsd != null
        ? '费用：\$${report.estimatedCostUsd!.toStringAsFixed(6)}'
        : report.pricingSource != null
            ? '费用：网关未返回 Token'
            : '费用：无可核验单价';
    final blockingFailure = report.blockingFailure;
    final resolvedModels = report.cases
        .map((result) => result.resolvedModel)
        .whereType<String>()
        .where((model) => model.isNotEmpty)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${report.passedCount}/${AiAcceptanceCaseKind.values.length} 通过  ·  '
          '${(report.totalLatencyMs / 1000).toStringAsFixed(1)} 秒',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: report.passed ? AppColors.greenDark : AppColors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$tokenText  ·  $costText',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        if (resolvedModels.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '网关实际模型：${resolvedModels.join(', ')}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...report.cases.map(_buildAcceptanceCaseRow),
        if (blockingFailure != null) ...[
          const SizedBox(height: 8),
          Text(
            blockingFailure.action,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAcceptanceCaseRow(AiAcceptanceCaseResult result) {
    final icon = switch (result.status) {
      AiAcceptanceCaseStatus.passed => Icons.check_circle_outline,
      AiAcceptanceCaseStatus.failed => Icons.cancel_outlined,
      AiAcceptanceCaseStatus.skipped => Icons.remove_circle_outline,
    };
    final color = switch (result.status) {
      AiAcceptanceCaseStatus.passed => AppColors.greenDark,
      AiAcceptanceCaseStatus.failed => AppColors.red,
      AiAcceptanceCaseStatus.skipped => AppColors.textLight,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${result.kind.label}：${result.detail}',
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
