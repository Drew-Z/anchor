import 'package:anchor_learning/core/constants/app_metadata.dart';
import 'package:anchor_learning/features/settings/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('about page exposes release boundaries at large text scale',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: AboutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppMetadata.productName), findsOneWidget);
    expect(
      find.text('${AppMetadata.releaseChannel} · ${AppMetadata.version}'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('已知限制'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('已知限制'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('模型需要自行配置与验收'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('模型需要自行配置与验收'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('本地数据与隐私'),
      300,
      scrollable: find.byType(Scrollable),
    );
    final privacyAction = find.bySemanticsLabel('打开本地数据与隐私');
    expect(privacyAction, findsOneWidget);
    expect(
      tester
          .getSemantics(privacyAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
