import 'dart:typed_data';

import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/features/settings/privacy_data_screen.dart';
import 'package:anchor_learning/services/privacy/local_data_backup_service.dart';
import 'package:anchor_learning/services/privacy/privacy_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('privacy data screen fits a narrow Android viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _MemoryPrivacyPreferencesStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(store),
          productEventListProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: PrivacyDataScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('本地数据与隐私'), findsOneWidget);
    expect(find.text('记录本地产品事件'), findsOneWidget);
    expect(find.text('导出本地数据备份'), findsOneWidget);
    expect(find.text('从备份恢复'), findsOneWidget);
    expect(find.text('导出本地事件'), findsOneWidget);
    expect(find.text('暂无本地事件'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restore requires confirmation and refreshes database state',
      (tester) async {
    final backupService = _FakeLocalDataBackupService();
    final originalPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance =
        _FakeFilePickerPlatform('C:/fixtures/anchor-learning-backup.db');
    addTearDown(() => FilePickerPlatform.instance = originalPicker);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            _MemoryPrivacyPreferencesStore(),
          ),
          productEventListProvider.overrideWith((ref) async => const []),
          localDataBackupServiceProvider.overrideWithValue(backupService),
        ],
        child: const MaterialApp(home: PrivacyDataScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('从备份恢复'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('从备份恢复'));
    await tester.pumpAndSettle();

    expect(find.text('替换本地学习数据？'), findsOneWidget);
    expect(find.textContaining('自动创建回滚快照'), findsOneWidget);
    expect(backupService.restoreSourcePath, isNull);

    await tester.tap(find.text('确认恢复'));
    await tester.pumpAndSettle();

    expect(
      backupService.restoreSourcePath,
      'C:/fixtures/anchor-learning-backup.db',
    );
    expect(find.text('本地数据恢复完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('database deletion offers backup before destructive action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            _MemoryPrivacyPreferencesStore(),
          ),
          productEventListProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: PrivacyDataScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('选择删除范围'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('选择删除范围'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('学习历史'));
    await tester.pump();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除前是否备份？'), findsOneWidget);
    expect(find.text('直接删除'), findsOneWidget);
    expect(find.text('备份后删除'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backup actions remain accessible at 200 percent text scale',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            _MemoryPrivacyPreferencesStore(),
          ),
          productEventListProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: PrivacyDataScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('导出本地数据备份'),
      300,
      scrollable: find.byType(Scrollable),
    );
    final exportAction = find.bySemanticsLabel('导出本地数据备份');
    expect(exportAction, findsOneWidget);
    expect(
      tester
          .getSemantics(exportAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

class _FakeFilePickerPlatform extends FilePickerPlatform {
  final String selectedPath;

  _FakeFilePickerPlatform(this.selectedPath);

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async =>
      _FakePlatformFile(selectedPath);
}

base class _FakePlatformFile extends PlatformFile {
  final String selectedPath;

  _FakePlatformFile(this.selectedPath);

  @override
  String get name => selectedPath.split(RegExp(r'[/\\]')).last;

  @override
  Uri get uri => Uri.file(selectedPath);

  @override
  String? get path => selectedPath;

  @override
  XFile get xFile => XFile(selectedPath);

  @override
  Future<int> length() async => 1024;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => const Stream.empty();
}

class _FakeLocalDataBackupService extends LocalDataBackupService {
  String? restoreSourcePath;

  _FakeLocalDataBackupService() : super(databaseHelper: DatabaseHelper());

  @override
  Future<LocalDataRestoreResult> restoreBackup(String sourcePath) async {
    restoreSourcePath = sourcePath;
    const validation = LocalDataBackupValidation(
      schemaVersion: DatabaseHelper.schemaVersion,
      fileSizeBytes: 1024,
      foreignKeyViolationCount: 0,
      tableNames: {},
    );
    return const LocalDataRestoreResult(
      candidateValidation: validation,
      restoredValidation: validation,
      migrationApplied: false,
    );
  }
}

class _MemoryPrivacyPreferencesStore implements PrivacyPreferencesStore {
  PrivacyPreferences preferences = const PrivacyPreferences();
  String installId = 'test-install';

  @override
  Future<PrivacyPreferences> read() async => preferences;

  @override
  Future<String> readOrCreateAnonymousInstallId() async => installId;

  @override
  Future<void> resetAnonymousInstallId() async => installId = 'reset-install';

  @override
  Future<void> write(PrivacyPreferences preferences) async {
    this.preferences = preferences;
  }
}
