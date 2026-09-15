import 'dart:async';
import 'dart:typed_data';

import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/core/theme/app_theme.dart';
import 'package:anchor_learning/data/models/deck.dart';
import 'package:anchor_learning/data/models/programming_exercise.dart';
import 'package:anchor_learning/data/models/programming_exercise_attempt.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/study_record.dart';
import 'package:anchor_learning/data/models/user_stats.dart';
import 'package:anchor_learning/features/settings/privacy_data_screen.dart';
import 'package:anchor_learning/services/gamification_service.dart';
import 'package:anchor_learning/services/agent/learning_agent_planner_service.dart';
import 'package:anchor_learning/services/ai/ai_api_protocol.dart';
import 'package:anchor_learning/services/ai/ai_model_acceptance.dart';
import 'package:anchor_learning/services/onboarding/first_run_model_readiness.dart';
import 'package:anchor_learning/services/privacy/local_data_backup_service.dart';
import 'package:anchor_learning/services/privacy/local_data_deletion_service.dart';
import 'package:anchor_learning/services/privacy/privacy_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    await tester.pump(const Duration(milliseconds: 400));

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

  testWidgets('restore owns a pending picker before accepting another tap',
      (tester) async {
    final picker = _ControlledFilePickerPlatform.pending();
    final originalPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            _MemoryPrivacyPreferencesStore(),
          ),
          productEventListProvider.overrideWith((ref) async => const []),
          localDataBackupServiceProvider.overrideWithValue(
            _FakeLocalDataBackupService(),
          ),
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
    await tester.pump();
    await tester.tap(find.text('从备份恢复'));
    await tester.pump();

    expect(picker.pickCalls, 1);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    picker.pending!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('picker failure is visible and restore can be retried',
      (tester) async {
    final picker = _ControlledFilePickerPlatform.throwing(
      StateError('picker unavailable'),
    );
    final originalPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);

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
      find.text('从备份恢复'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('从备份恢复'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('恢复失败: Bad state: picker unavailable'),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从备份恢复'));
    await tester.pumpAndSettle();
    expect(picker.pickCalls, 2);
  });

  testWidgets('cancelled and invalid selections release restore ownership',
      (tester) async {
    final originalPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _ControlledFilePickerPlatform.cancelled();
    addTearDown(() => FilePickerPlatform.instance = originalPicker);

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
      find.text('从备份恢复'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('从备份恢复'));
    await tester.pumpAndSettle();
    expect(find.text('替换本地学习数据？'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    FilePickerPlatform.instance = _ControlledFilePickerPlatform.invalid();
    await tester.tap(find.text('从备份恢复'));
    await tester.pumpAndSettle();
    expect(find.text('无法读取所选备份文件'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('pending picker completion after route exit does not restore',
      (tester) async {
    final picker = _ControlledFilePickerPlatform.pending();
    final backupService = _FakeLocalDataBackupService();
    final originalPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            _MemoryPrivacyPreferencesStore(),
          ),
          productEventListProvider.overrideWith((ref) async => const []),
          localDataBackupServiceProvider.overrideWithValue(backupService),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          home: const PrivacyDataScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('从备份恢复'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('从备份恢复'));
    await tester.pump();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    picker.pending!.complete(_FakePlatformFile(
      'C:/fixtures/anchor-learning-backup.db',
    ));
    await tester.pumpAndSettle();

    expect(backupService.restoreCalls, 0);
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

  for (final leaveRoute in [false, true]) {
    for (final scope in [
      LocalDataScope.learningHistory,
      LocalDataScope.learningContent,
    ]) {
      testWidgets(
          '${scope.value} deletion refreshes subscribed data '
          '${leaveRoute ? 'after route exit' : 'while mounted'}',
          (tester) async {
        final harness = await _PrivacyHarness.open(tester);
        await harness.expectStoredData();

        await harness.startDeletion(tester, scope);
        expect(harness.deletion.calls, [
          <LocalDataScope>{scope}
        ]);
        if (leaveRoute) await harness.leave(tester);
        harness.deletion.pending.complete();
        await tester.pumpAndSettle();

        expect(harness.data.correct, 0);
        await harness.expectStoredData();
        expect(harness.data.deckIds,
            scope == LocalDataScope.learningHistory ? ['deck'] : isEmpty);
        if (leaveRoute) {
          expect(find.text('返回后的学习页面'), findsOneWidget);
          expect(find.text('所选本地数据已删除'), findsNothing);
        } else {
          expect(find.text('所选本地数据已删除'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'restore refreshes subscribed data '
        '${leaveRoute ? 'after route exit' : 'while mounted'}', (tester) async {
      final harness = await _PrivacyHarness.open(tester);
      await harness.expectStoredData();
      await harness.startRestore(tester);
      expect(harness.backup.restoreCalls, 1);
      if (leaveRoute) await harness.leave(tester);

      harness.backup.pending!.complete();
      await tester.pumpAndSettle();

      expect(harness.data.correct, 24);
      await harness.expectStoredData();
      if (leaveRoute) {
        expect(find.text('返回后的学习页面'), findsOneWidget);
        expect(find.text('本地数据恢复完成'), findsNothing);
      } else {
        expect(find.text('本地数据恢复完成'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'partial deletion failure refreshes changed data and allows retry',
      (tester) async {
    final harness = await _PrivacyHarness.open(tester);
    harness.deletion.failure = StateError('legacy cleanup failed');
    await harness.expectStoredData();
    await harness.startDeletion(tester, LocalDataScope.learningHistory);
    harness.deletion.pending.complete();
    await tester.pumpAndSettle();

    expect(find.textContaining('删除失败:'), findsOneWidget);
    expect(find.text('所选本地数据已删除'), findsNothing);
    await harness.expectStoredData();

    // Let the first error SnackBar expire before asserting the retry message.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    harness.deletion.failure = null;
    harness.deletion.pending = Completer<void>();
    await harness.startDeletion(tester, LocalDataScope.learningHistory);
    harness.deletion.pending.complete();
    await tester.pumpAndSettle();
    expect(harness.deletion.calls, hasLength(2));
    await harness.expectStoredData();
    expect(find.text('所选本地数据已删除'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restore failure refreshes a snapshot read before rollback',
      (tester) async {
    final harness = await _PrivacyHarness.open(tester);
    await harness.expectStoredData();
    await harness.startRestore(tester);

    // A live consumer may read the candidate while validation is pending.
    harness.data.correct = 99;
    harness.container.invalidate(totalCorrectProvider);
    await tester.pump();
    expect(await harness.container.read(totalCorrectProvider.future), 99);
    harness.backup.onRestore = () => harness.data.correct = 12;
    harness.backup.failure = const LocalDataBackupException(
      code: LocalDataBackupErrorCode.restoreFailure,
      message: '恢复失败，已自动恢复原有数据。',
      rollbackSucceeded: true,
    );
    harness.backup.pending!.complete();
    await tester.pumpAndSettle();

    expect(find.textContaining('已自动恢复原有数据'), findsOneWidget);
    expect(find.text('本地数据恢复完成'), findsNothing);
    await harness.expectStoredData();
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial deletion failure still refreshes after route exit',
      (tester) async {
    final harness = await _PrivacyHarness.open(tester);
    harness.deletion.failure = StateError('legacy cleanup failed');
    await harness.startDeletion(tester, LocalDataScope.learningHistory);
    await harness.leave(tester);
    harness.deletion.pending.complete();
    await tester.pumpAndSettle();
    await harness.expectStoredData();
    expect(find.textContaining('删除失败:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restore rollback refreshes after route exit', (tester) async {
    final harness = await _PrivacyHarness.open(tester);
    await harness.startRestore(tester);
    await harness.leave(tester);
    harness.data.correct = 99;
    harness.container.invalidate(totalCorrectProvider);
    await tester.pump();
    expect(await harness.container.read(totalCorrectProvider.future), 99);
    harness.backup.onRestore = () => harness.data.correct = 12;
    harness.backup.failure = StateError('rolled back');
    harness.backup.pending!.complete();
    await tester.pumpAndSettle();
    await harness.expectStoredData();
    expect(tester.takeException(), isNull);
  });

  testWidgets('model deletion refreshes readiness and preserves learning data',
      (tester) async {
    final harness = await _PrivacyHarness.open(tester);
    harness.container.listen(firstRunModelReadinessProvider, (_, __) {});
    expect(
        (await harness.container.read(firstRunModelReadinessProvider.future))
            .hasCredential,
        isTrue);
    await harness.startDeletion(tester, LocalDataScope.modelConfiguration);
    harness.deletion.pending.complete();
    await tester.pumpAndSettle();
    expect(
        (await harness.container.read(firstRunModelReadinessProvider.future))
            .hasCredential,
        isFalse);
    expect(harness.data.correct, 12);
    await harness.expectStoredData();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'onboarding deletion refreshes the goal and preserves learning data',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'learning_agent_goal': LearningAgentGoal.programmingFoundations.value,
    });
    final harness = await _PrivacyHarness.open(tester);
    harness.container.listen(learningAgentGoalProvider, (_, __) {});
    await tester.pumpAndSettle();
    expect(harness.container.read(learningAgentGoalProvider),
        LearningAgentGoal.programmingFoundations);
    await harness.startDeletion(tester, LocalDataScope.onboardingState);
    harness.deletion.pending.complete();
    await tester.pumpAndSettle();
    expect(harness.container.read(learningAgentGoalProvider),
        LearningAgentGoal.aiInterviewPrep);
    expect(harness.data.correct, 12);
    await harness.expectStoredData();
    expect(tester.takeException(), isNull);
  });

  for (final restoring in [false, true]) {
    testWidgets(
        'accepted ${restoring ? 'restore' : 'deletion'} finishes after scope disposal',
        (tester) async {
      final harness = await _PrivacyHarness.open(tester);
      if (restoring) {
        await harness.startRestore(tester);
      } else {
        await harness.startDeletion(tester, LocalDataScope.learningHistory);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();

      if (restoring) {
        harness.backup.pending!.complete();
      } else {
        harness.deletion.pending.complete();
      }
      await tester.pumpAndSettle();
      expect(harness.data.correct, restoring ? 24 : 0);
      expect(tester.takeException(), isNull);
    });
  }
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

class _ControlledFilePickerPlatform extends FilePickerPlatform {
  final Completer<PlatformFile?>? pending;
  final Object? failure;
  final String? selectedPath;
  int pickCalls = 0;

  _ControlledFilePickerPlatform._({
    this.pending,
    this.failure,
    this.selectedPath,
  });

  factory _ControlledFilePickerPlatform.pending() =>
      _ControlledFilePickerPlatform._(pending: Completer<PlatformFile?>());

  factory _ControlledFilePickerPlatform.cancelled() =>
      _ControlledFilePickerPlatform._();

  factory _ControlledFilePickerPlatform.invalid() =>
      _ControlledFilePickerPlatform._(selectedPath: '');

  factory _ControlledFilePickerPlatform.throwing(Object failure) =>
      _ControlledFilePickerPlatform._(failure: failure);

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
  }) {
    pickCalls++;
    if (failure != null) return Future<PlatformFile?>.error(failure!);
    if (pending != null) return pending!.future;
    final path = selectedPath;
    return Future.value(path == null ? null : _FakePlatformFile(path));
  }
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
  int restoreCalls = 0;
  Completer<void>? pending;
  VoidCallback? onRestore;
  Object? failure;

  _FakeLocalDataBackupService() : super(databaseHelper: DatabaseHelper());

  @override
  Future<LocalDataRestoreResult> restoreBackup(String sourcePath) async {
    restoreSourcePath = sourcePath;
    restoreCalls++;
    await pending?.future;
    onRestore?.call();
    final error = failure;
    if (error != null) throw error;
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

class _PrivacyHarness {
  final data = _StoredPrivacyData();
  final database = _BlockedDatabase();
  final navigator = GlobalKey<NavigatorState>();
  late final _ControlledDeletionService deletion;
  late final _FakeLocalDataBackupService backup;
  late final ProviderContainer container;
  bool _disposed = false;

  _PrivacyHarness() {
    deletion = _ControlledDeletionService(data);
    backup = _FakeLocalDataBackupService()
      ..pending = Completer<void>()
      ..onRestore = data.restore;
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(database),
      privacyPreferencesStoreProvider.overrideWithValue(
        _MemoryPrivacyPreferencesStore(),
      ),
      productEventListProvider.overrideWith((ref) async => const []),
      localDataDeletionServiceProvider.overrideWithValue(deletion),
      localDataBackupServiceProvider.overrideWithValue(backup),
      gamificationServiceProvider.overrideWithValue(_StoredGamification(data)),
      studyRecordProvider.overrideWith((ref, deckId) async => data.record),
      allProgrammingExercisesProvider
          .overrideWith((ref) async => data.exercises),
      allProgrammingExerciseAttemptsProvider.overrideWith(
        (ref) async => data.attempts,
      ),
      programmingExerciseAttemptsProvider.overrideWith(
        (ref, exerciseId) async => data.attempts,
      ),
      deckListProvider.overrideWith((ref) async => data.decks),
      sourceListProvider.overrideWith((ref) async => data.sources),
      firstRunModelReadinessProvider
          .overrideWith((ref) async => FirstRunModelReadiness(
                configuration: AiModelConfiguration(
                  providerId: 'synthetic',
                  baseUrl: 'https://example.invalid/v1',
                  model: 'synthetic',
                  protocol: AiApiProtocol.chatCompletions,
                ),
                hasCredential: data.hasCredential,
                acceptanceReport: null,
              )),
    ]);
    // Keep the same consumers alive across navigation, as the tab shell does.
    for (final provider in <ProviderListenable<Object?>>[
      userStatsProvider,
      totalCorrectProvider,
      perfectCountProvider,
      monthlyCheckInProvider('2026_9'),
      earnedMedalsProvider,
      studyRecordProvider('deck'),
      allProgrammingExercisesProvider,
      allProgrammingExerciseAttemptsProvider,
      programmingExerciseAttemptsProvider('exercise'),
      deckListProvider,
      sourceListProvider,
    ]) {
      container.listen<Object?>(provider, (_, __) {});
    }
  }

  static Future<_PrivacyHarness> open(WidgetTester tester) async {
    final harness = _PrivacyHarness();
    final originalPicker = FilePickerPlatform.instance;
    FilePickerPlatform.instance =
        _FakeFilePickerPlatform('C:/fixtures/anchor-learning-backup.db');
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
      FilePickerPlatform.instance = originalPicker;
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        navigatorKey: harness.navigator,
        home: Scaffold(
          body: Builder(builder: (context) {
            return Column(children: [
              const Text('返回后的学习页面'),
              TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const PrivacyDataScreen()),
                ),
                child: const Text('打开隐私页面'),
              ),
            ]);
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开隐私页面'));
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> startDeletion(WidgetTester tester, LocalDataScope scope) async {
    await tester.scrollUntilVisible(find.text('选择删除范围'), 300,
        scrollable: find.byType(Scrollable));
    await tester.tap(find.text('选择删除范围'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(scope.label));
    await tester.pump();
    await tester.tap(find.text('确认删除'));
    if ({
      LocalDataScope.learningHistory,
      LocalDataScope.learningContent,
      LocalDataScope.productEvents,
    }.contains(scope)) {
      await tester.pumpAndSettle();
      await tester.tap(find.text('直接删除'));
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> startRestore(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('从备份恢复'), 200,
        scrollable: find.byType(Scrollable));
    await tester.tap(find.text('从备份恢复'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('确认恢复'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> leave(WidgetTester tester) async {
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
  }

  Future<void> expectStoredData() async {
    expect(database.attempts, 0,
        reason: 'Refreshing cached consumers must not start unrelated reads');
    expect(container.read(userStatsProvider).requireValue.xp, data.stats.xp,
        reason: 'XP must reflect the stored result');
    expect(await container.read(totalCorrectProvider.future), data.correct,
        reason: 'total correct must reflect the stored result');
    expect(await container.read(perfectCountProvider.future), data.perfect);
    expect(await container.read(monthlyCheckInProvider('2026_9').future),
        data.checkIns);
    expect(await container.read(earnedMedalsProvider.future), data.medals);
    expect(
        await container.read(studyRecordProvider('deck').future), data.record);
    expect(
        (await container.read(allProgrammingExercisesProvider.future))
            .map((item) => item.id),
        data.exerciseIds);
    expect(
        (await container.read(allProgrammingExerciseAttemptsProvider.future))
            .map((item) => item.id),
        data.attemptIds);
    expect(
        (await container
                .read(programmingExerciseAttemptsProvider('exercise').future))
            .map((item) => item.id),
        data.attemptIds);
    expect(
        (await container.read(deckListProvider.future)).map((item) => item.id),
        data.deckIds);
    expect(
        (await container.read(sourceListProvider.future))
            .map((item) => item.id),
        data.sourceIds);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    container.dispose();
  }
}

class _StoredPrivacyData {
  static final now = DateTime(2026, 9, 9);
  UserStats stats = UserStats(xp: 120, hearts: 4, lastStudyDate: now);
  int correct = 12;
  int perfect = 3;
  bool hasCredential = true;
  List<String> checkIns = ['2026-09-01', '2026-09-09'];
  List<({int year, int month})> medals = [(year: 2026, month: 8)];
  StudyRecord? record = StudyRecord(
      id: 'deck_record',
      deckId: 'deck',
      correctCount: 1,
      totalCount: 2,
      lastStudiedAt: now);
  List<String> exerciseIds = ['exercise'];
  List<String> attemptIds = ['attempt'];
  List<String> deckIds = ['deck'];
  List<String> sourceIds = ['source'];

  List<ProgrammingExercise> get exercises => exerciseIds
      .map((id) => ProgrammingExercise(
          id: id,
          knowledgePointId: 'point',
          kind: ProgrammingExerciseKind.explanation,
          prompt: 'Synthetic prompt',
          referenceAnswer: 'Synthetic answer',
          conceptAccuracyCriterion: '',
          reasoningProcessCriterion: '',
          evidenceUseCriterion: '',
          clarityCriterion: '',
          createdAt: now,
          updatedAt: now))
      .toList();
  List<ProgrammingExerciseAttempt> get attempts => attemptIds
      .map((id) => ProgrammingExerciseAttempt(
          id: id,
          exerciseId: 'exercise',
          knowledgePointId: 'point',
          userAnswer: 'Synthetic answer',
          feedback: 'Synthetic feedback',
          createdAt: now))
      .toList();
  List<Deck> get decks => deckIds
      .map((id) => Deck(id: id, title: id, createdAt: now, updatedAt: now))
      .toList();
  List<Source> get sources => sourceIds
      .map((id) => Source(
          id: id,
          title: id,
          type: SourceType.project,
          trustLevel: SourceTrustLevel.sourceCode,
          createdAt: now,
          updatedAt: now))
      .toList();

  void delete(Set<LocalDataScope> scopes) {
    if (scopes.contains(LocalDataScope.learningHistory) ||
        scopes.contains(LocalDataScope.learningContent)) {
      stats = stats.copyWith(xp: 0, hearts: 5, streak: 0, todayXp: 0);
      correct = 0;
      perfect = 0;
      checkIns = [];
      medals = [];
      record = null;
      attemptIds = [];
    }
    if (scopes.contains(LocalDataScope.learningContent)) {
      exerciseIds = [];
      deckIds = [];
      sourceIds = [];
    }
  }

  void restore() {
    stats = stats.copyWith(xp: 240, hearts: 5);
    correct = 24;
    perfect = 6;
    checkIns = ['2026-09-02'];
    medals = [(year: 2026, month: 7)];
    record = null;
    exerciseIds = ['restored-exercise'];
    attemptIds = ['restored-attempt'];
    deckIds = ['restored-deck'];
    sourceIds = ['restored-source'];
  }
}

class _StoredGamification extends GamificationService {
  final _StoredPrivacyData data;
  _StoredGamification(this.data) : super(DatabaseHelper());

  @override
  Future<UserStats> getStats() async => data.stats;
  @override
  Future<int> getTotalCorrect() async => data.correct;
  @override
  Future<int> getPerfectCount() async => data.perfect;
  @override
  Future<List<String>> getMonthlyCheckInDates(int year, int month) async =>
      data.checkIns;
  @override
  Future<List<({int year, int month})>> getEarnedMedals() async => data.medals;
}

class _ControlledDeletionService implements LocalDataDeletionService {
  final _StoredPrivacyData data;
  Completer<void> pending = Completer<void>();
  Object? failure;
  final calls = <Set<LocalDataScope>>[];
  _ControlledDeletionService(this.data);

  @override
  Future<LocalDataDeletionResult> delete(Set<LocalDataScope> scopes) async {
    calls.add(Set.of(scopes));
    await pending.future;
    data.delete(scopes);
    if (scopes.contains(LocalDataScope.modelConfiguration)) {
      data.hasCredential = false;
    }
    if (scopes.contains(LocalDataScope.onboardingState)) {
      await (await SharedPreferences.getInstance())
          .remove('learning_agent_goal');
    }
    final error = failure;
    if (error != null) throw error;
    return LocalDataDeletionResult(scopes: scopes, deletedRows: const {});
  }
}

class _BlockedDatabase implements DatabaseHelper {
  int attempts = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    attempts++;
    throw StateError('Unexpected database access in the isolated fixture');
  }
}
