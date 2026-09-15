import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/features/ingestion/project_import_screen.dart';
import 'package:anchor_learning/services/ingestion/android_project_directory_bridge.dart';
import 'package:anchor_learning/services/ingestion/project_source_import_service.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/disabled_privacy_preferences_store.dart';

void main() {
  setUp(() {
    FilePickerPlatform.instance = _ControlledFilePickerPlatform();
  });

  tearDown(() {
    FilePickerPlatform.instance = _ControlledFilePickerPlatform();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('pending ZIP picker owns both source buttons', (tester) async {
    final picker = _ControlledFilePickerPlatform.pending();
    FilePickerPlatform.instance = picker;
    final scanner = _ControlledProjectSourceImportService(
      snapshot: _snapshot(ProjectSourceImportKind.zip),
    );
    await _pumpScreen(tester, scanner: scanner);

    await tester.tap(find.text('选择 ZIP'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(_button(tester, '选择 ZIP').onPressed, isNull);
    expect(_button(tester, '选择目录').onPressed, isNull);

    await tester.tap(find.text('选择 ZIP'));
    await tester.pump();
    expect(picker.pickFilesCalls, 1);
    expect(scanner.scanZipCalls, 0);

    picker.pendingPick!.complete(const <PlatformFile>[]);
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(_button(tester, '选择 ZIP').onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ZIP picker failure is visible and retryable', (tester) async {
    final picker = _ControlledFilePickerPlatform.throwing(
      StateError('picker unavailable'),
    );
    FilePickerPlatform.instance = picker;
    await _pumpScreen(
      tester,
      scanner: _ControlledProjectSourceImportService(
        snapshot: _snapshot(ProjectSourceImportKind.zip),
      ),
    );

    await tester.tap(find.text('选择 ZIP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('项目扫描失败: Bad state: picker unavailable'),
        findsOneWidget);
    expect(_button(tester, '选择 ZIP').onPressed, isNotNull);

    picker.failure = null;
    picker.selectedFile = _FakePlatformFile('fixture.zip');
    await tester.tap(find.text('选择 ZIP'));
    await tester.pumpAndSettle();
    expect(picker.pickFilesCalls, 2);
    expect(find.text('项目扫描失败: Bad state: picker unavailable'), findsNothing);
    expect(find.textContaining('已发现 0 个可学习文件'), findsOneWidget);
  });

  testWidgets('pending Android directory picker can be cancelled',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final bridge = _ControlledAndroidDirectoryBridge.pending();
    await _pumpScreen(
      tester,
      scanner: _ControlledProjectSourceImportService(
        snapshot: _snapshot(ProjectSourceImportKind.directory),
      ),
      bridge: bridge,
    );

    await tester.tap(find.text('选择目录'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(_button(tester, '选择目录').onPressed, isNull);
    expect(_button(tester, '选择 ZIP').onPressed, isNull);

    bridge.pendingPick!.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(_button(tester, '选择目录').onPressed, isNotNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('late ZIP picker result after route exit does not scan',
      (tester) async {
    final picker = _ControlledFilePickerPlatform.pending();
    FilePickerPlatform.instance = picker;
    final scanner = _ControlledProjectSourceImportService(
      snapshot: _snapshot(ProjectSourceImportKind.zip),
    );
    await _pumpScreen(tester, scanner: scanner);

    await tester.tap(find.text('选择 ZIP'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    picker.pendingPick!.complete([_FakePlatformFile('late.zip')]);
    await tester.pumpAndSettle();

    expect(scanner.scanZipCalls, 0);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _ControlledProjectSourceImportService scanner,
  _ControlledAndroidDirectoryBridge? bridge,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        privacyPreferencesStoreProvider.overrideWithValue(
          const DisabledPrivacyPreferencesStore(),
        ),
        projectSourceImportServiceProvider.overrideWithValue(scanner),
        if (bridge != null)
          androidProjectDirectoryBridgeProvider.overrideWithValue(bridge),
      ],
      child: const MaterialApp(home: ProjectImportScreen()),
    ),
  );
  await tester.pump();
}

OutlinedButton _button(WidgetTester tester, String label) {
  return tester.widget<OutlinedButton>(
    find.widgetWithText(OutlinedButton, label),
  );
}

ProjectSourceSnapshot _snapshot(ProjectSourceImportKind kind) {
  return ProjectSourceSnapshot(
    kind: kind,
    displayName: 'Demo project',
    sourceUri:
        kind == ProjectSourceImportKind.zip ? 'demo.zip' : 'content://demo',
    revision: 'snapshot:demo',
    files: const [],
    exclusions: const [],
  );
}

class _ControlledProjectSourceImportService extends ProjectSourceImportService {
  final ProjectSourceSnapshot snapshot;
  int scanZipCalls = 0;
  int scanDirectoryCalls = 0;

  _ControlledProjectSourceImportService({required this.snapshot});

  @override
  Future<ProjectSourceSnapshot> scanZipFile(String zipPath) async {
    scanZipCalls++;
    return snapshot;
  }

  @override
  Future<ProjectSourceSnapshot> scanZipBytes({
    required String archiveName,
    required List<int> bytes,
    String? sourceUri,
  }) async {
    scanZipCalls++;
    return snapshot;
  }

  @override
  Future<ProjectSourceSnapshot> scanDirectory(String rootPath) async {
    scanDirectoryCalls++;
    return snapshot;
  }

  @override
  Future<ProjectSourceSnapshot> scanDirectoryEntries({
    required String displayName,
    required String sourceUri,
    required List<ProjectSourceInputFile> entries,
  }) async {
    scanDirectoryCalls++;
    return snapshot;
  }
}

class _ControlledAndroidDirectoryBridge extends AndroidProjectDirectoryBridge {
  final Completer<AndroidProjectDirectorySelection?>? pendingPick;

  _ControlledAndroidDirectoryBridge._({this.pendingPick});

  factory _ControlledAndroidDirectoryBridge.pending() =>
      _ControlledAndroidDirectoryBridge._(
        pendingPick: Completer<AndroidProjectDirectorySelection?>(),
      );

  @override
  Future<AndroidProjectDirectorySelection?> pickDirectory() {
    final pending = pendingPick;
    if (pending != null) return pending.future;
    return Future.value();
  }

  @override
  Future<List<ProjectSourceInputFile>> listDirectory({
    required String treeUri,
    required int maxFileBytes,
    int maxEntries = AndroidProjectDirectoryBridge.defaultMaxEntries,
  }) async =>
      const [];
}

class _ControlledFilePickerPlatform extends FilePickerPlatform {
  final Completer<List<PlatformFile>>? pending;
  Object? failure;
  PlatformFile? selectedFile;
  int pickFilesCalls = 0;

  _ControlledFilePickerPlatform._({this.pending, this.failure});

  factory _ControlledFilePickerPlatform() => _ControlledFilePickerPlatform._();

  factory _ControlledFilePickerPlatform.pending() =>
      _ControlledFilePickerPlatform._(
        pending: Completer<List<PlatformFile>>(),
      );

  factory _ControlledFilePickerPlatform.throwing(Object failure) =>
      _ControlledFilePickerPlatform._(failure: failure);

  Completer<List<PlatformFile>>? get pendingPick => pending;

  @override
  Future<List<PlatformFile>> pickFiles({
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
    pickFilesCalls++;
    final error = failure;
    if (error != null) return Future<List<PlatformFile>>.error(error);
    final waiting = pending;
    if (waiting != null) return waiting.future;
    final file = selectedFile;
    return Future.value(file == null ? const [] : [file]);
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
