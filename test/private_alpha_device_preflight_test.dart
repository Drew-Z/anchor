import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:anchor_learning/services/release/private_alpha_device_preflight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;
  late File apk;
  late String apkHash;

  setUp(() async {
    tempDirectory =
        await Directory.systemTemp.createTemp('anchor-learning-preflight-');
    apk = File('${tempDirectory.path}${Platform.pathSeparator}app-debug.apk');
    await apk.writeAsBytes(const [1, 2, 3, 4]);
    apkHash = sha256.convert(const [1, 2, 3, 4]).toString();
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test('passes an executed Arm64 physical-device smoke', () async {
    final runner = _FakeCommandRunner(_physicalResponses(apk.absolute.path));
    final report = await PrivateAlphaDevicePreflight(runner: runner).run(
      PrivateAlphaDevicePreflightOptions(
        apkPath: apk.path,
        expectedSha256: apkHash,
        execute: true,
      ),
    );

    expect(report.status, PrivateAlphaDeviceStatus.passed);
    expect(report.deviceKind, 'physical');
    expect(report.abi, 'arm64-v8a');
    expect(report.apiLevel, 35);
    expect(report.executionAttempted, isTrue);
    expect(report.installSucceeded, isTrue);
    expect(report.coldStartSucceeded, isTrue);
    expect(report.processAlive, isTrue);
    expect(report.logErrorMatches, 0);
  });

  test('keeps an x86 emulator on hold without installing', () async {
    final responses = _deviceQueryResponses(
      serial: 'emulator-5554',
      qemu: '1',
      abi: 'x86_64',
      api: '36',
      manufacturer: 'Google',
      model: 'sdk_gphone64_x86_64',
    );
    final runner = _FakeCommandRunner(responses);
    final report = await PrivateAlphaDevicePreflight(runner: runner).run(
      PrivateAlphaDevicePreflightOptions(
        apkPath: apk.path,
        expectedSha256: apkHash,
      ),
    );

    expect(report.status, PrivateAlphaDeviceStatus.hold);
    expect(
      report.reasons,
      containsAll([
        'physical_device_required',
        'arm64_required',
        'api_24_to_35_required',
      ]),
    );
    expect(report.executionAttempted, isFalse);
    expect(
        runner.invocations.any((value) => value.contains('install')), isFalse);
  });

  test('reports a stable failure when installation fails', () async {
    final responses = _physicalResponses(apk.absolute.path);
    responses[_commandKey('adb', [
      '-s',
      'physical-01',
      'install',
      '-r',
      apk.absolute.path,
    ])] = const DeviceCommandResult(
      exitCode: 1,
      stderrText: 'INSTALL_FAILED',
    );
    final report = await PrivateAlphaDevicePreflight(
      runner: _FakeCommandRunner(responses),
    ).run(
      PrivateAlphaDevicePreflightOptions(
        apkPath: apk.path,
        expectedSha256: apkHash,
        execute: true,
      ),
    );

    expect(report.status, PrivateAlphaDeviceStatus.failed);
    expect(report.reasons, ['install_failed']);
    expect(report.executionAttempted, isTrue);
    expect(report.installSucceeded, isFalse);
  });

  test('accepts Android OEM UNKNOWN launch state when activity starts',
      () async {
    final responses = _physicalResponses(apk.absolute.path);
    responses[_commandKey('adb', const [
      '-s',
      'physical-01',
      'shell',
      'am',
      'start',
      '-W',
      '-n',
      PrivateAlphaDevicePreflight.launchActivity,
    ])] = const DeviceCommandResult(
      exitCode: 0,
      stdoutText: 'Status: ok\nLaunchState: UNKNOWN (0)\n'
          'Activity: cc.eu.playlab.anchor/.MainActivity\n',
    );

    final report = await PrivateAlphaDevicePreflight(
      runner: _FakeCommandRunner(responses),
    ).run(
      PrivateAlphaDevicePreflightOptions(
        apkPath: apk.path,
        expectedSha256: apkHash,
        execute: true,
      ),
    );

    expect(report.status, PrivateAlphaDeviceStatus.passed);
    expect(report.coldStartSucceeded, isTrue);
    expect(report.processAlive, isTrue);
  });
}

Map<String, DeviceCommandResult> _physicalResponses(String apkPath) {
  return {
    ..._deviceQueryResponses(
      serial: 'physical-01',
      qemu: '0',
      abi: 'arm64-v8a',
      api: '35',
      manufacturer: 'Example',
      model: 'Phone',
    ),
    _commandKey('adb', [
      '-s',
      'physical-01',
      'install',
      '-r',
      apkPath,
    ]): const DeviceCommandResult(exitCode: 0, stdoutText: 'Success\n'),
    _commandKey('adb', const [
      '-s',
      'physical-01',
      'shell',
      'am',
      'force-stop',
      PrivateAlphaDevicePreflight.packageName,
    ]): const DeviceCommandResult(exitCode: 0),
    _commandKey('adb', const [
      '-s',
      'physical-01',
      'shell',
      'am',
      'start',
      '-W',
      '-n',
      PrivateAlphaDevicePreflight.launchActivity,
    ]): const DeviceCommandResult(
      exitCode: 0,
      stdoutText: 'Status: ok\nLaunchState: COLD\nTotalTime: 1200\n',
    ),
    _commandKey('adb', const [
      '-s',
      'physical-01',
      'shell',
      'pidof',
      PrivateAlphaDevicePreflight.packageName,
    ]): const DeviceCommandResult(exitCode: 0, stdoutText: '4321\n'),
    _commandKey('adb', const [
      '-s',
      'physical-01',
      'logcat',
      '--pid=4321',
      '-d',
      '-v',
      'brief',
    ]): const DeviceCommandResult(
      exitCode: 0,
      stdoutText: 'I/flutter: App started\n',
    ),
  };
}

Map<String, DeviceCommandResult> _deviceQueryResponses({
  required String serial,
  required String qemu,
  required String abi,
  required String api,
  required String manufacturer,
  required String model,
}) {
  return {
    _commandKey('adb', const ['devices', '-l']): DeviceCommandResult(
      exitCode: 0,
      stdoutText: 'List of devices attached\n$serial device product:test\n',
    ),
    _propertyKey(serial, 'ro.kernel.qemu'):
        DeviceCommandResult(exitCode: 0, stdoutText: '$qemu\n'),
    _propertyKey(serial, 'ro.product.cpu.abi'):
        DeviceCommandResult(exitCode: 0, stdoutText: '$abi\n'),
    _propertyKey(serial, 'ro.build.version.sdk'):
        DeviceCommandResult(exitCode: 0, stdoutText: '$api\n'),
    _propertyKey(serial, 'ro.product.manufacturer'):
        DeviceCommandResult(exitCode: 0, stdoutText: '$manufacturer\n'),
    _propertyKey(serial, 'ro.product.model'):
        DeviceCommandResult(exitCode: 0, stdoutText: '$model\n'),
    _commandKey('adb', [
      '-s',
      serial,
      'shell',
      'wm',
      'size',
    ]): const DeviceCommandResult(
      exitCode: 0,
      stdoutText: 'Physical size: 1080x2400\n',
    ),
    _commandKey('adb', [
      '-s',
      serial,
      'shell',
      'wm',
      'density',
    ]): const DeviceCommandResult(
      exitCode: 0,
      stdoutText: 'Physical density: 420\n',
    ),
  };
}

String _propertyKey(String serial, String property) {
  return _commandKey('adb', [
    '-s',
    serial,
    'shell',
    'getprop',
    property,
  ]);
}

String _commandKey(String executable, List<String> arguments) {
  return '$executable\u0000${arguments.join('\u0000')}';
}

class _FakeCommandRunner implements DeviceCommandRunner {
  final Map<String, DeviceCommandResult> responses;
  final List<String> invocations = [];

  _FakeCommandRunner(this.responses);

  @override
  Future<DeviceCommandResult> run(
    String executable,
    List<String> arguments,
  ) async {
    final key = _commandKey(executable, arguments);
    invocations.add(key);
    final response = responses[key];
    if (response == null) {
      throw StateError(
          'Unexpected command: $executable ${arguments.join(' ')}');
    }
    return response;
  }
}
