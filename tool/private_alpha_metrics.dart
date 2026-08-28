import 'dart:convert';
import 'dart:io';

import 'package:anchor_learning/services/privacy/private_alpha_metrics.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final exports = <Map<String, Object?>>[];
    for (final path in options.paths) {
      final decoded = jsonDecode(await File(path).readAsString());
      if (decoded is! Map) {
        throw FormatException('$path does not contain a JSON object.');
      }
      exports.add(Map<String, Object?>.from(decoded));
    }
    final report = const PrivateAlphaMetricsAggregator().aggregate(
      exports,
      invitedUsers: options.invitedUsers,
    );
    if (options.format == 'json') {
      stdout
          .writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
    } else {
      stdout.writeln(report.toMarkdown());
    }
  } on Object catch (error) {
    stderr.writeln('Private Alpha metrics failed: $error');
    stderr.writeln(
      'Usage: dart run tool/private_alpha_metrics.dart --invited 10 '
      '[--format markdown|json] <event-export.json>...',
    );
    exitCode = 64;
  }
}

class _Options {
  final int invitedUsers;
  final String format;
  final List<String> paths;

  const _Options({
    required this.invitedUsers,
    required this.format,
    required this.paths,
  });

  factory _Options.parse(List<String> arguments) {
    int? invitedUsers;
    var format = 'markdown';
    final paths = <String>[];
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--invited') {
        if (++index >= arguments.length) {
          throw const FormatException('--invited requires a value.');
        }
        invitedUsers = int.tryParse(arguments[index]);
        continue;
      }
      if (argument == '--format') {
        if (++index >= arguments.length) {
          throw const FormatException('--format requires a value.');
        }
        format = arguments[index];
        continue;
      }
      if (argument.startsWith('--')) {
        throw FormatException('Unknown option: $argument');
      }
      paths.add(argument);
    }
    if (invitedUsers == null || invitedUsers < 0) {
      throw const FormatException('--invited must be a non-negative integer.');
    }
    if (format != 'markdown' && format != 'json') {
      throw const FormatException('--format must be markdown or json.');
    }
    if (paths.isEmpty) {
      throw const FormatException('At least one event export is required.');
    }
    return _Options(
      invitedUsers: invitedUsers,
      format: format,
      paths: paths,
    );
  }
}
