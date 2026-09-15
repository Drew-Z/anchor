import 'dart:convert';
import 'dart:io';

import 'package:anchor_learning/services/release/private_alpha_device_preflight.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _CliOptions.parse(arguments);
    final report = await const PrivateAlphaDevicePreflight().run(
      PrivateAlphaDevicePreflightOptions(
        apkPath: options.apkPath,
        adbExecutable: options.adbExecutable,
        serial: options.serial,
        expectedSha256: options.expectedSha256,
        execute: options.execute,
      ),
    );
    if (options.format == 'json') {
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(report.toJson()),
      );
    } else {
      stdout.writeln(report.toMarkdown());
    }
    exitCode = switch (report.status) {
      PrivateAlphaDeviceStatus.ready || PrivateAlphaDeviceStatus.passed => 0,
      PrivateAlphaDeviceStatus.hold => 2,
      PrivateAlphaDeviceStatus.failed => 1,
    };
  } on FormatException catch (error) {
    stderr.writeln('Private Alpha device preflight failed: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  }
}

class _CliOptions {
  final String apkPath;
  final String adbExecutable;
  final String? serial;
  final String? expectedSha256;
  final bool execute;
  final String format;

  const _CliOptions({
    required this.apkPath,
    required this.adbExecutable,
    required this.serial,
    required this.expectedSha256,
    required this.execute,
    required this.format,
  });

  factory _CliOptions.parse(List<String> arguments) {
    var apkPath = 'build/app/outputs/flutter-apk/app-debug.apk';
    var adbExecutable = 'adb';
    String? serial;
    String? expectedSha256;
    var execute = false;
    var format = 'markdown';

    String readValue(String option, int index) {
      if (index >= arguments.length) {
        throw FormatException('$option requires a value.');
      }
      return arguments[index];
    }

    for (var index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--apk':
          apkPath = readValue('--apk', ++index);
        case '--adb':
          adbExecutable = readValue('--adb', ++index);
        case '--serial':
          serial = readValue('--serial', ++index);
        case '--expected-sha256':
          expectedSha256 = readValue('--expected-sha256', ++index);
        case '--format':
          format = readValue('--format', ++index);
        case '--execute':
          execute = true;
        default:
          throw FormatException('Unknown option: ${arguments[index]}');
      }
    }
    if (format != 'markdown' && format != 'json') {
      throw const FormatException('--format must be markdown or json.');
    }
    final normalizedHash = expectedSha256?.trim();
    if (normalizedHash != null &&
        normalizedHash.isNotEmpty &&
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(normalizedHash)) {
      throw const FormatException(
          '--expected-sha256 must contain 64 hex characters.');
    }
    return _CliOptions(
      apkPath: apkPath,
      adbExecutable: adbExecutable,
      serial: serial,
      expectedSha256: normalizedHash,
      execute: execute,
      format: format,
    );
  }
}

const String _usage =
    'Usage: dart run tool/private_alpha_device_preflight.dart '
    '[--apk <path>] [--adb <path>] [--serial <adb-serial>] '
    '[--expected-sha256 <hash>] [--format markdown|json] [--execute]';
