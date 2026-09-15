import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

enum PrivateAlphaDeviceStatus {
  ready,
  hold,
  passed,
  failed,
}

class PrivateAlphaDevicePreflightOptions {
  final String adbExecutable;
  final String apkPath;
  final String? serial;
  final String? expectedSha256;
  final bool execute;

  const PrivateAlphaDevicePreflightOptions({
    required this.apkPath,
    this.adbExecutable = 'adb',
    this.serial,
    this.expectedSha256,
    this.execute = false,
  });
}

class PrivateAlphaDeviceReport {
  final PrivateAlphaDeviceStatus status;
  final List<String> reasons;
  final String apkFileName;
  final int? apkBytes;
  final String? apkSha256;
  final String deviceKind;
  final String? manufacturer;
  final String? model;
  final String? abi;
  final int? apiLevel;
  final String? viewport;
  final String? density;
  final bool executionRequested;
  final bool executionAttempted;
  final bool? installSucceeded;
  final bool? coldStartSucceeded;
  final bool? processAlive;
  final int logErrorMatches;

  const PrivateAlphaDeviceReport({
    required this.status,
    required this.reasons,
    required this.apkFileName,
    required this.apkBytes,
    required this.apkSha256,
    required this.deviceKind,
    required this.manufacturer,
    required this.model,
    required this.abi,
    required this.apiLevel,
    required this.viewport,
    required this.density,
    required this.executionRequested,
    required this.executionAttempted,
    required this.installSucceeded,
    required this.coldStartSucceeded,
    required this.processAlive,
    required this.logErrorMatches,
  });

  Map<String, Object?> toJson() {
    return {
      'schema_version': 1,
      'status': status.name,
      'reasons': reasons,
      'model_gate': 'manual_in_app_5_of_5_required',
      'apk': {
        'file_name': apkFileName,
        'bytes': apkBytes,
        'sha256': apkSha256,
      },
      'device': {
        'kind': deviceKind,
        'manufacturer': manufacturer,
        'model': model,
        'abi': abi,
        'api_level': apiLevel,
        'viewport': viewport,
        'density': density,
      },
      'execution': {
        'requested': executionRequested,
        'attempted': executionAttempted,
        'install_succeeded': installSucceeded,
        'cold_start_succeeded': coldStartSucceeded,
        'process_alive': processAlive,
        'log_error_matches': logErrorMatches,
      },
    };
  }

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Private Alpha Device Preflight')
      ..writeln()
      ..writeln('- Status: `${status.name.toUpperCase()}`')
      ..writeln('- Reasons: ${reasons.isEmpty ? 'none' : reasons.join(', ')}')
      ..writeln('- APK: `$apkFileName`')
      ..writeln('- APK bytes: ${apkBytes ?? 'unavailable'}')
      ..writeln('- APK SHA-256: `${apkSha256 ?? 'unavailable'}`')
      ..writeln('- Device kind: $deviceKind')
      ..writeln('- Device: ${_deviceName()}')
      ..writeln(
          '- ABI / API: ${abi ?? 'unavailable'} / ${apiLevel ?? 'unavailable'}')
      ..writeln(
          '- Viewport / density: ${viewport ?? 'unavailable'} / ${density ?? 'unavailable'}')
      ..writeln('- Execution requested: $executionRequested')
      ..writeln('- Execution attempted: $executionAttempted')
      ..writeln('- Install succeeded: ${installSucceeded ?? 'not_run'}')
      ..writeln('- Cold start succeeded: ${coldStartSucceeded ?? 'not_run'}')
      ..writeln('- Process alive: ${processAlive ?? 'not_run'}')
      ..writeln('- Log error matches: $logErrorMatches')
      ..writeln('- Model gate: manual App `5/5` still required');
    return buffer.toString().trimRight();
  }

  String _deviceName() {
    final parts = [manufacturer, model]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? 'unavailable' : parts.join(' ');
  }
}

class DeviceCommandResult {
  final int exitCode;
  final String stdoutText;
  final String stderrText;

  const DeviceCommandResult({
    required this.exitCode,
    this.stdoutText = '',
    this.stderrText = '',
  });
}

abstract interface class DeviceCommandRunner {
  Future<DeviceCommandResult> run(String executable, List<String> arguments);
}

class SystemDeviceCommandRunner implements DeviceCommandRunner {
  const SystemDeviceCommandRunner();

  @override
  Future<DeviceCommandResult> run(
    String executable,
    List<String> arguments,
  ) async {
    try {
      final result = await Process.run(executable, arguments);
      return DeviceCommandResult(
        exitCode: result.exitCode,
        stdoutText: result.stdout.toString(),
        stderrText: result.stderr.toString(),
      );
    } on ProcessException catch (error) {
      return DeviceCommandResult(
        exitCode: 127,
        stderrText: error.message,
      );
    }
  }
}

class PrivateAlphaDevicePreflight {
  static const String packageName = 'cc.eu.playlab.anchor';
  static const String launchActivity = '$packageName/.MainActivity';

  final DeviceCommandRunner _runner;

  const PrivateAlphaDevicePreflight({
    DeviceCommandRunner runner = const SystemDeviceCommandRunner(),
  }) : _runner = runner;

  Future<PrivateAlphaDeviceReport> run(
    PrivateAlphaDevicePreflightOptions options,
  ) async {
    final apk = File(options.apkPath);
    final apkFileName = p.basename(options.apkPath);
    if (!await apk.exists()) {
      return _report(
        status: PrivateAlphaDeviceStatus.failed,
        reasons: const ['apk_missing'],
        options: options,
        apkFileName: apkFileName,
      );
    }
    final apkBytes = await apk.length();
    final apkSha256 = await sha256.bind(apk.openRead()).first.then(
          (digest) => digest.toString(),
        );
    final expectedHash = options.expectedSha256?.trim().toLowerCase();
    if (expectedHash != null &&
        expectedHash.isNotEmpty &&
        expectedHash != apkSha256) {
      return _report(
        status: PrivateAlphaDeviceStatus.failed,
        reasons: const ['apk_hash_mismatch'],
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
      );
    }

    final devicesResult = await _runner.run(
      options.adbExecutable,
      const ['devices', '-l'],
    );
    if (devicesResult.exitCode != 0) {
      return _report(
        status: PrivateAlphaDeviceStatus.failed,
        reasons: const ['adb_unavailable'],
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
      );
    }
    final serials = _connectedDeviceSerials(devicesResult.stdoutText);
    final serial = _selectSerial(serials, options.serial);
    if (serial == null) {
      return _report(
        status: PrivateAlphaDeviceStatus.hold,
        reasons: [serials.isEmpty ? 'no_device' : 'select_one_device'],
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
      );
    }

    final query = await _queryDevice(options.adbExecutable, serial);
    if (query == null) {
      return _report(
        status: PrivateAlphaDeviceStatus.failed,
        reasons: const ['device_query_failed'],
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
      );
    }

    final reasons = <String>[];
    if (!query.isPhysical) reasons.add('physical_device_required');
    if (!query.isArm64) reasons.add('arm64_required');
    if (!query.isSupportedApi) reasons.add('api_24_to_35_required');
    if (reasons.isNotEmpty) {
      return _report(
        status: PrivateAlphaDeviceStatus.hold,
        reasons: reasons,
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
        query: query,
      );
    }

    if (!options.execute) {
      return _report(
        status: PrivateAlphaDeviceStatus.ready,
        reasons: const ['rerun_with_execute'],
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
        query: query,
      );
    }

    final install = await _adb(
      options.adbExecutable,
      serial,
      ['install', '-r', apk.absolute.path],
    );
    if (install.exitCode != 0 || !install.stdoutText.contains('Success')) {
      return _report(
        status: PrivateAlphaDeviceStatus.failed,
        reasons: const ['install_failed'],
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
        query: query,
        executionAttempted: true,
        installSucceeded: false,
      );
    }

    await _adb(
      options.adbExecutable,
      serial,
      const ['shell', 'am', 'force-stop', packageName],
    );
    final launch = await _adb(
      options.adbExecutable,
      serial,
      const ['shell', 'am', 'start', '-W', '-n', launchActivity],
    );
    // Android/OEM builds may report LaunchState=UNKNOWN even when am start
    // successfully launches the requested activity. Process liveness below
    // is the authoritative smoke signal after the force-stop/start sequence.
    final coldStartSucceeded = launch.exitCode == 0 &&
        launch.stdoutText.contains('Status: ok') &&
        (launch.stdoutText.contains('LaunchState: COLD') ||
            launch.stdoutText.contains('Activity: $launchActivity') ||
            launch.stdoutText.contains('ComponentInfo{$launchActivity}'));
    if (!coldStartSucceeded) {
      return _report(
        status: PrivateAlphaDeviceStatus.failed,
        reasons: const ['cold_start_failed'],
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
        query: query,
        executionAttempted: true,
        installSucceeded: true,
        coldStartSucceeded: false,
      );
    }

    final pidResult = await _adb(
      options.adbExecutable,
      serial,
      const ['shell', 'pidof', packageName],
    );
    final pid = pidResult.stdoutText.trim();
    final processAlive = pidResult.exitCode == 0 && pid.isNotEmpty;
    if (!processAlive) {
      return _report(
        status: PrivateAlphaDeviceStatus.failed,
        reasons: const ['process_not_alive'],
        options: options,
        apkFileName: apkFileName,
        apkBytes: apkBytes,
        apkSha256: apkSha256,
        query: query,
        executionAttempted: true,
        installSucceeded: true,
        coldStartSucceeded: true,
        processAlive: false,
      );
    }

    final logcat = await _adb(
      options.adbExecutable,
      serial,
      ['logcat', '--pid=$pid', '-d', '-v', 'brief'],
    );
    final logErrorMatches = logcat.exitCode == 0
        ? _logFailurePattern.allMatches(logcat.stdoutText).length
        : 1;
    return _report(
      status: logErrorMatches == 0
          ? PrivateAlphaDeviceStatus.passed
          : PrivateAlphaDeviceStatus.failed,
      reasons: logErrorMatches == 0 ? const [] : const ['runtime_log_error'],
      options: options,
      apkFileName: apkFileName,
      apkBytes: apkBytes,
      apkSha256: apkSha256,
      query: query,
      executionAttempted: true,
      installSucceeded: true,
      coldStartSucceeded: true,
      processAlive: true,
      logErrorMatches: logErrorMatches,
    );
  }

  Future<_DeviceQuery?> _queryDevice(
    String adbExecutable,
    String serial,
  ) async {
    final values = <String, String>{};
    for (final property in const [
      'ro.kernel.qemu',
      'ro.product.cpu.abi',
      'ro.build.version.sdk',
      'ro.product.manufacturer',
      'ro.product.model',
    ]) {
      final result = await _adb(
        adbExecutable,
        serial,
        ['shell', 'getprop', property],
      );
      if (result.exitCode != 0) return null;
      values[property] = result.stdoutText.trim();
    }
    final size = await _adb(
      adbExecutable,
      serial,
      const ['shell', 'wm', 'size'],
    );
    final density = await _adb(
      adbExecutable,
      serial,
      const ['shell', 'wm', 'density'],
    );
    if (size.exitCode != 0 || density.exitCode != 0) return null;
    final apiLevel = int.tryParse(values['ro.build.version.sdk'] ?? '');
    final abi = values['ro.product.cpu.abi'] ?? '';
    final isPhysical = values['ro.kernel.qemu'] != '1' &&
        !serial.toLowerCase().startsWith('emulator-');
    return _DeviceQuery(
      manufacturer: values['ro.product.manufacturer'],
      model: values['ro.product.model'],
      abi: abi,
      apiLevel: apiLevel,
      viewport: _lastValue(size.stdoutText),
      density: _lastValue(density.stdoutText),
      isPhysical: isPhysical,
      isArm64: abi.toLowerCase().contains('arm64') ||
          abi.toLowerCase().contains('aarch64'),
      isSupportedApi: apiLevel != null && apiLevel >= 24 && apiLevel <= 35,
    );
  }

  Future<DeviceCommandResult> _adb(
    String adbExecutable,
    String serial,
    List<String> arguments,
  ) {
    return _runner.run(adbExecutable, ['-s', serial, ...arguments]);
  }

  PrivateAlphaDeviceReport _report({
    required PrivateAlphaDeviceStatus status,
    required List<String> reasons,
    required PrivateAlphaDevicePreflightOptions options,
    required String apkFileName,
    int? apkBytes,
    String? apkSha256,
    _DeviceQuery? query,
    bool executionAttempted = false,
    bool? installSucceeded,
    bool? coldStartSucceeded,
    bool? processAlive,
    int logErrorMatches = 0,
  }) {
    return PrivateAlphaDeviceReport(
      status: status,
      reasons: List.unmodifiable(reasons),
      apkFileName: apkFileName,
      apkBytes: apkBytes,
      apkSha256: apkSha256,
      deviceKind: query == null
          ? 'unavailable'
          : query.isPhysical
              ? 'physical'
              : 'emulator',
      manufacturer: query?.manufacturer,
      model: query?.model,
      abi: query?.abi,
      apiLevel: query?.apiLevel,
      viewport: query?.viewport,
      density: query?.density,
      executionRequested: options.execute,
      executionAttempted: executionAttempted,
      installSucceeded: installSucceeded,
      coldStartSucceeded: coldStartSucceeded,
      processAlive: processAlive,
      logErrorMatches: logErrorMatches,
    );
  }
}

class _DeviceQuery {
  final String? manufacturer;
  final String? model;
  final String abi;
  final int? apiLevel;
  final String? viewport;
  final String? density;
  final bool isPhysical;
  final bool isArm64;
  final bool isSupportedApi;

  const _DeviceQuery({
    required this.manufacturer,
    required this.model,
    required this.abi,
    required this.apiLevel,
    required this.viewport,
    required this.density,
    required this.isPhysical,
    required this.isArm64,
    required this.isSupportedApi,
  });
}

List<String> _connectedDeviceSerials(String output) {
  final serials = <String>[];
  for (final line in const LineSplitter().convert(output)) {
    final match = RegExp(r'^(\S+)\s+device(?:\s|$)').firstMatch(line.trim());
    if (match != null) serials.add(match.group(1)!);
  }
  return serials;
}

String? _selectSerial(List<String> serials, String? requested) {
  final trimmed = requested?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return serials.contains(trimmed) ? trimmed : null;
  }
  return serials.length == 1 ? serials.single : null;
}

String? _lastValue(String output) {
  final lines = const LineSplitter()
      .convert(output)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (lines.isEmpty) return null;
  final value = lines.last.split(':').last.trim();
  return value.isEmpty ? null : value;
}

final RegExp _logFailurePattern = RegExp(
  r'FATAL EXCEPTION|AndroidRuntime:\s*FATAL|E/flutter|\bANR\b|SQLiteException|database is locked|uncaught restore',
  caseSensitive: false,
);
