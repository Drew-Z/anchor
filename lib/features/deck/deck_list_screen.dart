import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/deck.dart';
import '../learning/quiz_screen.dart';
import '../ingestion/ingestion_screen.dart';
import '../knowledge_base/knowledge_library_error_state.dart';

class DeckListScreen extends ConsumerStatefulWidget {
  const DeckListScreen({super.key});

  @override
  ConsumerState<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends ConsumerState<DeckListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(deckListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('题库'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: '搜索题包...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // 题包列表
            Expanded(
              child: decksAsync.when(
                data: (decks) {
                  final filtered = decks
                      .where((d) =>
                          _searchQuery.isEmpty ||
                          d.title
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList();
                  if (filtered.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _DeckCard(
                      deck: filtered[index],
                      onStudy: () => _startDeckStudy(filtered[index]),
                      onDelete: () => _confirmDelete(context, filtered[index]),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
                error: (err, _) => KnowledgeLibraryErrorState(
                  title: '题包列表读取失败',
                  retryLabel: '重试读取题包',
                  diagnosticTitle: '题库题包列表读取失败',
                  diagnosticSuccessMessage: '已复制题包读取诊断',
                  diagnosticLines: [
                    '入口: 题库',
                    '搜索词: ${_searchQuery.trim().isEmpty ? '无' : _searchQuery.trim()}',
                  ],
                  error: err,
                  onRetry: () => ref.invalidate(deckListProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'deck-add-content',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IngestionScreen()),
          );
        },
        backgroundColor: AppColors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text(
            '还没有题包',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角 + 添加内容',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Deck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除题包'),
        content: Text('确定删除 "${deck.title}" 吗？此操作不可撤销。'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(deckOperationsProvider).deleteDeck(deck.id);
    }
  }

  Future<void> _startDeckStudy(Deck deck) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuizScreen(deckId: deck.id),
      ),
    );
    if (!mounted) return;
    ref.invalidate(deckListProvider);
    ref.invalidate(todayReviewQueueProvider);
    ref.invalidate(allQuestionsProvider);
    ref.invalidate(verifiedQuestionsProvider);
    ref.invalidate(knowledgePointListProvider);
    ref.invalidate(evidenceBackedKnowledgePointListProvider);
    ref.invalidate(practiceableKnowledgePointListProvider);
    ref.invalidate(deckQuestionsProvider(deck.id));
    ref.invalidate(verifiedDeckQuestionsProvider(deck.id));
  }
}

class _DeckCard extends ConsumerWidget {
  final Deck deck;
  final VoidCallback onStudy;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.deck,
    required this.onStudy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifiedQuestionsAsync =
        ref.watch(verifiedDeckQuestionsProvider(deck.id));
    final masteryColor = deck.masteryLevel >= 100
        ? AppColors.gold
        : deck.masteryLevel >= 50
            ? AppColors.green
            : AppColors.blue;
    final verifiedCount = verifiedQuestionsAsync.maybeWhen(
      data: (questions) => questions.length,
      orElse: () => null,
    );
    final canStudy = verifiedCount != null && verifiedCount > 0;
    final countLabel = verifiedQuestionsAsync.when(
      data: (questions) => '${questions.length} 已核验 / ${deck.questionCount} 总题',
      loading: () => '正在读取核验状态',
      error: (_, __) => '核验状态读取失败',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: masteryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  deck.sourceImage != null ? Icons.image : Icons.text_snippet,
                  color: masteryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // 标题和信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$countLabel  ·  ${_formatDate(deck.createdAt)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 菜单
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.red, size: 20),
                        SizedBox(width: 8),
                        Text('删除'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 掌握度进度条
          if (deck.masteryLevel > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: deck.masteryLevel / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: masteryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${deck.masteryLevel}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: masteryColor,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // 按钮行
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canStudy ? onStudy : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canStudy ? AppColors.green : AppColors.surface,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textLight,
                    disabledBackgroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    canStudy
                        ? (deck.masteryLevel > 0 ? '继续学习' : '开始学习')
                        : '待核验',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
