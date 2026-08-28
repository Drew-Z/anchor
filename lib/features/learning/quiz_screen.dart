import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/question.dart';
import '../../data/models/question_type.dart';
import '../../data/models/source_chunk.dart';
import '../../data/models/user_stats.dart';
import '../../shared/widgets/anchor_button.dart';
import '../../shared/widgets/source_citation_block.dart';
import '../../shared/widgets/stats_widgets.dart';
import '../knowledge_base/knowledge_library_error_state.dart';
import 'widgets/question_widgets.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String? deckId;
  final List<Question>? questions;

  const QuizScreen({super.key, this.deckId, this.questions});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<Question> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isLoading = true;
  int _correctCount = 0;
  bool _isComplete = false;
  bool _outOfHearts = false;
  bool _heartRestored = false;
  int _xpGained = 0;
  bool _isChecking = false; // AI 判题中
  bool _isCorrectAnswer = false; // 缓存的判题结果

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // 随机模式直接传入题目
    if (widget.questions != null) {
      setState(() {
        _questions = _verifiedQuestions(widget.questions!);
        _isLoading = false;
      });
      return;
    }
    if (widget.deckId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final questions = await ref
        .read(questionRepositoryProvider)
        .getQuestionsByDeck(widget.deckId!);
    setState(() {
      _questions = _verifiedQuestions(questions);
      _isLoading = false;
    });
  }

  List<Question> _verifiedQuestions(List<Question> questions) {
    return questions
        .where((question) => question.sourceStatus == SourceStatus.verified)
        .toList();
  }

  Future<void> _checkAnswer() async {
    if (_selectedAnswer == null) return;

    final question = _questions[_currentIndex];

    // 先做本地判断
    var isCorrect = _checkCorrect(question, _selectedAnswer!);

    // 填空题本地不匹配时，调用 AI 判断语义是否等价
    if (!isCorrect && question.type == QuestionType.fillBlank) {
      setState(() => _isChecking = true);
      try {
        final aiService = ref.read(openaiServiceProvider);
        final hasKey = await aiService.hasApiKey();
        if (hasKey) {
          isCorrect = await aiService.judgeFillBlankAnswer(
            question: question.content,
            userAnswer: _selectedAnswer!,
            correctAnswer: question.answer,
          );
        }
      } catch (_) {
        // AI 判题失败，保持本地判断结果
      }
      setState(() => _isChecking = false);
    }

    _isCorrectAnswer = isCorrect;

    // 记录每日打卡
    final gameService = ref.read(gamificationServiceProvider);
    await gameService.recordCheckIn();

    if (isCorrect) {
      _correctCount++;
      _xpGained += 10;
      await ref.read(userStatsProvider.notifier).onCorrect();
      await gameService.incrementTotalCorrect();
    } else {
      await ref.read(userStatsProvider.notifier).onWrong();
    }

    final updatedQuestion = await ref
        .read(reviewSchedulerServiceProvider)
        .recordQuestionReview(question: question, isCorrect: isCorrect);
    await ref
        .read(masteryServiceProvider)
        .updateFromQuestionAttempt(question: question, isCorrect: isCorrect);
    _questions[_currentIndex] = updatedQuestion;
    _refreshAfterQuestionAttempt(updatedQuestion);

    setState(() {
      _showResult = true;
    });

    // 心数耗尽时，延迟1.5秒后跳转到“心数用完”页面
    if (!isCorrect) {
      final stats = ref.read(userStatsProvider).value;
      if (stats != null && stats.hearts <= 0) {
        await Future.delayed(const Duration(milliseconds: 1500));
        setState(() => _outOfHearts = true);
      }
    }
  }

  void _refreshAfterQuestionAttempt(Question question) {
    ref.invalidate(todayReviewQueueProvider);
    ref.invalidate(allQuestionsProvider);
    ref.invalidate(verifiedQuestionsProvider);
    if (question.deckId.isNotEmpty) {
      ref.invalidate(deckQuestionsProvider(question.deckId));
      ref.invalidate(verifiedDeckQuestionsProvider(question.deckId));
    }

    final knowledgePointId = question.knowledgePointId;
    if (knowledgePointId != null && knowledgePointId.isNotEmpty) {
      ref.invalidate(knowledgePointListProvider);
      ref.invalidate(evidenceBackedKnowledgePointListProvider);
      ref.invalidate(practiceableKnowledgePointListProvider);
      ref.invalidate(knowledgePointProvider(knowledgePointId));
      ref.invalidate(knowledgePointQuestionsProvider(knowledgePointId));
    }
  }

  bool _checkCorrect(Question question, String answer) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return answer.trim() == question.answer.trim();
      case QuestionType.fillBlank:
        // 去除空格和标点，忽略大小写
        return answer.trim().toLowerCase() ==
            question.answer.trim().toLowerCase();
      case QuestionType.matching:
      case QuestionType.ordering:
        // 对于匹配和排序，答案格式为 "item1-match1|item2-match2" 或 "step1|step2|step3"
        // 比较时需要规范化
        String normalize(String value) =>
            value.split('|').map((item) => item.trim()).join('|');
        return normalize(answer) == normalize(question.answer);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
        _isCorrectAnswer = false;
        _isChecking = false;
      });
    } else {
      // 完成
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final allCorrect = _correctCount == _questions.length;
    final statsBefore = ref.read(userStatsProvider).value;
    await ref
        .read(userStatsProvider.notifier)
        .onDeckComplete(allCorrect: allCorrect);
    final statsAfter = ref.read(userStatsProvider).value;

    // 计算总 XP（含连续天数奖励）
    final bonus = allCorrect ? 100 : 50;
    final streakBonus = (statsAfter?.streak ?? 0) * 5;
    _xpGained += bonus + streakBonus;

    // 完美完成恢复一颗心
    if (allCorrect) {
      await ref.read(userStatsProvider.notifier).onPerfectQuiz();
      await ref.read(gamificationServiceProvider).incrementPerfectCount();
      _heartRestored = true;
    }

    // 仅知识点模式（有 deckId）才保存学习记录
    if (widget.deckId != null) {
      await ref.read(deckOperationsProvider).saveStudyRecord(
            widget.deckId!,
            _correctCount,
            _questions.length,
          );
    }
    setState(() => _isComplete = true);

    // 检查新解锁的成就
    if (statsBefore != null && statsAfter != null) {
      _checkAchievements(statsBefore, statsAfter);
    }
  }

  void _checkAchievements(UserStats before, UserStats after) {
    final newAchievements = <String>[];
    // 连续天数
    if (before.streak < 3 && after.streak >= 3) newAchievements.add('连续3天');
    if (before.streak < 7 && after.streak >= 7) newAchievements.add('连续7天');
    if (before.streak < 30 && after.streak >= 30) newAchievements.add('连续30天');
    if (before.streak < 100 && after.streak >= 100) {
      newAchievements.add('连续100天');
    }
    // XP
    if (before.xp < 100 && after.xp >= 100) newAchievements.add('初心者');
    if (before.xp < 500 && after.xp >= 500) newAchievements.add('积少成多');
    if (before.xp < 1000 && after.xp >= 1000) newAchievements.add('知识富翁');
    if (before.xp < 2000 && after.xp >= 2000) newAchievements.add('勤学者');
    if (before.xp < 5000 && after.xp >= 5000) newAchievements.add('学霸');
    if (newAchievements.isNotEmpty && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 64, color: AppColors.gold),
                const SizedBox(height: 12),
                const Text(
                  '成就解锁！',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold),
                ),
                const SizedBox(height: 16),
                ...newAchievements.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.gold, size: 20),
                          const SizedBox(width: 6),
                          Text(a,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('太棒了',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('答题')),
        body: const Center(child: Text('暂无已核验题目，请先在知识库完成来源核验')),
      );
    }

    if (_outOfHearts) {
      return _buildOutOfHeartsScreen();
    }

    if (_isComplete) {
      return _buildResultScreen();
    }

    final stats = ref.watch(userStatsProvider);
    final question = _questions[_currentIndex];
    final isCorrect = _showResult && _isCorrectAnswer;
    final citationChunksAsync = _showResult
        ? ref.watch(
            questionCitationChunksProvider(question.citationIds.join('\x00')),
          )
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 进度条
            stats.when(
              data: (s) => QuizProgressBar(
                progress: (_currentIndex + 1) / _questions.length,
                hearts: s.hearts,
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(height: 40),
            ),
            // 题目内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 题型标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.type.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 题干
                    Text(
                      question.type == QuestionType.fillBlank
                          ? '填入正确答案'
                          : question.content,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 答题区
                    QuestionWidget(
                      question: question,
                      showResult: _showResult,
                      selectedAnswer: _selectedAnswer,
                      onAnswerSelected: (answer) {
                        setState(() => _selectedAnswer = answer);
                      },
                    ),
                    // 解析
                    if (_showResult && question.explanation != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.lightbulb : Icons.info,
                                  size: 18,
                                  color: isCorrect
                                      ? AppColors.green
                                      : AppColors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '解析',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isCorrect
                                        ? AppColors.green
                                        : AppColors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.explanation!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (citationChunksAsync != null) ...[
                      const SizedBox(height: 16),
                      _QuizCitationSection(
                        question: question,
                        chunksAsync: citationChunksAsync,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 底部操作区
            _buildBottomBar(isCorrect),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isCorrect) {
    if (_isChecking) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 2)),
        ),
        child: const SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.green,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'AI 判题中...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_showResult) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 2)),
        ),
        child: SafeArea(
          child: AnchorButton(
            label: '检查',
            color: AppColors.green,
            enabled: _selectedAnswer != null && !_isChecking,
            width: double.infinity,
            onPressed: _checkAnswer,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.greenLight : AppColors.redLight,
        border: Border(
          top: BorderSide(
            color: isCorrect ? AppColors.green : AppColors.red,
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? '答对了！' : '答错了',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color:
                          isCorrect ? AppColors.greenDark : AppColors.redDark,
                    ),
                  ),
                  if (isCorrect)
                    Text(
                      '+10 XP',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    )
                  else ...[
                    const Text(
                      '-1 ❤',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heartRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '正确答案: ${_questions[_currentIndex].answer}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.redDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            AnchorButton(
              label: _currentIndex < _questions.length - 1 ? '继续' : '完成',
              color: isCorrect ? AppColors.green : AppColors.red,
              width: 140,
              height: 56,
              fontSize: 18,
              onPressed: _nextQuestion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfHeartsScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.heartRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 60,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 500.ms),
              const SizedBox(height: 24),
              const Text(
                '心数用完了！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.heartRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '答对 $_correctCount / ${_questions.length} 题',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '完美完成一个单元可恢复1颗心',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AnchorButton(
                label: '返回',
                color: AppColors.blue,
                width: double.infinity,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final accuracy =
        _questions.isNotEmpty ? _correctCount / _questions.length : 0.0;
    final allCorrect = _correctCount == _questions.length;
    final stats = ref.watch(userStatsProvider).value;
    final streakBonus = (stats?.streak ?? 0) * 5;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 结果图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: allCorrect ? AppColors.gold : AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allCorrect ? Icons.emoji_events : Icons.check_circle,
                  size: 60,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 500.ms),
              const SizedBox(height: 24),
              Text(
                allCorrect ? '完美！' : '完成！',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: allCorrect ? AppColors.gold : AppColors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '答对 $_correctCount / ${_questions.length} 题',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // XP 明细
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _xpRow('答对题数', '+${_correctCount * 10} XP'),
                    _xpRow('完成奖励', '+${allCorrect ? 100 : 50} XP'),
                    if (streakBonus > 0)
                      _xpRow('连续${stats?.streak ?? 0}天奖励', '+$streakBonus XP'),
                    const Divider(height: 16),
                    _xpRow('总计', '$_xpGained XP', isBold: true),
                  ],
                ),
              ),
              if (_heartRestored) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.heartRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: AppColors.heartRed, size: 20),
                      SizedBox(width: 6),
                      Text(
                        '完美通关，恢复1颗心！',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heartRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // 统计卡片
              Row(
                children: [
                  _ResultCard(
                    icon: Icons.star,
                    color: AppColors.gold,
                    label: '总 XP',
                    value: '+$_xpGained',
                  ),
                  const SizedBox(width: 12),
                  _ResultCard(
                    icon: Icons.check_circle,
                    color: AppColors.green,
                    label: '正确率',
                    value: '${(accuracy * 100).round()}%',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AnchorButton(
                label: '返回',
                color: AppColors.blue,
                width: double.infinity,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _xpRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.green : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCitationSection extends ConsumerWidget {
  final Question question;
  final AsyncValue<List<SourceChunk>> chunksAsync;

  const _QuizCitationSection({
    required this.question,
    required this.chunksAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citationKey = question.citationIds.join('\x00');
    return chunksAsync.when(
      data: (chunks) {
        if (chunks.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blueLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: AppColors.blue),
                  SizedBox(width: 8),
                  Text(
                    '引用依据',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blueDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...chunks.map(
                (chunk) => SourceCitationBlock(
                  chunk: chunk,
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(color: AppColors.green),
      error: (error, _) => KnowledgeLibraryErrorState(
        title: '引用依据读取失败',
        retryLabel: '重试读取引用',
        diagnosticTitle: '答题引用依据读取失败',
        diagnosticSuccessMessage: '已复制答题引用读取诊断',
        diagnosticLines: [
          '入口: 答题结果',
          '题目 ID: ${question.id}',
          '题包 ID: ${question.deckId}',
          '题目: ${question.content}',
          '引用数量: ${question.citationIds.length}',
          '引用 ID: ${question.citationIds.isEmpty ? '无' : question.citationIds.join(', ')}',
        ],
        error: error,
        onRetry: () => ref.invalidate(
          questionCitationChunksProvider(citationKey),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ResultCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
