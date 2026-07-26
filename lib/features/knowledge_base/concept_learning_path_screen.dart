import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/knowledge_point_prerequisite.dart';
import '../../data/models/question.dart';
import '../../data/models/source_chunk.dart';
import '../../services/scheduling/concept_learning_path_service.dart';
import '../agent/tutor_session_screen.dart';
import '../learning/quiz_screen.dart';
import 'knowledge_base_screen.dart';
import 'knowledge_library_error_state.dart';

class ConceptLearningPathScreen extends ConsumerStatefulWidget {
  const ConceptLearningPathScreen({super.key});

  @override
  ConsumerState<ConceptLearningPathScreen> createState() =>
      _ConceptLearningPathScreenState();
}

class _ConceptLearningPathScreenState
    extends ConsumerState<ConceptLearningPathScreen> {
  static const int _maxSelectedPoints = 12;

  List<KnowledgePoint> _eligiblePoints = const [];
  Map<String, List<SourceChunk>> _chunksByPointId = const {};
  Set<String> _selectedPointIds = const {};
  List<KnowledgePointPrerequisiteDraft> _drafts = const [];
  Set<String> _approvedKeys = const {};
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(knowledgePointRepositoryProvider);
      final points = (await repository.getAllKnowledgePoints())
          .where((point) => point.kind == KnowledgePointKind.concept)
          .toList();
      points.sort(_comparePoints);

      final chunksByPointId = <String, List<SourceChunk>>{};
      final eligiblePoints = <KnowledgePoint>[];
      for (final point in points) {
        final relations = await repository.getKnowledgePointSources(point.id);
        final chunks = <SourceChunk>[];
        final seenChunkIds = <String>{};
        for (final relation in relations) {
          if (!seenChunkIds.add(relation.sourceChunkId)) continue;
          final chunk = await ref
              .read(sourceChunkRepositoryProvider)
              .getSourceChunk(relation.sourceChunkId);
          if (chunk != null) chunks.add(chunk);
        }
        if (chunks.isEmpty) continue;
        chunksByPointId[point.id] = chunks;
        eligiblePoints.add(point);
      }

      final savedRelations = await repository.getKnowledgePointPrerequisites();
      final eligibleIds = eligiblePoints.map((point) => point.id).toSet();
      final savedDrafts = savedRelations
          .where(
            (relation) =>
                eligibleIds.contains(relation.knowledgePointId) &&
                eligibleIds.contains(relation.prerequisiteKnowledgePointId),
          )
          .map((relation) => relation.toDraft())
          .toList();
      final savedPointIds = savedDrafts
          .expand(
            (draft) => [
              draft.knowledgePointId,
              draft.prerequisiteKnowledgePointId,
            ],
          )
          .toSet();
      final selectedIds = <String>{...savedPointIds};
      for (final point in eligiblePoints) {
        if (selectedIds.length >= _maxSelectedPoints) break;
        selectedIds.add(point.id);
      }

      if (!mounted) return;
      setState(() {
        _eligiblePoints = eligiblePoints;
        _chunksByPointId = chunksByPointId;
        _selectedPointIds = selectedIds;
        _drafts = savedDrafts;
        _approvedKeys = savedDrafts.map((draft) => draft.key).toSet();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _generateCandidates() async {
    final scopePoints = _scopePoints;
    if (scopePoints.length < 2) {
      _showMessage('请至少选择两个有来源的通用概念');
      return;
    }
    final hasKey = await ref.read(openaiServiceProvider).hasApiKey();
    if (!hasKey) {
      _showMessage('请先在设置中配置 AI API Key');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    try {
      final chunksByPointId = {
        for (final point in scopePoints)
          point.id: _chunksByPointId[point.id] ?? const <SourceChunk>[],
      };
      final result = await ref.read(conceptPrerequisiteTaskProvider).run(
            knowledgePoints: scopePoints,
            sourceChunksByKnowledgePointId: chunksByPointId,
          );
      if (!result.isSuccess) {
        throw StateError(result.errorMessage ?? '先修关系分析失败');
      }
      final sanitized = _sanitize(result.requireData.relations);
      if (!mounted) return;
      setState(() {
        _drafts = sanitized.accepted;
        _approvedKeys = sanitized.accepted.map((draft) => draft.key).toSet();
        _isGenerating = false;
      });
      if (sanitized.accepted.isEmpty) {
        _showMessage('当前来源没有明确支持可保存的先修关系');
      } else if (sanitized.rejected.isNotEmpty) {
        _showMessage('已过滤 ${sanitized.rejected.length} 条无效或成环关系');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _saveRelations() async {
    final approved =
        _drafts.where((draft) => _approvedKeys.contains(draft.key)).toList();
    final sanitized = _sanitize(approved);
    if (sanitized.rejected.isNotEmpty) {
      _showMessage(sanitized.rejected.first.reason);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      await ref
          .read(knowledgePointRepositoryProvider)
          .replaceKnowledgePointPrerequisites(
            scopeKnowledgePointIds: _selectedPointIds.toList(),
            relations: sanitized.accepted
                .map((draft) => draft.toRelation(now))
                .toList(),
          );
      if (!mounted) return;
      setState(() {
        _drafts = sanitized.accepted;
        _approvedKeys = sanitized.accepted.map((draft) => draft.key).toSet();
        _isSaving = false;
      });
      _showMessage('学习路径已保存');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _togglePoint(String pointId, bool selected) {
    final next = {..._selectedPointIds};
    if (selected) {
      if (next.length >= _maxSelectedPoints) {
        _showMessage('一次最多分析 $_maxSelectedPoints 个概念');
        return;
      }
      next.add(pointId);
    } else {
      next.remove(pointId);
    }
    final remainingDrafts = _drafts
        .where(
          (draft) =>
              next.contains(draft.knowledgePointId) &&
              next.contains(draft.prerequisiteKnowledgePointId),
        )
        .toList();
    setState(() {
      _selectedPointIds = next;
      _drafts = remainingDrafts;
      _approvedKeys = _approvedKeys
          .where((key) => remainingDrafts.any((draft) => draft.key == key))
          .toSet();
    });
  }

  void _reverseDraft(int index) {
    final oldKey = _drafts[index].key;
    final reversed = _drafts[index].reversed();
    final next = [..._drafts]..[index] = reversed;
    final sanitized = _sanitize(next);
    if (sanitized.accepted.length != next.length) {
      final rejected = sanitized.rejected.first;
      _showMessage('不能反向：${rejected.reason}');
      return;
    }
    final wasApproved = _approvedKeys.contains(_drafts[index].key);
    setState(() {
      _drafts = sanitized.accepted;
      _approvedKeys = {
        for (final key in _approvedKeys)
          if (key != oldKey) key,
        if (wasApproved) reversed.key,
      };
    });
  }

  void _deleteDraft(int index) {
    final removed = _drafts[index];
    setState(() {
      _drafts = [..._drafts]..removeAt(index);
      _approvedKeys = {..._approvedKeys}..remove(removed.key);
    });
  }

  ConceptPrerequisiteSanitizationResult _sanitize(
    List<KnowledgePointPrerequisiteDraft> drafts,
  ) {
    final citationIdsByPointId = {
      for (final id in _selectedPointIds)
        id: (_chunksByPointId[id] ?? const <SourceChunk>[])
            .map((chunk) => chunk.id)
            .toSet(),
    };
    return ref.read(conceptLearningPathServiceProvider).sanitize(
          drafts: drafts,
          knowledgePoints: _scopePoints,
          sourceBackedKnowledgePointIds: _selectedPointIds,
          citationIdsByKnowledgePointId: citationIdsByPointId,
        );
  }

  List<KnowledgePoint> get _scopePoints => _eligiblePoints
      .where((point) => _selectedPointIds.contains(point.id))
      .toList();

  ConceptLearningPath get _path {
    final approved =
        _drafts.where((draft) => _approvedKeys.contains(draft.key)).toList();
    return ref.read(conceptLearningPathServiceProvider).buildPath(
          knowledgePoints: _scopePoints,
          relations: approved,
        );
  }

  int _comparePoints(KnowledgePoint left, KnowledgePoint right) {
    final mastery = left.masteryLevel.compareTo(right.masteryLevel);
    if (mastery != 0) return mastery;
    final difficulty = left.difficulty.compareTo(right.difficulty);
    if (difficulty != 0) return difficulty;
    final title = left.title.compareTo(right.title);
    if (title != 0) return title;
    return left.id.compareTo(right.id);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编程学习路径')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            : _errorMessage != null && _eligiblePoints.isEmpty
                ? KnowledgeLibraryErrorState(
                    title: '学习路径读取失败',
                    retryLabel: '重试',
                    diagnosticTitle: '编程学习路径读取失败',
                    diagnosticSuccessMessage: '已复制学习路径诊断',
                    diagnosticLines: const ['入口: 编程学习路径'],
                    error: _errorMessage!,
                    onRetry: _load,
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_eligiblePoints.length < 2) {
      return const _EmptyLearningPathState();
    }
    final path = _path;
    final pointsById = {for (final point in _eligiblePoints) point.id: point};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _LearningPathHeader(
          selectedCount: _selectedPointIds.length,
          relationCount: _approvedKeys.length,
        ),
        const SizedBox(height: 12),
        _PointScopeSelector(
          points: _eligiblePoints,
          selectedPointIds: _selectedPointIds,
          maxSelectedPoints: _maxSelectedPoints,
          onChanged: _togglePoint,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _isGenerating || _isSaving ? null : _generateCandidates,
                icon: _isGenerating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? '分析中' : '分析先修关系'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: '保存学习路径',
              onPressed: _isGenerating || _isSaving ? null : _saveRelations,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          KnowledgeLibraryErrorState(
            title: '学习路径操作失败',
            retryLabel: '重新分析',
            diagnosticTitle: '编程学习路径操作失败',
            diagnosticSuccessMessage: '已复制学习路径诊断',
            diagnosticLines: [
              '选择概念数: ${_selectedPointIds.length}',
              '候选关系数: ${_drafts.length}',
            ],
            error: _errorMessage!,
            onRetry: _generateCandidates,
          ),
        ],
        const SizedBox(height: 18),
        const _SectionTitle('候选先修关系'),
        const SizedBox(height: 8),
        if (_drafts.isEmpty)
          const _InlineEmptyState(
            icon: Icons.account_tree_outlined,
            text: '尚无明确先修关系，学习路径将按掌握度、难度和标题稳定排序。',
          )
        else
          ..._drafts.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PrerequisiteDraftCard(
                    draft: entry.value,
                    prerequisiteTitle:
                        pointsById[entry.value.prerequisiteKnowledgePointId]
                                ?.title ??
                            entry.value.prerequisiteKnowledgePointId,
                    knowledgePointTitle:
                        pointsById[entry.value.knowledgePointId]?.title ??
                            entry.value.knowledgePointId,
                    approved: _approvedKeys.contains(entry.value.key),
                    onApprovedChanged: (approved) {
                      setState(() {
                        final next = {..._approvedKeys};
                        if (approved) {
                          next.add(entry.value.key);
                        } else {
                          next.remove(entry.value.key);
                        }
                        _approvedKeys = next;
                      });
                    },
                    onReverse: () => _reverseDraft(entry.key),
                    onDelete: () => _deleteDraft(entry.key),
                  ),
                ),
              ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: _SectionTitle('学习顺序')),
            if (path.hasCycle)
              const _StatusChip(
                label: '检测到环路',
                color: AppColors.red,
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...path.steps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LearningPathStepCard(
              step: step,
              prerequisiteTitles: step.prerequisiteKnowledgePointIds
                  .map((id) => pointsById[id]?.title ?? id)
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningPathHeader extends StatelessWidget {
  final int selectedCount;
  final int relationCount;

  const _LearningPathHeader({
    required this.selectedCount,
    required this.relationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blueLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.blue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.route_outlined, color: AppColors.blue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$selectedCount 个有来源概念 · $relationCount 条已确认先修关系',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointScopeSelector extends StatelessWidget {
  final List<KnowledgePoint> points;
  final Set<String> selectedPointIds;
  final int maxSelectedPoints;
  final void Function(String pointId, bool selected) onChanged;

  const _PointScopeSelector({
    required this.points,
    required this.selectedPointIds,
    required this.maxSelectedPoints,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.filter_alt_outlined),
        title: Text(
          '学习范围 ${selectedPointIds.length}/$maxSelectedPoints',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        children: points
            .map(
              (point) => CheckboxListTile(
                dense: true,
                value: selectedPointIds.contains(point.id),
                onChanged: (value) => onChanged(point.id, value ?? false),
                title: Text(
                  point.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '掌握度 ${point.masteryLevel}% · 难度 ${point.difficulty}',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PrerequisiteDraftCard extends StatelessWidget {
  final KnowledgePointPrerequisiteDraft draft;
  final String prerequisiteTitle;
  final String knowledgePointTitle;
  final bool approved;
  final ValueChanged<bool> onApprovedChanged;
  final VoidCallback onReverse;
  final VoidCallback onDelete;

  const _PrerequisiteDraftCard({
    required this.draft,
    required this.prerequisiteTitle,
    required this.knowledgePointTitle,
    required this.approved,
    required this.onApprovedChanged,
    required this.onReverse,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: approved ? AppColors.greenLight : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: approved ? AppColors.green : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: approved,
              onChanged: (value) => onApprovedChanged(value ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$prerequisiteTitle → $knowledgePointTitle',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    draft.rationale,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${draft.citationIds.length} 个来源片段',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blueDark,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '反向先修关系',
              onPressed: onReverse,
              icon: const Icon(Icons.swap_horiz),
            ),
            IconButton(
              tooltip: '删除候选关系',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningPathStepCard extends ConsumerWidget {
  final ConceptLearningPathStep step;
  final List<String> prerequisiteTitles;

  const _LearningPathStepCard({
    required this.step,
    required this.prerequisiteTitles,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync =
        ref.watch(knowledgePointQuestionsProvider(step.knowledgePoint.id));
    final verifiedQuestions = questionsAsync.maybeWhen(
      data: (questions) => questions
          .where((question) => question.sourceStatus == SourceStatus.verified)
          .toList(),
      orElse: () => const <Question>[],
    );

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: step.prerequisitesMastered
                    ? AppColors.greenLight
                    : AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${step.order}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.knowledgePoint.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prerequisiteTitles.isEmpty
                        ? '无已确认先修项'
                        : '先修：${prerequisiteTitles.join('、')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StatusChip(
                        label: '掌握 ${step.knowledgePoint.masteryLevel}%',
                        color: AppColors.blue,
                      ),
                      _StatusChip(
                        label: step.prerequisitesMastered ? '可开始' : '先补先修',
                        color: step.prerequisitesMastered
                            ? AppColors.green
                            : AppColors.goldDark,
                      ),
                      _StatusChip(
                        label: '已核验题 ${verifiedQuestions.length}',
                        color: AppColors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: '查看来源与知识点',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => KnowledgePointDetailScreen(
                          point: step.knowledgePoint,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.source_outlined),
                ),
                IconButton(
                  tooltip: '进入导师模式',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TutorSessionScreen(
                          initialPoint: step.knowledgePoint,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school_outlined),
                ),
                IconButton(
                  tooltip: verifiedQuestions.isEmpty ? '暂无已核验题' : '练习已核验题',
                  onPressed: verifiedQuestions.isEmpty
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                questions: verifiedQuestions,
                              ),
                            ),
                          );
                          ref.invalidate(
                            knowledgePointQuestionsProvider(
                              step.knowledgePoint.id,
                            ),
                          );
                          ref.invalidate(knowledgePointListProvider);
                          ref.invalidate(todayReviewQueueProvider);
                        },
                  icon: const Icon(Icons.quiz_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
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
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineEmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLearningPathState extends StatelessWidget {
  const _EmptyLearningPathState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, size: 56, color: AppColors.textLight),
            SizedBox(height: 14),
            Text(
              '至少需要两个有来源的通用概念',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
