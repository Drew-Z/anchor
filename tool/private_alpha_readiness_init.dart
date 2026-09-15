import 'dart:convert';
import 'dart:io';

import 'package:anchor_learning/services/release/private_alpha_readiness_initializer.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final evidence = await const PrivateAlphaReadinessInitializer().build(
      repositoryRoot: options.repositoryRoot,
      apkPath: options.apkPath,
      outputPath: options.outputPath,
      completedAt: DateTime.now().toUtc(),
      testsPassed: options.testsPassed,
      analyzerErrors: options.analyzerErrors,
      analyzerWarnings: options.analyzerWarnings,
      formatPassed: options.formatPassed,
      diffCheckPassed: options.diffCheckPassed,
      arm64Only: options.arm64Only,
      v2Signed: options.v2Signed,
    );
    final output = File(
      '${options.repositoryRoot}${Platform.pathSeparator}${options.outputPath}',
    );
    await output.parent.create(recursive: true);
    await output.writeAsString(
      const JsonEncoder.withIndent('  ').convert(evidence),
    );
    stdout.writeln(options.outputPath);
  } on FormatException catch (error) {
    stderr.writeln('Private Alpha initializer failed: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Private Alpha initializer failed: ${error.message}');
    exitCode = 66;
  }
}

class _Options {
  final String repositoryRoot;
  final String apkPath;
  final String outputPath;
  final int testsPassed;
  final int analyzerErrors;
  final int analyzerWarnings;
  final bool formatPassed;
  final bool diffCheckPassed;
  final bool arm64Only;
  final bool v2Signed;

  const _Options({
    required this.repositoryRoot,
    required this.apkPath,
    required this.outputPath,
    required this.testsPassed,
    required this.analyzerErrors,
    required this.analyzerWarnings,
    required this.formatPassed,
    required this.diffCheckPassed,
    required this.arm64Only,
    required this.v2Signed,
  });

  factory _Options.parse(List<String> arguments) {
    var repositoryRoot = Directory.current.path;
    var outputPath = 'build/validation/private-alpha-readiness.json';
    String? apkPath;
    int? testsPassed;
    var analyzerErrors = 0;
    var analyzerWarnings = 0;
    var formatPassed = false;
    var diffCheckPassed = false;
    var arm64Only = false;
    var v2Signed = false;

    String readValue(String option, int index) {
      if (index >= arguments.length) {
        throw FormatException('$option requires a value.');
      }
      return arguments[index];
    }

    int readInt(String option, int index) {
      final value = int.tryParse(readValue(option, index));
      if (value == null) throw FormatException('$option must be an integer.');
      return value;
    }

    for (var index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--repository-root':
          repositoryRoot = readValue('--repository-root', ++index);
        case '--apk':
          apkPath = readValue('--apk', ++index);
        case '--output':
          outputPath = readValue('--output', ++index);
        case '--tests-passed':
          testsPassed = readInt('--tests-passed', ++index);
        case '--analyzer-errors':
          analyzerErrors = readInt('--analyzer-errors', ++index);
        case '--analyzer-warnings':
          analyzerWarnings = readInt('--analyzer-warnings', ++index);
        case '--format-passed':
          formatPassed = true;
        case '--diff-check-passed':
          diffCheckPassed = true;
        case '--arm64-only':
          arm64Only = true;
        case '--v2-signed':
          v2Signed = true;
        default:
          throw FormatException('Unknown option: ${arguments[index]}');
      }
    }
    if (apkPath == null || testsPassed == null) {
      throw const FormatException('--apk and --tests-passed are required.');
    }
    return _Options(
      repositoryRoot: repositoryRoot,
      apkPath: apkPath,
      outputPath: outputPath,
      testsPassed: testsPassed,
      analyzerErrors: analyzerErrors,
      analyzerWarnings: analyzerWarnings,
      formatPassed: formatPassed,
      diffCheckPassed: diffCheckPassed,
      arm64Only: arm64Only,
      v2Signed: v2Signed,
    );
  }
}

const _usage = 'Usage: dart run tool/private_alpha_readiness_init.dart '
    '--apk <repository-relative.apk> --tests-passed <count> '
    '[--analyzer-errors <count>] [--analyzer-warnings <count>] '
    '[--format-passed] [--diff-check-passed] [--arm64-only] [--v2-signed] '
    '[--output build/validation/private-alpha-readiness.json] '
    '[--repository-root <path>]';
