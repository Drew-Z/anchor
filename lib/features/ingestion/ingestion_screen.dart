import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/ingestion/programming_source_import_service.dart';
import '../../services/ingestion/source_grounded_ingestion_service.dart';
import '../../shared/widgets/duo_button.dart';
import 'deck_preview_screen.dart';
import 'knowledge_review_screen.dart';
import 'project_import_screen.dart';

class IngestionScreen extends ConsumerStatefulWidget {
  final String? sharedText;
  final String? sharedImagePath;

  const IngestionScreen({
    super.key,
    this.sharedText,
    this.sharedImagePath,
  });

  @override
  ConsumerState<IngestionScreen> createState() => _IngestionScreenState();
}

class _IngestionScreenState extends ConsumerState<IngestionScreen> {
  final _textController = TextEditingController();
  final _titleController = TextEditingController();
  final _uriController = TextEditingController();
  final _publisherController = TextEditingController();
  final _revisionController = TextEditingController();
  final _licenseController = TextEditingController();
  String? _imagePath;
  String? _imageBase64;
  bool _isAnalyzing = false;
  String _statusText = '';
  String? _errorMessage;
  SourceTrustLevel _selectedTrustLevel = SourceTrustLevel.userNote;

  @override
  void initState() {
    super.initState();
    if (widget.sharedText != null && widget.sharedText!.isNotEmpty) {
      _textController.text = widget.sharedText!;
    }
    if (widget.sharedImagePath != null) {
      _imagePath = widget.sharedImagePath;
      _loadImageBase64();
    }
  }

  Future<void> _loadImageBase64() async {
    if (_imagePath == null) return;
    try {
      final file = File(_imagePath!);
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    } catch (e) {
      // 忽略图片加载错误
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipData = await Clipboard.getData('text/plain');
    if (clipData?.text != null && clipData!.text!.isNotEmpty) {
      setState(() {
        _textController.text = clipData.text!;
      });
    }
  }

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _imageBase64 == null) {
      setState(() => _errorMessage = '请输入或粘贴内容');
      return;
    }

    // 检查 API Key
    final openai = ref.read(openaiServiceProvider);
    final hasKey = await openai.hasApiKey();
    if (!hasKey) {
      setState(() => _errorMessage = '请先在设置中配置 OpenAI API Key');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _statusText = '正在分析内容...';
    });

    try {
      if (text.isNotEmpty) {
        await _analyzeTextWithSources(
          text,
          attachedImagePath: _imagePath,
        );
        return;
      }

      final analyzer = ref.read(contentAnalyzerProvider);

      setState(() => _statusText = 'AI 正在拆解知识点...');
      final result = await analyzer.analyze(
        text: text,
        imageBase64: _imageBase64,
      );

      setState(() => _statusText = '正在生成题目...');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isAnalyzing = false);
        // 跳转到预览页，用户确认后再保存
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DeckPreviewScreen(
              result: result,
              sourceText: text,
              sourceImage: _imagePath,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = '分析失败: $e';
        });
      }
    }
  }

  Future<void> _analyzeTextWithSources(
    String text, {
    String? attachedImagePath,
  }) async {
    final now = DateTime.now();
    final sourceId = now.microsecondsSinceEpoch.toString();
    final deckId = '${sourceId}_deck';
    final title = _titleController.text.trim().isEmpty
        ? _sourceTitleFor(text, now)
        : _titleController.text.trim();
    final enteredUri = _uriController.text.trim();
    final snapshot =
        ref.read(programmingSourceImportServiceProvider).buildSnapshot(
              draft: ProgrammingSourceImportDraft(
                title: title,
                content: text,
                trustLevel: _selectedTrustLevel,
                uri: enteredUri.isNotEmpty ? enteredUri : attachedImagePath,
                publisher: _publisherController.text,
                revision: _revisionController.text,
                licenseExpression: _licenseController.text,
              ),
              sourceId: sourceId,
              retrievedAt: now,
            );
    final source = snapshot.source;
    final chunks = snapshot.chunks;
    if (chunks.isEmpty) {
      throw StateError('没有可分析的文本片段');
    }
    final sourceGroundedIngestion =
        ref.read(sourceGroundedIngestionServiceProvider);

    setState(() => _statusText = 'AI 正在抽取有来源的知识点...');
    final extractionResult =
        await ref.read(knowledgeExtractionTaskProvider).run(
              sourceChunks: chunks,
            );
    if (!extractionResult.isSuccess) {
      throw StateError(extractionResult.errorMessage ?? '知识点抽取失败');
    }

    final buildResult = sourceGroundedIngestion.buildKnowledgePointDrafts(
      sourceId: sourceId,
      now: now,
      extractedKnowledgePoints: extractionResult.requireData.knowledgePoints,
    );

    setState(() => _statusText = 'AI 正在生成有引用的题目...');
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

    setState(() => _statusText = '正在预核验引用依据...');
    final verifiedQuestions = await sourceGroundedIngestion.precheckQuestions(
      questions: questions,
      chunks: chunks,
    );

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _statusText = '';
    });

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => KnowledgeReviewScreen(
          title: '$title 的学习内容',
          sources: [source],
          sourceChunks: chunks,
          knowledgePoints: buildResult.knowledgePoints,
          sourceChunkIdsByKnowledgePointId:
              buildResult.sourceChunkIdsByKnowledgePointId,
          questions: verifiedQuestions,
          onSave: (knowledgePointDecisions, questionDecisions) {
            return _saveReviewedContent(
              source: source,
              chunks: chunks,
              knowledgePointDecisions: knowledgePointDecisions,
              sourceChunkIdsByKnowledgePointId:
                  buildResult.sourceChunkIdsByKnowledgePointId,
              deckId: deckId,
              deckTitle: '$title 题目',
              questionDecisions: questionDecisions,
            );
          },
        ),
      ),
    );
  }

  String _sourceTitleFor(String text, DateTime now) {
    final firstLine = text
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isNotEmpty) {
      return firstLine.length <= 24
          ? firstLine
          : '${firstLine.substring(0, 24)}...';
    }
    return '文本导入 ${now.month}/${now.day} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
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
            deckSourceText: 'source:${source.id}',
            questionDecisions: questionDecisions,
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
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _uriController.dispose();
    _publisherController.dispose();
    _revisionController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加内容'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isAnalyzing ? _buildLoadingView() : _buildInputView(),
      ),
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: AppColors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '粘贴知识内容后，AI 会基于原文生成知识点和题目，并进入来源核验',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.blueDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 图片预览
          if (_imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_imagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.surface,
                  child:
                      const Center(child: Icon(Icons.broken_image, size: 48)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _ImageSourceHint(),
            const SizedBox(height: 12),
          ],
          // 文本输入区
          _SourceTrustSelector(
            value: _selectedTrustLevel,
            onChanged: (value) {
              setState(() => _selectedTrustLevel = value);
            },
          ),
          const SizedBox(height: 12),
          _ProgrammingSourceMetadataFields(
            trustLevel: _selectedTrustLevel,
            titleController: _titleController,
            uriController: _uriController,
            publisherController: _publisherController,
            revisionController: _revisionController,
            licenseController: _licenseController,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText:
                  '在此粘贴或输入要学习的内容...\n\n例如：\n• 知乎文章片段\n• 小红书知识笔记\n• 任何你想记住的内容',
              hintStyle: TextStyle(color: AppColors.textLight, height: 1.8),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 粘贴按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 20),
                  label: const Text('从粘贴板粘贴'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProjectImportScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.integration_instructions, size: 20),
                  label: const Text('导入项目材料'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 错误信息
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: AppColors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: AppColors.redDark, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // 开始拆解按钮
          DuoButton(
            label: 'AI 拆解为题目',
            color: AppColors.green,
            width: double.infinity,
            height: 56,
            icon: Icons.auto_awesome,
            fontSize: 18,
            onPressed: _analyze,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 动画图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.green,
                size: 40,
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .shimmer(duration: 1500.ms),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI 正在分析内容并生成题目，请稍候...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            // 进度指示器
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surface,
                color: AppColors.green,
                minHeight: 8,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceHint extends StatelessWidget {
  const _ImageSourceHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.goldDark, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '如果同时填写文字，文字会作为可引用来源进入核验；纯图片仍会保存为无来源题包。',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTrustSelector extends StatelessWidget {
  final SourceTrustLevel value;
  final ValueChanged<SourceTrustLevel> onChanged;

  const _SourceTrustSelector({
    required this.value,
    required this.onChanged,
  });

  static const _levels = [
    SourceTrustLevel.userNote,
    SourceTrustLevel.article,
    SourceTrustLevel.bookCourse,
    SourceTrustLevel.officialDoc,
    SourceTrustLevel.sourceCode,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '来源可信度',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _levels.map((level) {
              final selected = level == value;
              return ChoiceChip(
                label: Text(level.label),
                selected: selected,
                onSelected: (_) => onChanged(level),
                selectedColor: AppColors.greenLight,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected ? AppColors.green : AppColors.border,
                  width: 1.5,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.greenDark : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProgrammingSourceMetadataFields extends StatelessWidget {
  final SourceTrustLevel trustLevel;
  final TextEditingController titleController;
  final TextEditingController uriController;
  final TextEditingController publisherController;
  final TextEditingController revisionController;
  final TextEditingController licenseController;

  const _ProgrammingSourceMetadataFields({
    required this.trustLevel,
    required this.titleController,
    required this.uriController,
    required this.publisherController,
    required this.revisionController,
    required this.licenseController,
  });

  bool get _requiresProvenance =>
      trustLevel == SourceTrustLevel.officialDoc ||
      trustLevel == SourceTrustLevel.sourceCode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _requiresProvenance ? AppColors.green : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('source_metadata_${trustLevel.value}'),
            initiallyExpanded: _requiresProvenance,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            leading: Icon(
              Icons.fact_check_outlined,
              size: 20,
              color: _requiresProvenance
                  ? AppColors.greenDark
                  : AppColors.textSecondary,
            ),
            title: Text(
              _requiresProvenance ? '来源档案 · 必填' : '来源档案 · 可选',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _requiresProvenance
                    ? AppColors.greenDark
                    : AppColors.textPrimary,
              ),
            ),
            children: [
              TextField(
                controller: titleController,
                decoration: _decoration('来源标题', '例如：Python 3.14 官方文档'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: uriController,
                keyboardType: TextInputType.url,
                decoration: _decoration(
                  _requiresProvenance ? '规范来源 URL *' : '来源 URL',
                  'https://...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: publisherController,
                decoration: _decoration(
                  _requiresProvenance ? '发布者 / 仓库所有者 *' : '发布者',
                  '例如：Python Software Foundation',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: revisionController,
                decoration: _decoration(
                  _requiresProvenance ? '版本 / tag / commit *' : '版本 / revision',
                  '例如：3.14.6 或 commit SHA',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: licenseController,
                decoration: _decoration(
                  '许可表达式',
                  '例如：CC-BY-SA-2.5；不确定可留空',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
      ),
    );
  }
}
