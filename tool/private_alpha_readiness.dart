import 'dart:convert';
import 'dart:io';

import 'package:anchor_learning/services/release/private_alpha_readiness.dart';
import 'package:anchor_learning/services/release/private_alpha_readiness_evaluator.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _CliOptions.parse(arguments);
    final decoded = jsonDecode(await File(options.evidencePath).readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Evidence must be a JSON object.');
    }
    final report = await const PrivateAlphaReadinessEvaluator().evaluate(
      json: decoded,
      repositoryRoot: options.repositoryRoot,
      evaluatedAt: DateTime.now().toUtc(),
    );
    stdout.writeln(
      options.format == 'json'
          ? const JsonEncoder.withIndent('  ').convert(report.toJson())
          : report.toMarkdown(),
    );
    exitCode = report.status == PrivateAlphaReadinessStatus.go ? 0 : 2;
  } on FormatException catch (error) {
    stderr.writeln('Private Alpha readiness failed: ${error.message}');
    stderr.writeln(_usage);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Private Alpha readiness failed: ${error.message}');
    exitCode = 66;
  }
}

class _CliOptions {
  final String evidencePath;
  final String format;
  final String repositoryRoot;

  const _CliOptions({
    required this.evidencePath,
    required this.format,
    required this.repositoryRoot,
  });

  factory _CliOptions.parse(List<String> arguments) {
    String? evidencePath;
    var format = 'markdown';
    var repositoryRoot = Directory.current.path;

    String readValue(String option, int index) {
      if (index >= arguments.length) {
        throw FormatException('$option requires a value.');
      }
      return arguments[index];
    }

    for (var index = 0; index < arguments.length; index++) {
      switch (arguments[index]) {
        case '--evidence':
          evidencePath = readValue('--evidence', ++index);
        case '--format':
          format = readValue('--format', ++index);
        case '--repository-root':
          repositoryRoot = readValue('--repository-root', ++index);
        default:
          throw FormatException('Unknown option: ${arguments[index]}');
      }
    }
    if (evidencePath == null || evidencePath.trim().isEmpty) {
      throw const FormatException('--evidence is required.');
    }
    if (format != 'markdown' && format != 'json') {
      throw const FormatException('--format must be markdown or json.');
    }
    return _CliOptions(
      evidencePath: evidencePath,
      format: format,
      repositoryRoot: repositoryRoot,
    );
  }
}

const _usage = 'Usage: dart run tool/private_alpha_readiness.dart '
    '--evidence <evidence.json> [--format markdown|json] '
    '[--repository-root <path>]';
