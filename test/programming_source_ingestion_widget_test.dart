import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_learning/features/ingestion/ingestion_screen.dart';

void main() {
  testWidgets('preferred programming sources expand required provenance fields',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: IngestionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('来源档案 · 可选'), findsOneWidget);
    expect(find.text('规范来源 URL *'), findsNothing);

    await tester.tap(find.text('官方文档'));
    await tester.pumpAndSettle();

    expect(find.text('来源档案 · 必填'), findsOneWidget);
    expect(find.text('规范来源 URL *'), findsOneWidget);
    expect(find.text('发布者 / 仓库所有者 *'), findsOneWidget);
    expect(find.text('版本 / tag / commit *'), findsOneWidget);
  });
}
