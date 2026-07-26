import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/providers.dart';
import 'first_run_screen.dart';

class FirstRunGate extends ConsumerWidget {
  final Widget completedChild;

  const FirstRunGate({
    super.key,
    required this.completedChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(firstRunProgressProvider);
    return progressAsync.when(
      data: (progress) => progress.isCompleted
          ? completedChild
          : FirstRunScreen(progress: progress),
      loading: () => const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sync_problem_outlined,
                    color: AppColors.red,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '首次运行状态读取失败',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(firstRunProgressProvider.notifier).load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
