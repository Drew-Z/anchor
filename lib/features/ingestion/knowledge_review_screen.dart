import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/ingestion/question_bulk_verification_service.dart';
import '../../services/ingestion/source_grounded_ingestion_service.dart';
import '../../shared/widgets/anchor_button.dart';
import 'project_code_walkthrough_screen.dart';

typedef KnowledgeReviewSaveCallback = Future<void> Function(
  List<SourceGroundedKnowledgePointDecision> knowledgePointDecisions,
  List<SourceGroundedQuestionDecision> questionDecisions,
);

class KnowledgeReviewScreen extends StatefulWidget {
  final String title;
  final List<Source> sources;
  final List<SourceChunk> sourceChunks;
  final List<KnowledgePoint> knowledgePoints;
  final Map<String, List<String>> sourceChunkIdsByKnowledgePointId;
  final List<Question> questions;
  final KnowledgeReviewSaveCallback? onSave;

  const KnowledgeReviewScreen({
    super.key,
    required this.title,
    this.sources = const [],
    this.sourceChunks = const [],
    this.knowledgePoints = const [],
    this.sourceChunkIdsByKnowledgePointId = const {},
    this.questions = const [],
    this.onSave,
  });

  @override
  State<KnowledgeReviewScreen> createState() => _KnowledgeReviewScreenState();
}

class _KnowledgeReviewScreenState extends State<KnowledgeReviewScreen> {
  late final Map<String, KnowledgePoint> _editedKnowledgePoints;
  final Set<String> _approvedKnowledgePointIds = {};
  final Set<String> _deletedKnowledgePointIds = {};
  late final Map<String, SourceStatus> _questionStatuses;
  late final Map<String, Question> _editedQuestions;
  final Set<String> _deletedQuestionKeys = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editedKnowledgePoints = {
      for (final point in widget.knowledgePoints) point.id: point,
    };
    _questionStatuses = {
      for (final entry in widget.questions.asMap().entries)
        _questionKey(entry.key, entry.value): entry.value.sourceStatus,
    };
    _editedQuestions = {
      for (final entry in widget.questions.asMap().entries)
        _questionKey(entry.key, entry.value): entry.value,
    };
  }

  String _questionKey(int index, Question question) {
    return question.id.isEmpty ? 'draft_$index' : question.id;
  }

  void _setStatus(String key, SourceStatus status) {
    setState(() {
      _questionStatuses[key] = status;
    });
  }

  void _deleteQuestion(String key) {
    setState(() {
      _deletedQuestionKeys.add(key);
    });
  }

  void _verifyAllQuestionsWithReadableCitations() {
    final currentQuestions = widget.questions.asMap().entries.map((entry) {
      final key = _questionKey(entry.key, entry.value);
      final question = _editedQuestions[key] ?? entry.value;
      return question.copyWith(
        sourceStatus: _questionStatuses[key] ?? question.sourceStatus,
      );
    }).toList();
    final ignoredIndexes = widget.questions
        .asMap()
        .entries
        .where(
          (entry) => _deletedQuestionKeys.contains(
            _questionKey(entry.key, entry.value),
          ),
        )
        .map((entry) => entry.key)
        .toSet();
    final plan = const QuestionBulkVerificationService().buildPlan(
      questions: currentQuestions,
      readableCitationIds: widget.sourceChunks.map((chunk) => chunk.id).toSet(),
      ignoredIndexes: ignoredIndexes,
    );

    if (!plan.hasUpdates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有引用片段仍可读取的待核验题目'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() {
      for (final update in plan.updates) {
        final original = widget.questions[update.index];
        final key = _questionKey(update.index, original);
        _editedQuestions[key] = update.question;
        _questionStatuses[key] = SourceStatus.verified;
      }
    });
    final skipped = plan.skippedPendingCount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skipped == 0
              ? '已批量核验 ${plan.updates.length} 道有有效引用的题目'
              : '已批量核验 ${plan.updates.length} 道题，$skipped 道仍需单独处理',
        ),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _approveKnowledgePoint(String pointId) {
    if (!_hasReadableEvidence(pointId)) return;
    setState(() {
      _deletedKnowledgePointIds.remove(pointId);
      _approvedKnowledgePointIds.add(pointId);
    });
  }

  void _approveAllKnowledgePoints() {
    setState(() {
      for (final point in widget.knowledgePoints) {
        if (!_deletedKnowledgePointIds.contains(point.id) &&
            _hasReadableEvidence(point.id)) {
          _approvedKnowledgePointIds.add(point.id);
        }
      }
    });
  }

  bool _hasReadableEvidence(String pointId) {
    final knownChunkIds = widget.sourceChunks.map((chunk) => chunk.id).toSet();
    return (widget.sourceChunkIdsByKnowledgePointId[pointId] ?? const [])
        .any(knownChunkIds.contains);
  }

  void _deleteKnowledgePoint(String pointId) {
    setState(() {
      _approvedKnowledgePointIds.remove(pointId);
      _deletedKnowledgePointIds.add(pointId);
      for (final entry in widget.questions.asMap().entries) {
        final question =
            _editedQuestions[_questionKey(entry.key, entry.value)] ??
                entry.value;
        if (question.knowledgePointId == pointId) {
          _deletedQuestionKeys.add(_questionKey(entry.key, entry.value));
        }
      }
    });
  }

  Future<void> _editKnowledgePoint(KnowledgePoint point) async {
    final titleController = TextEditingController(text: point.title);
    final summaryController = TextEditingController(text: point.summary);
    final tagsController = TextEditingController(text: point.tags.join(', '));
    var selectedKind = point.kind;
    String? validationMessage;

    try {
      final updated = await showDialog<KnowledgePoint>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('编辑知识单元'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<KnowledgePointKind>(
                        initialValue: selectedKind,
                        decoration: const InputDecoration(labelText: '类型'),
                        items: KnowledgePointKind.values
                            .map(
                              (kind) => DropdownMenuItem(
                                value: kind,
                                child: Text(kind.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) selectedKind = value;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: '标题'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: summaryController,
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: '项目理解'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: '标签',
                          hintText: '使用逗号分隔',
                        ),
                      ),
                      if (validationMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          validationMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final summary = summaryController.text.trim();
                      if (title.isEmpty || summary.isEmpty) {
                        setDialogState(() {
                          validationMessage = '标题和项目理解不能为空';
                        });
                        return;
                      }
                      final tags = tagsController.text
                          .split(RegExp(r'[,，]'))
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toSet()
                          .toList();
                      Navigator.pop(
                        dialogContext,
                        point.copyWith(
                          title: title,
                          summary: summary,
                          kind: selectedKind,
                          tags: tags,
                          updatedAt: DateTime.now(),
                        ),
                      );
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || updated == null) return;
      setState(() {
        _editedKnowledgePoints[point.id] = updated;
        _approvedKnowledgePointIds.remove(point.id);
      });
    } finally {
      titleController.dispose();
      summaryController.dispose();
      tagsController.dispose();
    }
  }

  Future<void> _editQuestion(String key, Question question) async {
    final contentController = TextEditingController(text: question.content);
    final answerController = TextEditingController(text: question.answer);
    final explanationController =
        TextEditingController(text: question.explanation ?? '');

    try {
      final updated = await showDialog<Question>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('编辑题目'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: '题干'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: answerController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: '答案'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: explanationController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: '解析'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    question.copyWith(
                      content: contentController.text.trim(),
                      answer: answerController.text.trim(),
                      explanation: explanationController.text.trim(),
                      sourceStatus: SourceStatus.pending,
                    ),
                  );
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      );

      if (!mounted || updated == null) return;
      setState(() {
        _editedQuestions[key] = updated;
        _questionStatuses[key] = SourceStatus.pending;
      });
    } finally {
      contentController.dispose();
      answerController.dispose();
      explanationController.dispose();
    }
  }

  Future<void> _save() async {
    final onSave = widget.onSave;
    if (onSave == null || _isSaving) return;

    final unresolvedCount = widget.knowledgePoints.where((point) {
      return !_approvedKnowledgePointIds.contains(point.id) &&
          !_deletedKnowledgePointIds.contains(point.id);
    }).length;
    if (unresolvedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('还有 $unresolvedCount 个知识单元待确认或删除'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final knowledgePointDecisions = widget.knowledgePoints.map((point) {
      return SourceGroundedKnowledgePointDecision(
        knowledgePoint: _editedKnowledgePoints[point.id] ?? point,
        approved: _approvedKnowledgePointIds.contains(point.id),
        deleted: _deletedKnowledgePointIds.contains(point.id),
      );
    }).toList();

    final questionDecisions = widget.questions.asMap().entries.map((entry) {
      final key = _questionKey(entry.key, entry.value);
      final question = _editedQuestions[key] ?? entry.value;
      final pointId = question.knowledgePointId;
      return SourceGroundedQuestionDecision(
        question: question,
        sourceStatus: _questionStatuses[key] ?? SourceStatus.noSource,
        deleted: _deletedQuestionKeys.contains(key) ||
            (pointId != null && !_approvedKnowledgePointIds.contains(pointId)),
      );
    }).toList();

    setState(() => _isSaving = true);
    try {
      await onSave(knowledgePointDecisions, questionDecisions);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _openCodeWalkthrough(
    List<KnowledgePoint> knowledgePoints,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectCodeWalkthroughScreen(
          knowledgePoints: knowledgePoints,
          sourceChunks: widget.sourceChunks,
          sourceChunkIdsByKnowledgePointId:
              widget.sourceChunkIdsByKnowledgePointId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chunksById = {
      for (final chunk in widget.sourceChunks) chunk.id: chunk,
    };
    final visibleKnowledgePoints = widget.knowledgePoints
        .where((point) => !_deletedKnowledgePointIds.contains(point.id))
        .map((point) => _editedKnowledgePoints[point.id] ?? point)
        .toList();
    final pointsById = {
      for (final point in visibleKnowledgePoints) point.id: point,
    };
    final visibleQuestions = widget.questions.asMap().entries.where((entry) {
      return !_deletedQuestionKeys
          .contains(_questionKey(entry.key, entry.value));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('知识核验')),
      body: Column(
        children: [
          _ReviewHeader(
            title: widget.title,
            sourceCount: widget.sources.length,
            pointCount: visibleKnowledgePoints.length,
            approvedPointCount: _approvedKnowledgePointIds.length,
            questionCount: visibleQuestions.length,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.sources.isNotEmpty) ...[
                  const _SectionTitle(label: '来源'),
                  ...widget.sources.map(_SourceCard.new),
                  const SizedBox(height: 16),
                ],
                if (visibleKnowledgePoints.isNotEmpty) ...[
                  _KnowledgePointSectionHeader(
                    onApproveAll: _approveAllKnowledgePoints,
                    onOpenWalkthrough: visibleKnowledgePoints.any(
                      (point) => point.kind.isProjectUnderstanding,
                    )
                        ? () => _openCodeWalkthrough(visibleKnowledgePoints)
                        : null,
                  ),
                  ...visibleKnowledgePoints.map((point) {
                    final evidenceChunks =
                        (widget.sourceChunkIdsByKnowledgePointId[point.id] ??
                                const <String>[])
                            .map((id) => chunksById[id])
                            .whereType<SourceChunk>()
                            .toList();
                    return _KnowledgePointCard(
                      key: ValueKey('knowledge_point_${point.id}'),
                      point: point,
                      evidenceChunks: evidenceChunks,
                      approved: _approvedKnowledgePointIds.contains(point.id),
                      onApprove: () => _approveKnowledgePoint(point.id),
                      onEdit: () => _editKnowledgePoint(point),
                      onDelete: () => _deleteKnowledgePoint(point.id),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                if (visibleQuestions.isNotEmpty) ...[
                  _QuestionReviewSectionHeader(
                    onVerifyAll: _verifyAllQuestionsWithReadableCitations,
                  ),
                  ...visibleQuestions.map(
                    (entry) {
                      final key = _questionKey(entry.key, entry.value);
                      final question = _editedQuestions[key] ?? entry.value;
                      final sourceStatus =
                          _questionStatuses[key] ?? SourceStatus.noSource;
                      final citationChunks =
                          sourceStatus == SourceStatus.noSource
                              ? <SourceChunk>[]
                              : question.citationIds
                                  .map((id) => chunksById[id])
                                  .whereType<SourceChunk>()
                                  .toList();
                      return _QuestionReviewCard(
                        question: question,
                        sourceStatus: sourceStatus,
                        knowledgePoint: question.knowledgePointId == null
                            ? null
                            : pointsById[question.knowledgePointId],
                        citationChunks: citationChunks,
                        onStatusChanged: (status) => _setStatus(key, status),
                        onDelete: () => _deleteQuestion(key),
                        onEdit: () => _editQuestion(key, question),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: SafeArea(
              child: AnchorButton(
                label: _isSaving ? '保存中...' : '保存已核验内容',
                color: AppColors.green,
                width: double.infinity,
                height: 56,
                icon: Icons.check,
                enabled: widget.onSave != null && !_isSaving,
                onPressed: widget.onSave == null ? null : () => _save(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  final String title;
  final int sourceCount;
  final int pointCount;
  final int approvedPointCount;
  final int questionCount;

  const _ReviewHeader({
    required this.title,
    required this.sourceCount,
    required this.pointCount,
    required this.approvedPointCount,
    required this.questionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.greenLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CountChip(label: '来源', value: sourceCount),
              _CountChip(label: '知识点', value: pointCount),
              _CountChip(label: '已确认', value: approvedPointCount),
              _CountChip(label: '题目', value: questionCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;

  const _CountChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _QuestionReviewSectionHeader extends StatelessWidget {
  final VoidCallback onVerifyAll;

  const _QuestionReviewSectionHeader({required this.onVerifyAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '题目与依据',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('verify_all_cited_questions'),
            onPressed: onVerifyAll,
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: const Text('批量核验有效引用'),
          ),
        ],
      ),
    );
  }
}

class _KnowledgePointSectionHeader extends StatelessWidget {
  final VoidCallback onApproveAll;
  final VoidCallback? onOpenWalkthrough;

  const _KnowledgePointSectionHeader({
    required this.onApproveAll,
    required this.onOpenWalkthrough,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '知识点',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('approve_all_knowledge_points'),
            tooltip: '全部确认',
            onPressed: onApproveAll,
            icon: const Icon(Icons.done_all),
            color: AppColors.green,
          ),
          if (onOpenWalkthrough != null)
            IconButton(
              key: const ValueKey('open_code_walkthrough'),
              tooltip: '代码走读',
              onPressed: onOpenWalkthrough,
              icon: const Icon(Icons.route_outlined),
              color: AppColors.blue,
            ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final Source source;

  const _SourceCard(this.source);

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: source.type.label),
              _MetaChip(label: source.trustLevel.label),
              if (source.publisher != null && source.publisher!.isNotEmpty)
                _MetaChip(label: source.publisher!),
              if (source.revision != null && source.revision!.isNotEmpty)
                _MetaChip(label: 'revision ${source.revision}'),
              _MetaChip(
                label: source.licenseExpression == null ||
                        source.licenseExpression!.isEmpty
                    ? '许可未知'
                    : source.licenseExpression!,
              ),
            ],
          ),
          if (source.uri != null && source.uri!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              source.uri!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (source.retrievedAt != null || source.contentHash.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (source.retrievedAt != null)
                  '获取于 ${source.retrievedAt!.toIso8601String()}',
                if (source.contentHash.isNotEmpty)
                  'SHA-256 ${source.contentHash}',
              ].join('\n'),
              style: const TextStyle(
                fontSize: 11,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KnowledgePointCard extends StatelessWidget {
  final KnowledgePoint point;
  final List<SourceChunk> evidenceChunks;
  final bool approved;
  final VoidCallback onApprove;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KnowledgePointCard({
    super.key,
    required this.point,
    required this.evidenceChunks,
    required this.approved,
    required this.onApprove,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            point.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _MetaChip(label: point.kind.label),
          const SizedBox(height: 8),
          Text(
            point.summary,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (point.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: point.tags.map((tag) => _MetaChip(label: tag)).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            evidenceChunks.isEmpty ? '暂无可读源码依据' : '源码依据',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: evidenceChunks.isEmpty ? AppColors.red : AppColors.blue,
            ),
          ),
          if (evidenceChunks.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...evidenceChunks.map(_CitationBlock.new),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusActionButton(
                key: ValueKey('approve_knowledge_${point.id}'),
                icon: Icons.verified_outlined,
                label: approved ? '已确认' : '确认保留',
                color: AppColors.green,
                selected: approved,
                enabled: evidenceChunks.isNotEmpty,
                onTap: onApprove,
              ),
              IconButton(
                key: ValueKey('edit_knowledge_${point.id}'),
                tooltip: '编辑知识单元',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.blue,
              ),
              IconButton(
                key: ValueKey('delete_knowledge_${point.id}'),
                tooltip: '删除知识单元及关联题目',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final Question question;
  final SourceStatus sourceStatus;
  final KnowledgePoint? knowledgePoint;
  final List<SourceChunk> citationChunks;
  final ValueChanged<SourceStatus> onStatusChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _QuestionReviewCard({
    required this.question,
    required this.sourceStatus,
    required this.knowledgePoint,
    required this.citationChunks,
    required this.onStatusChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _ReviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: question.type.label),
              _MetaChip(label: sourceStatus.label),
              if (knowledgePoint != null)
                _MetaChip(label: knowledgePoint!.title),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '答案：${question.answer}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDark,
            ),
          ),
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              question.explanation!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            '引用依据',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 6),
          if (citationChunks.isEmpty)
            const Text(
              '暂无来源引用',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            )
          else
            ...citationChunks.map(_CitationBlock.new),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusActionButton(
                icon: Icons.verified,
                label: '已核验',
                color: AppColors.green,
                selected: sourceStatus == SourceStatus.verified,
                enabled: citationChunks.isNotEmpty,
                onTap: () => onStatusChanged(SourceStatus.verified),
              ),
              _StatusActionButton(
                icon: Icons.pending_actions,
                label: '待核验',
                color: AppColors.blue,
                selected: sourceStatus == SourceStatus.pending,
                onTap: () => onStatusChanged(SourceStatus.pending),
              ),
              _StatusActionButton(
                icon: Icons.link_off,
                label: '无来源',
                color: AppColors.red,
                selected: sourceStatus == SourceStatus.noSource,
                onTap: () => onStatusChanged(SourceStatus.noSource),
              ),
              IconButton(
                tooltip: '编辑',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.blue,
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: '删除',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _StatusActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? color : AppColors.textLight,
        backgroundColor:
            selected && enabled ? color.withValues(alpha: 0.1) : Colors.white,
        side: BorderSide(
          color: selected && enabled ? color : AppColors.border,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CitationBlock extends StatelessWidget {
  final SourceChunk chunk;

  const _CitationBlock(this.chunk);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chunk.locator != null && chunk.locator!.isNotEmpty) ...[
            Text(
              chunk.locator!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            chunk.content,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Widget child;

  const _ReviewCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: child,
    );
  }
}
