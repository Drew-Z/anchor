import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/product_event.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/ingestion/project_source_import_service.dart';
import '../../services/ingestion/source_grounded_ingestion_service.dart';
import '../../services/privacy/product_event_recorder.dart';
import '../../shared/widgets/duo_button.dart';
import 'knowledge_review_screen.dart';

class ProjectImportResult {
  final String sourceId;
  final int selectedFileCount;
  final int excludedFileCount;
  final int selectedBytes;

  const ProjectImportResult({
    required this.sourceId,
    required this.selectedFileCount,
    required this.excludedFileCount,
    required this.selectedBytes,
  });
}

typedef ProjectMaterialPersistedCallback = Future<void> Function(
  ProjectImportResult result,
);

class ProjectImportScreen extends ConsumerStatefulWidget {
  final bool localMaterialOnly;
  final ProjectMaterialPersistedCallback? onMaterialPersisted;
  final String? eventFlowId;
  final String? eventGoal;

  const ProjectImportScreen({
    super.key,
    this.localMaterialOnly = false,
    this.onMaterialPersisted,
    this.eventFlowId,
    this.eventGoal,
  });

  @override
  ConsumerState<ProjectImportScreen> createState() =>
      _ProjectImportScreenState();
}

class _ProjectImportScreenState extends ConsumerState<ProjectImportScreen> {
  static const _maxAnalysisBytes = 256 * 1024;
  static const _maxAnalysisFiles = 40;

  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _techStackController = TextEditingController();
  final _readmeController = TextEditingController();
  final _treeController = TextEditingController();
  final _codePathController = TextEditingController();
  final _codeStartLineController = TextEditingController();
  final _codeEndLineController = TextEditingController();
  final _codeController = TextEditingController();
  final _focusController = TextEditingController();

  bool _isSaving = false;
  bool _isScanning = false;
  String? _errorMessage;
  String _statusMessage = '';
  ProjectSourceSnapshot? _projectSnapshot;
  Set<String> _selectedProjectPaths = {};
  late final String _eventFlowId = widget.eventFlowId ??
      'project_import_${DateTime.now().toUtc().microsecondsSinceEpoch}';

  String get _eventGoal => widget.eventGoal ?? 'unknown';

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _techStackController.dispose();
    _readmeController.dispose();
    _treeController.dispose();
    _codePathController.dispose();
    _codeStartLineController.dispose();
    _codeEndLineController.dispose();
    _codeController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    final projectName = _nameController.text.trim();
    if (projectName.isEmpty) {
      setState(() => _errorMessage = '请输入项目名称');
      return;
    }

    if (_selectedProjectBytes > _maxAnalysisBytes ||
        _selectedProjectPaths.length > _maxAnalysisFiles) {
      setState(() {
        _errorMessage =
            '当前选择 ${_selectedProjectPaths.length} 个文件、${_formatBytes(_selectedProjectBytes)}，'
            '单次分析最多 $_maxAnalysisFiles 个文件、${_formatBytes(_maxAnalysisBytes)}';
      });
      return;
    }

    if (!widget.localMaterialOnly) {
      final openai = ref.read(openaiServiceProvider);
      final hasKey = await openai.hasApiKey();
      if (!hasKey) {
        setState(() => _errorMessage = '请先在设置中配置 AI API Key');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _statusMessage = '正在保存项目材料...';
    });

    try {
      if (_projectSnapshot == null) {
        await _recordImportStarted('manual');
      }
      final now = DateTime.now();
      final sourceId = now.microsecondsSinceEpoch.toString();
      final deckId = '${sourceId}_deck';

      final source = Source(
        id: sourceId,
        title: projectName,
        type: SourceType.project,
        uri: _projectSnapshot?.sourceUri,
        revision: _projectSnapshot?.revision,
        trustLevel: SourceTrustLevel.sourceCode,
        createdAt: now,
        updatedAt: now,
      );

      final chunks = _buildChunks(sourceId, now);
      if (chunks.isEmpty) {
        throw StateError('请至少填写 README、目录结构或关键代码片段中的一项');
      }
      final sourceGroundedIngestion =
          ref.read(sourceGroundedIngestionServiceProvider);

      if (widget.localMaterialOnly) {
        _updateStatus('正在保存本地项目材料...');
        await sourceGroundedIngestion.saveSourceMaterial(
          source: source,
          chunks: chunks,
        );
        ref.invalidate(sourceListProvider);
        ref.invalidate(sourceProvider(source.id));
        ref.invalidate(sourceChunksProvider(source.id));

        final result = ProjectImportResult(
          sourceId: source.id,
          selectedFileCount: _selectedProjectPaths.length,
          excludedFileCount: _projectSnapshot?.exclusions.length ?? 0,
          selectedBytes: _selectedProjectBytes,
        );
        await widget.onMaterialPersisted?.call(result);
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('项目材料已保存在本机'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.of(context).pop(result);
        return;
      }

      _updateStatus('AI 正在生成项目理解...');
      final understandingResult =
          await ref.read(projectUnderstandingTaskProvider).run(
                sourceChunks: chunks,
              );
      if (!understandingResult.isSuccess) {
        throw StateError(
          understandingResult.errorMessage ?? '项目理解生成失败',
        );
      }

      final buildResult =
          sourceGroundedIngestion.buildProjectUnderstandingDrafts(
        sourceId: sourceId,
        now: now,
        units: understandingResult.requireData.units,
      );

      _updateStatus('AI 正在生成练习题...');
      final questionResult = await ref.read(questionGenerationTaskProvider).run(
            knowledgePoints: buildResult.knowledgePoints,
            sourceChunks: chunks,
            questionCount: sourceGroundedIngestion.questionCountFor(
              buildResult.knowledgePoints.length,
            ),
          );
      if (!questionResult.isSuccess) {
        throw StateError(questionResult.errorMessage ?? '题目生成失败');
      }

      final questions = questionResult.requireData.questions
          .map((draft) => draft.toQuestion(deckId: deckId))
          .toList();

      _updateStatus('正在预核验引用依据...');
      final verifiedQuestions = await sourceGroundedIngestion.precheckQuestions(
        questions: questions,
        chunks: chunks,
      );

      // 新增:质量验证 - 确保 AI 生成的题目事实准确
      _updateStatus('正在验证题目事实准确性...');
      final validator = ref.read(questionValidatorProvider);
      final validationResults = await validator.validateBatch(
        questions: verifiedQuestions,
        sourceChunks: chunks,
      );

      // 在 explanation 中标记验证问题(低置信度题目)
      final qualityCheckedQuestions = verifiedQuestions.map((q) {
        final validation = validationResults[q.id];
        if (validation == null || validation.isValid) {
          return q;
        }
        // 添加验证警告到解析中
        final warningText =
            '\n\n⚠️ 验证发现以下问题:\n${validation.issues.map((i) => '• $i').join('\n')}\n(置信度: ${(validation.confidence * 100).toInt()}%)';
        return q.copyWith(
          explanation: (q.explanation ?? '') + warningText,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _statusMessage = '';
      });
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KnowledgeReviewScreen(
            title: '$projectName 的学习内容',
            sources: [source],
            sourceChunks: chunks,
            knowledgePoints: buildResult.knowledgePoints,
            sourceChunkIdsByKnowledgePointId:
                buildResult.sourceChunkIdsByKnowledgePointId,
            questions: qualityCheckedQuestions,
            onSave: (knowledgePointDecisions, questionDecisions) {
              return _saveReviewedContent(
                source: source,
                chunks: chunks,
                knowledgePointDecisions: knowledgePointDecisions,
                sourceChunkIdsByKnowledgePointId:
                    buildResult.sourceChunkIdsByKnowledgePointId,
                deckId: deckId,
                deckTitle: '$projectName 面试题',
                questionDecisions: questionDecisions,
              );
            },
          ),
        ),
      );
    } catch (e) {
      await _recordImportFailure(e, phase: 'save');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = '';
          _errorMessage = '保存失败: $e';
        });
      }
    }
  }

  Future<void> _pickProjectDirectory() async {
    await _recordImportStarted('directory');
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final bridge = ref.read(androidProjectDirectoryBridgeProvider);
        final selection = await bridge.pickDirectory();
        if (selection == null) return;
        final service = ref.read(projectSourceImportServiceProvider);
        await _loadProjectSnapshot(
          bridge
              .listDirectory(
                treeUri: selection.sourceUri,
                maxFileBytes: service.policy.maxFileBytes,
              )
              .then(
                (entries) => service.scanDirectoryEntries(
                  displayName: selection.displayName,
                  sourceUri: selection.sourceUri,
                  entries: entries,
                ),
              ),
        );
        return;
      }

      final directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择项目目录',
      );
      if (directoryPath == null) return;
      await _loadProjectSnapshot(
        ref.read(projectSourceImportServiceProvider).scanDirectory(
              directoryPath,
            ),
      );
    } catch (error) {
      await _showScanError(error);
    }
  }

  Future<void> _pickProjectZip() async {
    await _recordImportStarted('zip');
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择项目 ZIP',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final service = ref.read(projectSourceImportServiceProvider);
      final future = file.path == null
          ? file.xFile.readAsBytes().then(
                (bytes) => service.scanZipBytes(
                  archiveName: file.name,
                  bytes: bytes,
                  sourceUri: file.name,
                ),
              )
          : service.scanZipFile(file.path!);
      await _loadProjectSnapshot(future);
    } catch (error) {
      await _showScanError(error);
    }
  }

  Future<void> _loadProjectSnapshot(
    Future<ProjectSourceSnapshot> future,
  ) async {
    final startedAt = DateTime.now();
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _statusMessage = '正在扫描项目源码...';
    });

    try {
      final snapshot = await future;
      final selectedCount =
          snapshot.files.where((file) => file.selectedByDefault).length;
      final totalBytes = snapshot.files.fold<int>(
        0,
        (total, file) => total + file.byteLength,
      );
      await ref.read(productEventRecorderProvider).recordBestEffort(
        ProductEventName.projectScanCompleted,
        flowId: _eventFlowId,
        goal: _eventGoal,
        properties: {
          'selected_count': selectedCount,
          'excluded_count': snapshot.exclusions.length,
          'total_bytes_bucket':
              ProductEventRecorder.byteCountBucket(totalBytes),
          'duration_bucket': ProductEventRecorder.durationBucket(
            DateTime.now().difference(startedAt),
          ),
        },
      );
      if (!mounted) return;
      setState(() {
        _projectSnapshot = snapshot;
        _selectedProjectPaths = snapshot.files
            .where((file) => file.selectedByDefault)
            .map((file) => file.relativePath)
            .toSet();
        _isScanning = false;
        _statusMessage =
            '已发现 ${snapshot.files.length} 个可学习文件，自动排除 ${snapshot.exclusions.length} 个文件';
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = snapshot.displayName;
        }
      });
    } catch (error) {
      await _showScanError(error);
    }
  }

  Future<void> _showScanError(Object error) async {
    await _recordImportFailure(error, phase: 'scan');
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _statusMessage = '';
      _errorMessage = '项目扫描失败: $error';
    });
  }

  Future<void> _recordImportStarted(String importType) {
    return ref.read(productEventRecorderProvider).recordBestEffort(
      ProductEventName.projectImportStarted,
      flowId: _eventFlowId,
      goal: _eventGoal,
      properties: {'import_type': importType},
    );
  }

  Future<void> _recordImportFailure(
    Object error, {
    required String phase,
  }) {
    final failureCode = switch (error) {
      ProjectSourceReadLimitException() => 'read_limit_exceeded',
      FormatException() => 'invalid_format',
      StateError() => 'invalid_input',
      _ => 'unexpected_failure',
    };
    return ref.read(productEventRecorderProvider).recordBestEffort(
      ProductEventName.projectImportFailed,
      flowId: _eventFlowId,
      goal: _eventGoal,
      properties: {
        'failure_code': failureCode,
        'phase': phase,
      },
    );
  }

  int get _selectedProjectBytes {
    final snapshot = _projectSnapshot;
    if (snapshot == null) return 0;
    return snapshot.files
        .where((file) => _selectedProjectPaths.contains(file.relativePath))
        .fold(0, (total, file) => total + file.byteLength);
  }

  void _toggleProjectFile(String relativePath, bool selected) {
    setState(() {
      if (selected) {
        _selectedProjectPaths.add(relativePath);
      } else {
        _selectedProjectPaths.remove(relativePath);
      }
      _errorMessage = null;
    });
  }

  void _selectRecommendedProjectFiles() {
    final snapshot = _projectSnapshot;
    if (snapshot == null) return;
    setState(() {
      _selectedProjectPaths = snapshot.files
          .where((file) => file.selectedByDefault)
          .map((file) => file.relativePath)
          .toSet();
      _errorMessage = null;
    });
  }

  void _selectAllProjectFiles() {
    final snapshot = _projectSnapshot;
    if (snapshot == null) return;
    setState(() {
      _selectedProjectPaths =
          snapshot.files.map((file) => file.relativePath).toSet();
      _errorMessage = null;
    });
  }

  void _clearProjectFileSelection() {
    setState(() {
      _selectedProjectPaths = {};
      _errorMessage = null;
    });
  }

  void _updateStatus(String message) {
    if (!mounted) return;
    setState(() => _statusMessage = message);
  }

  Future<void> _saveReviewedContent({
    required Source source,
    required List<SourceChunk> chunks,
    required List<SourceGroundedKnowledgePointDecision> knowledgePointDecisions,
    required Map<String, List<String>> sourceChunkIdsByKnowledgePointId,
    required String deckId,
    required String deckTitle,
    required List<SourceGroundedQuestionDecision> questionDecisions,
  }) async {
    final result = await ref
        .read(sourceGroundedIngestionServiceProvider)
        .saveReviewedContent(
          SourceGroundedSaveRequest(
            source: source,
            chunks: chunks,
            knowledgePointDecisions: knowledgePointDecisions,
            sourceChunkIdsByKnowledgePointId: sourceChunkIdsByKnowledgePointId,
            deckId: deckId,
            deckTitle: deckTitle,
            deckSourceText: 'project:${source.id}',
            questionDecisions: questionDecisions,
            eventFlowId: _eventFlowId,
            eventGoal: _eventGoal,
          ),
        );

    if (result.savedKnowledgePointCount == 0 &&
        result.savedQuestionCount == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('至少确认一个知识单元或保留一道题目'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final includedCount =
        result.savedKnowledgePointCount + result.savedQuestionCount;
    await ref.read(productEventRecorderProvider).recordBestEffort(
          ProductEventName.coverageReviewCompleted,
          flowId: _eventFlowId,
          goal: _eventGoal,
          properties: {
            'included_count': includedCount,
            'excluded_count': knowledgePointDecisions.length +
                questionDecisions.length -
                includedCount,
            'locator_coverage': _locatorCoverage(chunks),
          },
          dedupeKey: 'coverage_review_completed:${source.id}',
        );

    ref.invalidate(deckListProvider);
    ref.invalidate(sourceListProvider);
    ref.invalidate(sourceProvider(source.id));
    ref.invalidate(sourceChunksProvider(source.id));
    ref.invalidate(sourceKnowledgePointsProvider(source.id));
    ref.invalidate(knowledgePointListProvider);
    ref.invalidate(evidenceBackedKnowledgePointListProvider);
    ref.invalidate(practiceableKnowledgePointListProvider);
    ref.invalidate(pendingQuestionListProvider);
    ref.invalidate(allQuestionsProvider);
    ref.invalidate(verifiedQuestionsProvider);
    ref.invalidate(deckQuestionsProvider(deckId));
    ref.invalidate(verifiedDeckQuestionsProvider(deckId));
    ref.invalidate(todayReviewQueueProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '已保存 ${result.savedKnowledgePointCount} 个知识单元、'
          '${result.savedQuestionCount} 道题目',
        ),
        backgroundColor: AppColors.green,
      ),
    );
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  String _locatorCoverage(List<SourceChunk> chunks) {
    if (chunks.isEmpty) return 'none';
    final located = chunks.where((chunk) {
      return (chunk.locator?.trim().isNotEmpty ?? false) ||
          (chunk.relativePath?.trim().isNotEmpty ?? false);
    }).length;
    if (located == 0) return 'none';
    if (located == chunks.length) return 'complete';
    return 'partial';
  }

  List<SourceChunk> _buildChunks(String sourceId, DateTime createdAt) {
    final chunks = <SourceChunk>[];
    final snapshot = _projectSnapshot;
    if (snapshot != null && _selectedProjectPaths.isNotEmpty) {
      chunks.addAll(
        ref.read(projectSourceImportServiceProvider).buildSourceChunks(
              snapshot: snapshot,
              selectedPaths: _selectedProjectPaths,
              sourceId: sourceId,
              createdAt: createdAt,
            ),
      );
    }

    final entries = <({String locator, String content})>[
      (
        locator: 'project-metadata',
        content: [
          if (_goalController.text.trim().isNotEmpty)
            '项目目标：${_goalController.text.trim()}',
          if (_techStackController.text.trim().isNotEmpty)
            '技术栈：${_techStackController.text.trim()}',
          if (_focusController.text.trim().isNotEmpty)
            '面试重点：${_focusController.text.trim()}',
        ].join('\n'),
      ),
      (locator: 'README.md', content: _readmeController.text.trim()),
      (locator: 'project-tree', content: _treeController.text.trim()),
      (locator: _codeLocator(), content: _codeController.text.trim()),
    ].where((entry) => entry.content.trim().isNotEmpty).toList();

    for (final entry in entries) {
      final index = chunks.length;
      final value = entry;
      final content = value.content;
      chunks.add(SourceChunk(
        id: '${sourceId}_chunk_$index',
        sourceId: sourceId,
        chunkIndex: index,
        locator: value.locator,
        content: content,
        contentHash: sha256.convert(utf8.encode(content)).toString(),
        createdAt: createdAt,
      ));
    }
    return chunks;
  }

  String _codeLocator() {
    final path = _codePathController.text.trim();
    final start = _codeStartLineController.text.trim();
    final end = _codeEndLineController.text.trim();

    if (path.isEmpty) return 'manual-code-snippets';
    if (start.isEmpty && end.isEmpty) return path;
    if (start.isNotEmpty && end.isNotEmpty) return '$path:$start-$end';
    return '$path:${start.isNotEmpty ? start : end}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入项目')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProjectSourcePicker(
                snapshot: _projectSnapshot,
                selectedPaths: _selectedProjectPaths,
                selectedBytes: _selectedProjectBytes,
                isScanning: _isScanning,
                onPickDirectory: _pickProjectDirectory,
                onPickZip: _pickProjectZip,
                onToggleFile: _toggleProjectFile,
                onSelectRecommended: _selectRecommendedProjectFiles,
                onSelectAll: _selectAllProjectFiles,
                onClearSelection: _clearProjectFileSelection,
              ),
              const SizedBox(height: 20),
              _ProjectTextField(
                controller: _nameController,
                label: '项目名称',
                hintText: '例如：Duoduo Learn',
              ),
              _ProjectTextField(
                controller: _goalController,
                label: '项目目标',
                hintText: '这个项目解决什么问题？',
                maxLines: 3,
              ),
              _ProjectTextField(
                controller: _techStackController,
                label: '技术栈',
                hintText: 'Flutter, Riverpod, SQLite, OpenAI-compatible API...',
                maxLines: 2,
              ),
              _ProjectTextField(
                controller: _readmeController,
                label: 'README / 项目说明',
                hintText: '粘贴 README 或你自己的项目说明',
                maxLines: 8,
              ),
              _ProjectTextField(
                controller: _treeController,
                label: '目录结构',
                hintText: '粘贴项目目录树',
                maxLines: 8,
              ),
              _ProjectTextField(
                controller: _codePathController,
                label: '关键代码文件路径',
                hintText: '例如：lib/services/content_analyzer.dart',
              ),
              Row(
                children: [
                  Expanded(
                    child: _ProjectTextField(
                      controller: _codeStartLineController,
                      label: '起始行',
                      hintText: '例如：19',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProjectTextField(
                      controller: _codeEndLineController,
                      label: '结束行',
                      hintText: '例如：105',
                    ),
                  ),
                ],
              ),
              _ProjectTextField(
                controller: _codeController,
                label: '关键代码片段',
                hintText: '粘贴你希望面试时讲清楚的关键代码',
                maxLines: 10,
              ),
              _ProjectTextField(
                controller: _focusController,
                label: '重点面试方向',
                hintText: '例如：AI 调用链路、状态管理、数据库设计',
                maxLines: 3,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (_statusMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              DuoButton(
                label: _isSaving
                    ? (widget.localMaterialOnly ? '保存中...' : '生成中...')
                    : (widget.localMaterialOnly ? '保存本地项目材料' : '生成并核验学习内容'),
                color: AppColors.green,
                width: double.infinity,
                height: 56,
                icon: widget.localMaterialOnly
                    ? Icons.save_outlined
                    : Icons.auto_awesome,
                enabled: !_isSaving && !_isScanning,
                onPressed: _saveProject,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectSourcePicker extends StatelessWidget {
  final ProjectSourceSnapshot? snapshot;
  final Set<String> selectedPaths;
  final int selectedBytes;
  final bool isScanning;
  final VoidCallback onPickDirectory;
  final VoidCallback onPickZip;
  final void Function(String relativePath, bool selected) onToggleFile;
  final VoidCallback onSelectRecommended;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  const _ProjectSourcePicker({
    required this.snapshot,
    required this.selectedPaths,
    required this.selectedBytes,
    required this.isScanning,
    required this.onPickDirectory,
    required this.onPickZip,
    required this.onToggleFile,
    required this.onSelectRecommended,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final currentSnapshot = snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '项目源码',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isScanning ? null : onPickDirectory,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择目录'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isScanning ? null : onPickZip,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('选择 ZIP'),
              ),
            ),
          ],
        ),
        if (isScanning) ...[
          const SizedBox(height: 14),
          const LinearProgressIndicator(),
        ],
        if (currentSnapshot != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      currentSnapshot.kind == ProjectSourceImportKind.directory
                          ? Icons.folder_copy_outlined
                          : Icons.folder_zip_outlined,
                      color: AppColors.greenDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentSnapshot.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '已选 ${selectedPaths.length}/${currentSnapshot.files.length} 个文件 · ${_formatBytes(selectedBytes)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  currentSnapshot.revision,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: onSelectRecommended,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('推荐'),
                    ),
                    TextButton.icon(
                      onPressed: onSelectAll,
                      icon: const Icon(Icons.select_all, size: 18),
                      label: const Text('全选'),
                    ),
                    TextButton.icon(
                      onPressed: onClearSelection,
                      icon: const Icon(Icons.deselect, size: 18),
                      label: const Text('清空'),
                    ),
                  ],
                ),
                if (currentSnapshot.files.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: currentSnapshot.files.length,
                      itemBuilder: (context, index) {
                        final file = currentSnapshot.files[index];
                        final selected = selectedPaths.contains(
                          file.relativePath,
                        );
                        return CheckboxListTile(
                          value: selected,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            file.relativePath,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${file.lineCount} 行 · ${_formatBytes(file.byteLength)}',
                          ),
                          onChanged: (value) {
                            onToggleFile(file.relativePath, value ?? false);
                          },
                        );
                      },
                    ),
                  ),
                if (currentSnapshot.exclusions.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(
                    '已自动排除 ${currentSnapshot.exclusions.length} 个生成、敏感、二进制或超限文件',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}

class _ProjectTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final int maxLines;

  const _ProjectTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.textLight),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.green, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
