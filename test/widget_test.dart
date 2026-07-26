import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dlg_q/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/services/onboarding/first_run_progress.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final originalErrorWidgetBuilder = ErrorWidget.builder;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      SharedPreferencesFirstRunProgressStore.storageKey: jsonEncode(
        FirstRunProgress.initial(now: DateTime.utc(2026, 7, 16)).toJson(),
      ),
    });
    final databaseHelper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    addTearDown(databaseHelper.close);

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(databaseHelper),
          ],
          child: const DIYDuolingoApp(),
        ),
      );
      for (var attempt = 0; attempt < 30; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('选择本轮学习目标').evaluate().isNotEmpty) break;
      }
      final renderedText = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .join(' | ');
      expect(
        find.text('选择本轮学习目标'),
        findsOneWidget,
        reason: renderedText,
      );
      expect(find.text('确认目标'), findsOneWidget);
    } finally {
      ErrorWidget.builder = originalErrorWidgetBuilder;
    }
  });
}
