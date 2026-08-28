import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../data/models/grounded_learning_context.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/programming_exercise.dart';
import '../../data/models/programming_exercise_attempt.dart';
import '../../data/models/question.dart';
import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import '../../services/agent/grounded_learning_context_service.dart';
import '../../shared/widgets/anchor_button.dart';
import '../../shared/widgets/source_citation_block.dart';

class ProgrammingExerciseScreen extends ConsumerStatefulWidget {
  final KnowledgePoint knowledgePoint;
  final String? initialExerciseId;

  const ProgrammingExerciseScreen({
    super.key,
    required this.knowledgePoint,
    this.initialExerciseId,
  });

  @override
  ConsumerState<ProgrammingExerciseScreen> createState() =>
      _ProgrammingExerciseScreenState();
}

class _ProgrammingExerciseScreenState
    extends ConsumerState<ProgrammingExerciseScreen> {
  final TextEditingController _answerController = TextEditingController();

  List<SourceChunk> _evidenceChunks = const [];
  List<ProgrammingExercise> _exercises = const [];
  ProgrammingExercise? _selectedExercise;
  ProgrammingExerciseAttempt? _latestAttempt;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final relations = await ref
          .read(knowledgePointRepositoryProvider)
          .getKnowledgePointSources(widget.knowledgePoint.id);
      final chunks = <SourceChunk>[];
      for (final relation in relations) {
        final chunk = await ref
            .read(sourceChunkRepositoryProvider)
            .getSourceChunk(relation.sourceChunkId);
        if (chunk != null) chunks.add(chunk);
      }
      chunks.sort((a, b) {
        final sourceOrder = a.sourceId.compareTo(b.sourceId);
        if (sourceOrder != 0) return sourceOrder;
        return a.chunkIndex.compareTo(b.chunkIndex);
      });
      final exercises = await ref
          .read(programmingExerciseRepositoryProvider)
          .getExercisesForKnowledgePoint(widget.knowledgePoint.id);
      ProgrammingExercise? initialExercise;
      ProgrammingExerciseAttempt? initialAttempt;
      for (final exercise in exercises) {
        if (exercise.id == widget.initialExerciseId) {
          initialExercise = exercise;
          if (exercise.sourceStatus == SourceStatus.verified) {
            final attempts = await ref
                .read(programmingExerciseRepositoryProvider)
                .getAttemptsForExercise(exercise.id);
            initialAttempt = attempts.isEmpty ? null : attempts.last;
          }
          break;
        }
      }
      final pendingInitialExercise =
          initialExercise?.sourceStatus == SourceStatus.pending
              ? initialExercise
              : null;
      if (!mounted) return;
      setState(() {
        _evidenceChunks = chunks;
        _exercises = exercises;
        _selectedExercise =
            initialExercise?.sourceStatus == SourceStatus.verified
                ? initialExercise
                : null;
        _latestAttempt = initialAttempt;
        _isLoading = false;
      });
      if (pendingInitialExercise != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _reviewAndVerify(pendingInitialExercise);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '读取练习失败: $e';
      });
    }
  }

  Future<void> _generateExercises() async {
    if (_isGenerating || _isSubmitting) return;
    final hasKey = await ref.read(openaiServiceProvider).hasApiKey();
    if (!hasKey) {
      setState(() => _errorMessage = '请先在设置中配置 AI API Key');
      return;
    }
    if (_evidenceChunks.isEmpty) {
      setState(() => _errorMessage = '当前知识点没有来源片段，无法生成练习');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final result =
          await ref.read(programmingExerciseGenerationTaskProvider).run(
                knowledgePoint: widget.knowledgePoint,
                sourceChunks: _evidenceChunks,
              );
      if (!result.isSuccess) {
        throw StateError(result.errorMessage ?? '练习生成失败');
      }

      final repository = ref.read(programmingExerciseRepositoryProvider);
      final now = DateTime.now();
      final generated = <ProgrammingExercise>[];
      for (var index = 0; index < result.requireData.length; index++) {
        final exercise = result.requireData[index].toExercise(
          id: 'programming-exercise-${now.microsecondsSinceEpoch}-$index',
          knowledgePointId: widget.knowledgePoint.id,
          createdAt: now.add(Duration(microseconds: index)),
        );
        await repository.insertExercise(exercise);
        generated.add(exercise);
      }

      if (!mounted) return;
      setState(() {
        _exercises = [..._exercises, ...generated];
        _isGenerating = false;
        _successMessage = '已生成 ${generated.length} 道待核验练习';
      });
      ref.invalidate(programmingExercisesProvider(widget.knowledgePoint.id));
      ref.invalidate(allProgrammingExercisesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = '生成练习失败: $e';
      });
    }
  }

  Future<void> _reviewAndVerify(ProgrammingExercise exercise) async {
    final citedChunks = _chunksForExercise(exercise);
    if (citedChunks.length != exercise.citationIds.length ||
        citedChunks.isEmpty) {
      setState(() => _errorMessage = '练习引用不完整，不能标记为已核验');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('核验${exercise.kind.label}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReviewLine(label: '题目', text: exercise.prompt),
                _ReviewLine(
                  label: '参考关键点',
                  text: exercise.referenceAnswer,
                ),
                const Text(
                  '来源依据',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...citedChunks.map(
                  (chunk) => SourceCitationBlock(
                    chunk: chunk,
                    backgroundColor: AppColors.blueLight,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('暂不核验'),
          ),
          FilledButton.icon(
            key: const ValueKey('confirm-programming-exercise-verification'),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('确认来源可支撑'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final verified = exercise.copyWith(
      sourceStatus: SourceStatus.verified,
      updatedAt: DateTime.now(),
    );
    await ref
        .read(programmingExerciseRepositoryProvider)
        .updateExercise(verified);
    if (!mounted) return;
    setState(() {
      _exercises = _exercises
          .map((item) => item.id == verified.id ? verified : item)
          .toList();
      if (_selectedExercise?.id == verified.id) {
        _selectedExercise = verified;
      }
      _successMessage = '练习已核验，可以进入正式作答';
      _errorMessage = null;
    });
    ref.invalidate(programmingExercisesProvider(widget.knowledgePoint.id));
    ref.invalidate(allProgrammingExercisesProvider);
    ref.invalidate(verifiedPracticeTargetsProvider);
    ref.invalidate(programmingReviewQueueProvider);
    await _selectExercise(verified);
  }

  Future<void> _selectExercise(ProgrammingExercise exercise) async {
    if (exercise.sourceStatus != SourceStatus.verified) return;
    final attempts = await ref
        .read(programmingExerciseRepositoryProvider)
        .getAttemptsForExercise(exercise.id);
    if (!mounted) return;
    setState(() {
      _selectedExercise = exercise;
      _latestAttempt = attempts.isEmpty ? null : attempts.last;
      _answerController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _submitAnswer() async {
    final exercise = _selectedExercise;
    final answer = _answerController.text.trim();
    if (exercise == null || _isSubmitting) return;
    if (answer.isEmpty) {
      setState(() => _errorMessage = '请先完成当前练习');
      return;
    }
    final hasKey = await ref.read(openaiServiceProvider).hasApiKey();
    if (!hasKey) {
      setState(() => _errorMessage = '请先在设置中配置 AI API Key');
      return;
    }
    final citedChunks = _chunksForExercise(exercise);
    if (citedChunks.length != exercise.citationIds.length ||
        citedChunks.isEmpty) {
      setState(() => _errorMessage = '当前练习引用不完整，无法评价');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final groundedContext = await _buildEvaluationContext(
        exercise,
        citedChunks,
      );
      if (!groundedContext.isExecutable) {
        throw StateError(groundedContext.diagnosticLines.join('\n'));
      }
      final result =
          await ref.read(programmingExerciseEvaluationTaskProvider).run(
                knowledgePoint: widget.knowledgePoint,
                exercise: exercise,
                userAnswer: answer,
                sourceChunks: groundedContext.chunks,
                groundedContext: groundedContext,
              );
      if (!result.isSuccess) {
        throw StateError(result.errorMessage ?? '练习评价失败');
      }

      final evaluation = result.requireData;
      final repository = ref.read(programmingExerciseRepositoryProvider);
      final now = DateTime.now();
      final attemptId = 'programming-attempt-${now.microsecondsSinceEpoch}';
      var attempt = ProgrammingExerciseAttempt(
        id: attemptId,
        exerciseId: exercise.id,
        knowledgePointId: widget.knowledgePoint.id,
        userAnswer: answer,
        feedback: evaluation.feedback,
        conceptAccuracyScore: evaluation.conceptAccuracyScore,
        reasoningProcessScore: evaluation.reasoningProcessScore,
        evidenceUseScore: evaluation.evidenceUseScore,
        clarityScore: evaluation.clarityScore,
        misconceptionCode: evaluation.misconceptionCode,
        misconceptionLabel: evaluation.misconceptionLabel,
        repairExplanation: evaluation.repairExplanation,
        citationIds: evaluation.citationIds,
        evidenceSufficient: evaluation.evidenceSufficient,
        groundedClaims: evaluation.claims,
        groundingDisposition: evaluation.groundingDisposition,
        createdAt: now,
      );
      await repository.insertAttempt(attempt);

      ProgrammingExercise? retest;
      if (evaluation.retestExercise != null) {
        retest = evaluation.retestExercise!.toExercise(
          id: 'programming-retest-${now.microsecondsSinceEpoch}',
          knowledgePointId: widget.knowledgePoint.id,
          createdAt: now.add(const Duration(microseconds: 1)),
          isRetest: true,
          parentAttemptId: attempt.id,
        );
        await repository.insertExercise(retest);
        attempt = attempt.copyWith(retestExerciseId: retest.id);
        await repository.updateAttempt(attempt);
      }

      final masteryApplied = await ref
          .read(masteryServiceProvider)
          .updateFromProgrammingExerciseAttempt(
            exercise: exercise,
            attempt: attempt,
          );
      if (masteryApplied) {
        attempt = attempt.copyWith(formalMasteryApplied: true);
        await repository.updateAttempt(attempt);
        ref.invalidate(knowledgePointProvider(widget.knowledgePoint.id));
        ref.invalidate(knowledgePointListProvider);
      }
      await ref
          .read(programmingReviewClosureServiceProvider)
          .closeExerciseAttempt(
            exercise: exercise,
            attempt: attempt,
          );

      if (!mounted) return;
      setState(() {
        _latestAttempt = attempt;
        if (retest != null) _exercises = [..._exercises, retest];
        _answerController.clear();
        _isSubmitting = false;
        _successMessage =
            masteryApplied ? '评价已记录，并更新正式掌握度' : '评价已记录；本次结果未进入正式掌握度';
      });
      ref.invalidate(programmingExerciseAttemptsProvider(exercise.id));
      ref.invalidate(programmingExercisesProvider(widget.knowledgePoint.id));
      ref.invalidate(allProgrammingExercisesProvider);
      ref.invalidate(programmingReviewQueueProvider);
      invalidateAgentLearningRecordProviders(ref);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = '提交失败: $e';
      });
    }
  }

  Future<GroundedLearningContext> _buildEvaluationContext(
    ProgrammingExercise exercise,
    List<SourceChunk> chunks,
  ) async {
    final sources = <String, Source>{};
    for (final sourceId in chunks.map((chunk) => chunk.sourceId).toSet()) {
      final source = await ref.read(sourceProvider(sourceId).future);
      if (source != null) sources[source.id] = source;
    }
    return ref.read(groundedLearningContextServiceProvider).select(
          targetId: exercise.id,
          knowledgePoint: widget.knowledgePoint,
          surface: GroundedLearningSurface.programmingExerciseEvaluation,
          candidates: chunks
              .map(
                (chunk) => GroundedLearningContextCandidate(
                  chunk: chunk,
                  reasons: const [
                    GroundedLearningContextReason.practiceCitation,
                  ],
                ),
              )
              .toList(growable: false),
          sources: sources.values.toList(growable: false),
          requiredCitationIds: exercise.citationIds.toSet(),
          limit: exercise.citationIds.length,
        );
  }

  List<SourceChunk> _chunksForExercise(ProgrammingExercise exercise) {
    final chunksById = {for (final chunk in _evidenceChunks) chunk.id: chunk};
    return exercise.citationIds
        .map((id) => chunksById[id])
        .whereType<SourceChunk>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编程练习')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ExerciseHeader(
                    point: widget.knowledgePoint,
                    exerciseCount: _exercises.length,
                    verifiedCount: _exercises
                        .where((exercise) =>
                            exercise.sourceStatus == SourceStatus.verified)
                        .length,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _MessageBanner(
                      text: _errorMessage!,
                      color: AppColors.red,
                      icon: Icons.error_outline,
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 12),
                    _MessageBanner(
                      text: _successMessage!,
                      color: AppColors.green,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_isGenerating)
                    const _BusyBlock(label: '正在基于来源生成练习...')
                  else
                    AnchorButton(
                      key: const ValueKey('generate-programming-exercises'),
                      label: _exercises.isEmpty ? '生成练习' : '补充一组练习',
                      color: AppColors.blue,
                      width: double.infinity,
                      icon: Icons.auto_awesome_outlined,
                      onPressed: _isSubmitting ? null : _generateExercises,
                    ),
                  const SizedBox(height: 18),
                  const _SectionTitle('练习列表'),
                  const SizedBox(height: 8),
                  if (_exercises.isEmpty)
                    const _MessageBanner(
                      text: '当前还没有编程练习。',
                      color: AppColors.blue,
                      icon: Icons.code,
                    )
                  else
                    ..._exercises.map(
                      (exercise) => _ExerciseCard(
                        exercise: exercise,
                        selected: _selectedExercise?.id == exercise.id,
                        busy: _isGenerating || _isSubmitting,
                        onReview: () => _reviewAndVerify(exercise),
                        onStart: () => _selectExercise(exercise),
                      ),
                    ),
                  if (_selectedExercise != null) ...[
                    const SizedBox(height: 8),
                    _AnswerPanel(
                      exercise: _selectedExercise!,
                      controller: _answerController,
                      isSubmitting: _isSubmitting,
                      onSubmit: _submitAnswer,
                    ),
                  ],
                  if (_latestAttempt != null) ...[
                    const SizedBox(height: 14),
                    _AttemptResultView(
                      attempt: _latestAttempt!,
                      evidenceChunks: _chunksForExercise(
                        _selectedExercise!,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ExerciseHeader extends StatelessWidget {
  final KnowledgePoint point;
  final int exerciseCount;
  final int verifiedCount;

  const _ExerciseHeader({
    required this.point,
    required this.exerciseCount,
    required this.verifiedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal, color: AppColors.blueDark, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$exerciseCount 道练习 · $verifiedCount 道已核验',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ProgrammingExercise exercise;
  final bool selected;
  final bool busy;
  final VoidCallback onReview;
  final VoidCallback onStart;

  const _ExerciseCard({
    required this.exercise,
    required this.selected,
    required this.busy,
    required this.onReview,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final verified = exercise.sourceStatus == SourceStatus.verified;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.greenLight : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AppColors.green : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _kindIcon(exercise.kind),
                color:
                    exercise.isRetest ? AppColors.purpleDark : AppColors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.isRetest
                      ? '${exercise.kind.label} · 复测'
                      : exercise.kind.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusPill(
                label: exercise.sourceStatus.label,
                color: verified ? AppColors.green : AppColors.goldDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            exercise.prompt,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${exercise.citationIds.length} 条来源依据',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: ValueKey(
                verified
                    ? 'start-programming-exercise-${exercise.id}'
                    : 'verify-programming-exercise-${exercise.id}',
              ),
              onPressed: busy
                  ? null
                  : verified
                      ? onStart
                      : onReview,
              icon: Icon(
                verified ? Icons.edit_note_outlined : Icons.fact_check_outlined,
              ),
              label: Text(verified ? '开始作答' : '查看依据并核验'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _kindIcon(ProgrammingExerciseKind kind) {
    switch (kind) {
      case ProgrammingExerciseKind.explanation:
        return Icons.record_voice_over_outlined;
      case ProgrammingExerciseKind.codeReading:
        return Icons.code;
      case ProgrammingExerciseKind.boundaryJudgment:
        return Icons.rule_outlined;
      case ProgrammingExerciseKind.implementation:
        return Icons.build_outlined;
    }
  }
}

class _AnswerPanel extends StatelessWidget {
  final ProgrammingExercise exercise;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _AnswerPanel({
    required this.exercise,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('当前作答'),
          const SizedBox(height: 8),
          Text(
            exercise.prompt,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: const Text(
                '四维评价标准',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              children: [
                _RubricLine('概念准确', exercise.conceptAccuracyCriterion),
                _RubricLine('推理过程', exercise.reasoningProcessCriterion),
                _RubricLine('代码或文档依据', exercise.evidenceUseCriterion),
                _RubricLine('表达清晰', exercise.clarityCriterion),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('programming-exercise-answer-input'),
            controller: controller,
            enabled: !isSubmitting,
            minLines: 6,
            maxLines: 14,
            decoration: InputDecoration(
              hintText: exercise.kind == ProgrammingExerciseKind.implementation
                  ? '写下实现、伪代码或关键代码，并说明依据'
                  : '写下你的回答和推理依据',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isSubmitting)
            const _BusyBlock(label: '正在按四个维度核对来源...')
          else
            AnchorButton(
              key: const ValueKey('submit-programming-exercise-answer'),
              label: '提交评价',
              color: AppColors.green,
              width: double.infinity,
              icon: Icons.send_outlined,
              onPressed: onSubmit,
            ),
        ],
      ),
    );
  }
}

class _AttemptResultView extends StatelessWidget {
  final ProgrammingExerciseAttempt attempt;
  final List<SourceChunk> evidenceChunks;

  const _AttemptResultView({
    required this.attempt,
    required this.evidenceChunks,
  });

  @override
  Widget build(BuildContext context) {
    final chunksById = {for (final chunk in evidenceChunks) chunk.id: chunk};
    final citedChunks = attempt.citationIds
        .map((id) => chunksById[id])
        .whereType<SourceChunk>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('本次评价'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attempt.feedback,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ScorePill('概念准确', attempt.conceptAccuracyScore),
                  _ScorePill('推理过程', attempt.reasoningProcessScore),
                  _ScorePill('依据', attempt.evidenceUseScore),
                  _ScorePill('表达', attempt.clarityScore),
                ],
              ),
              if (attempt.misconceptionLabel.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ReviewLine(
                  label: '误区 · ${attempt.misconceptionCode}',
                  text: attempt.misconceptionLabel,
                ),
              ],
              if (attempt.repairExplanation.isNotEmpty)
                _ReviewLine(
                  label: '修复讲解',
                  text: attempt.repairExplanation,
                ),
              const SizedBox(height: 2),
              _StatusPill(
                label: attempt.formalMasteryApplied ? '已计入正式掌握度' : '未计入正式掌握度',
                color: attempt.formalMasteryApplied
                    ? AppColors.green
                    : AppColors.goldDark,
              ),
            ],
          ),
        ),
        if (citedChunks.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SectionTitle('评价依据'),
          const SizedBox(height: 8),
          ...citedChunks.map(
            (chunk) => SourceCitationBlock(
              chunk: chunk,
              backgroundColor: AppColors.blueLight,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewLine extends StatelessWidget {
  final String label;
  final String text;

  const _ReviewLine({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RubricLine extends StatelessWidget {
  final String label;
  final String text;

  const _RubricLine(this.label, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.blueDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int score;

  const _ScorePill(this.label, this.score);

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.green
        : score >= 60
            ? AppColors.goldDark
            : AppColors.red;
    return _StatusPill(label: '$label $score', color: color);
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _MessageBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusyBlock extends StatelessWidget {
  final String label;

  const _BusyBlock({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
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
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}
