import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/services/privacy/alpha_feedback_service.dart';
import 'package:dlg_q/services/privacy/support_bundle_service.dart';
import 'package:dlg_q/shared/widgets/alpha_feedback_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('feedback dialog shows export scope and submits a saved draft',
      (tester) async {
    AlphaFeedbackDraft? recordedDraft;
    final service = AlphaFeedbackService(
      databaseSchemaVersion: 23,
      supportBundleBuilder: (_) async => const LocalTextExport(
        fileName: 'support.json',
        content: '{"bundle_schema_version":1}',
      ),
      artifactSaver: (_) async => true,
      eventRecorder: (draft) async => recordedDraft = draft,
      clock: () => DateTime.utc(2026, 7, 16, 10),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alphaFeedbackServiceProvider.overrideWithValue(service),
          productEventListProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [
                AlphaFeedbackIconButton(screenId: 'agent_workspace'),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('提交私测反馈'));
    await tester.pumpAndSettle();
    expect(find.text('提交 Private Alpha 反馈'), findsOneWidget);
    expect(find.textContaining('不会附加诊断'), findsOneWidget);

    await tester.tap(find.text('反馈类型'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('功能建议').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '希望成果页支持按证据缺口排序。');
    await tester.tap(find.text('附加脱敏诊断'));
    await tester.pump();
    expect(find.textContaining('以及脱敏诊断'), findsOneWidget);

    await tester.tap(find.text('导出反馈'));
    await tester.pumpAndSettle();

    expect(recordedDraft, isNotNull);
    expect(recordedDraft!.category, AlphaFeedbackCategory.featureRequest);
    expect(recordedDraft!.diagnosticConsent, isTrue);
    expect(find.textContaining('反馈已导出'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'feedback dialog fits a narrow viewport at 200 percent text scale',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: AlphaFeedbackButton(screenId: 'error_state'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('提交反馈'));
    await tester.pumpAndSettle();
    expect(find.text('提交 Private Alpha 反馈'), findsOneWidget);
    expect(find.text('导出反馈'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
