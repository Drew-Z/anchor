import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_metadata.dart';
import 'privacy_data_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void openPrivacyData() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PrivacyDataScreen()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Icon(
              Icons.school_outlined,
              size: 52,
              color: AppColors.green,
              semanticLabel: '多多学应用图标',
            ),
            const SizedBox(height: 12),
            const Text(
              AppMetadata.productName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '${AppMetadata.releaseChannel} · ${AppMetadata.version}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            const _SectionTitle('当前支持'),
            const SizedBox(height: 6),
            const _BoundaryItem(
              icon: Icons.android_outlined,
              title: 'Android 私测',
              description:
                  '当前发布练习以 Android 模拟器和私测设备为准；iOS、Windows、macOS 与 Linux 尚未列入发布支持范围。',
            ),
            const _BoundaryItem(
              icon: Icons.storage_outlined,
              title: '本地优先',
              description: '学习数据保存在本机 SQLite 中，当前没有账户、云同步或跨设备合并。',
            ),
            const Divider(height: 32),
            const _SectionTitle('已知限制'),
            const SizedBox(height: 6),
            const _BoundaryItem(
              icon: Icons.model_training_outlined,
              title: '模型需要自行配置与验收',
              description:
                  '应用没有已批准的默认模型配置。正式学习调用前，当前 provider、协议和模型必须通过应用内五项验收。',
            ),
            const _BoundaryItem(
              icon: Icons.settings_backup_restore_outlined,
              title: '备份范围有限',
              description: '数据库备份包含学习内容、学习记录和本地产品事件，不包含模型凭据、模型配置、首次运行状态或隐私偏好。',
            ),
            const _BoundaryItem(
              icon: Icons.account_tree_outlined,
              title: '受控的单 Agent 编排',
              description: '当前是本地、来源约束的学习编排器，不提供远程多 Agent、后台长任务或跨设备恢复。',
            ),
            const _BoundaryItem(
              icon: Icons.restore_page_outlined,
              title: '恢复兼容边界',
              description:
                  '恢复文件必须是完整 SQLite 数据库，最大 512 MB；当前接受 schema 12 到 23，并在替换失败时自动回滚。',
            ),
            const Divider(height: 32),
            const _SectionTitle('数据与支持'),
            Semantics(
              button: true,
              label: '打开本地数据与隐私',
              excludeSemantics: true,
              onTap: openPrivacyData,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text(
                  '本地数据与隐私',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('检查事件、导出支持包、备份、恢复或删除数据。'),
                trailing: const Icon(Icons.chevron_right),
                onTap: openPrivacyData,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '自定义题库与来源约束 AI 学习应用',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
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
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _BoundaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BoundaryItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(description, style: const TextStyle(height: 1.4)),
      ),
    );
  }
}
