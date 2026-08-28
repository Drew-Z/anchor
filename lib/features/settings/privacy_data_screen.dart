import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/product_event.dart';
import '../../services/privacy/local_data_backup_service.dart';
import '../../services/privacy/local_data_deletion_service.dart';
import '../../services/privacy/privacy_redactor.dart';
import '../../services/privacy/support_bundle_service.dart';

class PrivacyDataScreen extends ConsumerStatefulWidget {
  const PrivacyDataScreen({super.key});

  @override
  ConsumerState<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends ConsumerState<PrivacyDataScreen> {
  bool _isExporting = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isDeleting = false;

  bool get _isBusy =>
      _isExporting || _isBackingUp || _isRestoring || _isDeleting;

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(privacyPreferencesProvider);
    final eventsAsync = ref.watch(productEventListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('本地数据与隐私')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const _SectionTitle('隐私控制'),
            const SizedBox(height: 8),
            preferencesAsync.when(
              data: (preferences) => Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('记录本地产品事件'),
                    subtitle: const Text('事件只保存在本机，关闭后不会新增记录。'),
                    value: preferences.localProductEventsEnabled,
                    onChanged: (value) => ref
                        .read(privacyPreferencesProvider.notifier)
                        .setLocalProductEventsEnabled(value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('支持包包含 Agent 运行摘要'),
                    subtitle: const Text('只包含阶段和数量，不包含回答、源码或模型原文。'),
                    value: preferences.includeAgentRuntimeSummary,
                    onChanged: (value) => ref
                        .read(privacyPreferencesProvider.notifier)
                        .setIncludeAgentRuntimeSummary(value),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _InlineError(
                message: '隐私设置读取失败: $error',
                onRetry: () => ref.invalidate(privacyPreferencesProvider),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('备份与恢复'),
            const SizedBox(height: 8),
            const Text(
              '数据库备份包含学习内容、学习记录和本地产品事件；不包含模型凭据、模型配置、首次运行状态或隐私偏好。',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.cloud_download_outlined,
              title: '导出本地数据备份',
              onTap: _isBusy ? null : _exportDatabaseBackup,
            ),
            const Divider(height: 1),
            _ActionRow(
              icon: Icons.settings_backup_restore_outlined,
              title: '从备份恢复',
              onTap: _isBusy ? null : _restoreDatabaseBackup,
            ),
            if (_isBackingUp || _isRestoring) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 24),
            const _SectionTitle('导出'),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.table_view_outlined,
              title: '导出本地事件',
              onTap: _isBusy ? null : _exportEvents,
            ),
            const Divider(height: 1),
            _ActionRow(
              icon: Icons.support_agent_outlined,
              title: '导出脱敏支持包',
              onTap: _isBusy ? null : _exportSupportBundle,
            ),
            if (_isExporting) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: _SectionTitle('最近事件')),
                IconButton(
                  tooltip: '刷新事件',
                  onPressed: () => ref.invalidate(productEventListProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            eventsAsync.when(
              data: (events) => _EventList(events: events),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _InlineError(
                message: '事件读取失败: $error',
                onRetry: () => ref.invalidate(productEventListProvider),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('删除本地数据'),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.delete_forever_outlined,
              title: _isDeleting ? '正在删除...' : '选择删除范围',
              color: AppColors.red,
              onTap: _isBusy ? null : _showDeleteDialog,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportEvents() async {
    await _runExport(() async {
      final artifact = await ref
          .read(supportBundleServiceProvider)
          .buildProductEventExport();
      return _saveArtifact(artifact, dialogTitle: '导出本地事件');
    });
  }

  Future<void> _exportSupportBundle() async {
    await _runExport(() async {
      final artifact =
          await ref.read(supportBundleServiceProvider).buildSupportBundle();
      final saved = await _saveArtifact(
        artifact,
        dialogTitle: '导出脱敏支持包',
      );
      if (saved) {
        await ref.read(productEventRecorderProvider).recordBestEffort(
          ProductEventName.supportBundleExported,
          flowId: 'privacy_settings',
          properties: {
            'included_sections': artifact.includedSections,
            'redaction_version': PrivacyRedactor.currentVersion,
          },
        );
        ref.invalidate(productEventListProvider);
      }
      return saved;
    });
  }

  Future<void> _runExport(Future<bool> Function() action) async {
    setState(() => _isExporting = true);
    try {
      final saved = await action();
      if (!mounted || !saved) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('导出完成'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $error')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<bool> _saveArtifact(
    LocalTextExport artifact, {
    required String dialogTitle,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: artifact.fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: Uint8List.fromList(utf8.encode(artifact.content)),
    );
    return path != null;
  }

  Future<bool> _exportDatabaseBackup() async {
    setState(() => _isBackingUp = true);
    LocalDataBackupArtifact? artifact;
    try {
      artifact = await ref.read(localDataBackupServiceProvider).createBackup();
      final path = await FilePicker.saveFile(
        dialogTitle: '导出本地数据备份',
        fileName: artifact.fileName,
        type: FileType.custom,
        allowedExtensions: const ['db'],
        bytes: await artifact.readBytes(),
      );
      if (path == null || !mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('本地数据备份已导出'),
          backgroundColor: AppColors.green,
        ),
      );
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份失败: ${_backupErrorMessage(error)}')),
        );
      }
      return false;
    } finally {
      await artifact?.dispose();
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreDatabaseBackup() async {
    final selection = await FilePicker.pickFile(
      dialogTitle: '选择本地数据备份',
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );
    if (selection == null || !mounted) return;
    final sourcePath = selection.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法读取所选备份文件')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('替换本地学习数据？'),
        content: const Text(
          '恢复会用备份中的学习内容、学习记录和产品事件替换当前数据库。模型凭据、模型配置、首次运行状态和隐私偏好保持不变。\n\n恢复前会自动创建回滚快照；如果校验或迁移失败，应用会恢复当前数据。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('确认恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      final result = await ref
          .read(localDataBackupServiceProvider)
          .restoreBackup(sourcePath);
      invalidateDatabaseBackedProviders(ref);
      if (!mounted) return;
      final message =
          result.migrationApplied ? '恢复完成，旧版备份已升级到当前数据库版本' : '本地数据恢复完成';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.green),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复失败: ${_backupErrorMessage(error)}')),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _showDeleteDialog() async {
    final selected = <LocalDataScope>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('选择删除范围'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: LocalDataScope.values.map((scope) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(scope),
                  title: Text(scope.label),
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        selected.add(scope);
                      } else {
                        selected.remove(scope);
                      }
                    });
                  },
                );
              }).toList(growable: false),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton.icon(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('确认删除'),
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selected.isEmpty || !mounted) return;

    if (selected.any(_databaseBackedDeletionScopes.contains)) {
      final preparation = await _chooseDeletePreparation();
      if (preparation == null || preparation == _DeletePreparation.cancel) {
        return;
      }
      if (preparation == _DeletePreparation.backupThenDelete) {
        final saved = await _exportDatabaseBackup();
        if (!saved || !mounted) return;
      }
    }

    setState(() => _isDeleting = true);
    try {
      await ref.read(localDataDeletionServiceProvider).delete(selected);
      _invalidateDeletedData(selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('所选本地数据已删除'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $error')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<_DeletePreparation?> _chooseDeletePreparation() {
    return showDialog<_DeletePreparation>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除前是否备份？'),
        content: const Text(
          '数据库备份可以保存学习内容、学习记录和本地产品事件。模型凭据、模型配置、首次运行状态与隐私偏好不会进入备份。',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_DeletePreparation.cancel),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(_DeletePreparation.deleteDirectly),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('直接删除'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext)
                .pop(_DeletePreparation.backupThenDelete),
            icon: const Icon(Icons.download_outlined),
            label: const Text('备份后删除'),
          ),
        ],
      ),
    );
  }

  static String _backupErrorMessage(Object error) {
    if (error is LocalDataBackupException) return error.message;
    return error.toString();
  }

  void _invalidateDeletedData(Set<LocalDataScope> scopes) {
    if (scopes.contains(LocalDataScope.productEvents)) {
      ref.invalidate(productEventListProvider);
    }
    if (scopes.contains(LocalDataScope.onboardingState)) {
      ref.invalidate(firstRunProgressProvider);
    }
    if (scopes.contains(LocalDataScope.modelConfiguration)) {
      ref.invalidate(firstRunModelReadinessProvider);
    }

    final learningDataChanged =
        scopes.contains(LocalDataScope.learningHistory) ||
            scopes.contains(LocalDataScope.learningContent);
    if (!learningDataChanged) return;

    ref.invalidate(deckListProvider);
    ref.invalidate(knowledgePointListProvider);
    ref.invalidate(allQuestionsProvider);
    ref.invalidate(verifiedQuestionsProvider);
    ref.invalidate(pendingQuestionListProvider);
    ref.invalidate(learningSessionListProvider);
    ref.invalidate(agentSessionListProvider);
    ref.invalidate(agentSessionMemoryIndexProvider);
    ref.invalidate(todayReviewQueueProvider);
    ref.invalidate(userStatsProvider);

    if (scopes.contains(LocalDataScope.learningContent)) {
      ref.invalidate(sourceListProvider);
      ref.invalidate(allProgrammingExercisesProvider);
      ref.invalidate(allProgrammingExerciseAttemptsProvider);
      ref.invalidate(allProgrammingReviewActionsProvider);
      ref.invalidate(knowledgeSearchCorpusProvider);
    }
  }
}

const Set<LocalDataScope> _databaseBackedDeletionScopes = {
  LocalDataScope.learningHistory,
  LocalDataScope.learningContent,
  LocalDataScope.productEvents,
};

enum _DeletePreparation { cancel, deleteDirectly, backupThenDelete }

class _EventList extends StatelessWidget {
  final List<ProductEvent> events;

  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '暂无本地事件',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: events.map((event) {
        final properties = event.properties.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join(' · ');
        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_toggle_off_outlined),
              title: Text(
                event.name.value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  _timeText(event.occurredAt),
                  if (properties.isNotEmpty) properties,
                ].join('\n'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
          ],
        );
      }).toList(growable: false),
    );
  }

  static String _timeText(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.red)),
        ),
        IconButton(
          tooltip: '重试',
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
