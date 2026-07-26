import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/source_chunk.dart';
import '../../services/ingestion/project_code_walkthrough_service.dart';

class ProjectCodeWalkthroughScreen extends StatelessWidget {
  final List<KnowledgePoint> knowledgePoints;
  final List<SourceChunk> sourceChunks;
  final Map<String, List<String>> sourceChunkIdsByKnowledgePointId;

  const ProjectCodeWalkthroughScreen({
    super.key,
    required this.knowledgePoints,
    required this.sourceChunks,
    required this.sourceChunkIdsByKnowledgePointId,
  });

  @override
  Widget build(BuildContext context) {
    final steps = const ProjectCodeWalkthroughService().build(
      knowledgePoints: knowledgePoints,
      sourceChunks: sourceChunks,
      sourceChunkIdsByKnowledgePointId: sourceChunkIdsByKnowledgePointId,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('项目代码走读')),
      body: SafeArea(
        child: steps.isEmpty
            ? const _EmptyWalkthrough()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return _WalkthroughStepTile(
                    key: ValueKey('walkthrough_step_${step.sequence}'),
                    step: step,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProjectCodeWalkthroughDetailScreen(
                            step: step,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class ProjectCodeWalkthroughDetailScreen extends StatelessWidget {
  final ProjectCodeWalkthroughStep step;

  const ProjectCodeWalkthroughDetailScreen({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final point = step.knowledgePoint;
    return Scaffold(
      appBar: AppBar(title: Text('第 ${step.sequence} 步')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WalkthroughChip(label: point.kind.label),
                _WalkthroughChip(label: '难度 ${point.difficulty}'),
                _WalkthroughChip(
                  label: '面试相关 ${point.interviewRelevance}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              point.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              point.summary,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '源码依据',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (step.evidenceChunks.isEmpty)
              const Text(
                '当前单元没有可读源码片段，不应作为正式项目结论保存。',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.red,
                ),
              )
            else
              ...step.evidenceChunks.map(_WalkthroughEvidenceBlock.new),
          ],
        ),
      ),
    );
  }
}

class _WalkthroughStepTile extends StatelessWidget {
  final ProjectCodeWalkthroughStep step;
  final VoidCallback onTap;

  const _WalkthroughStepTile({
    super.key,
    required this.step,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final point = step.knowledgePoint;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${step.sequence}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.kind.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      point.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      step.locatorLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalkthroughEvidenceBlock extends StatelessWidget {
  final SourceChunk chunk;

  const _WalkthroughEvidenceBlock(this.chunk);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chunk.locator ?? chunk.relativePath ?? chunk.id,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            chunk.content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkthroughChip extends StatelessWidget {
  final String label;

  const _WalkthroughChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

class _EmptyWalkthrough extends StatelessWidget {
  const _EmptyWalkthrough();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '当前没有可走读的项目理解单元。',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
