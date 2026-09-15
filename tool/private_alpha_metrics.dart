import 'dart:convert';
import 'dart:io';

import 'package:anchor_learning/services/privacy/private_alpha_metrics.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final exports = <Map<String, Object?>>[];
    for (var index = 0; index < options.paths.length; index++) {
      // Participant exports live under a participant-code directory outside
      // the repository, so failures are reported by input position only.
      final reference = 'event export ${index + 1}';
      final Object? decoded;
      try {
        decoded = jsonDecode(await File(options.paths[index]).readAsString());
      } on FileSystemException {
        throw FormatException('Cannot read $reference.');
      } on FormatException {
        throw FormatException('$reference is not valid JSON.');
      }
      if (decoded is! Map) {
        throw FormatException('$reference does not contain a JSON object.');
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
  } on FormatException catch (error) {
    _fail(error.message);
  } on FileSystemException catch (error) {
    // `message` omits the `path` field that `toString()` would include.
    _fail(error.message);
  } on Object catch (error) {
    // Never interpolate an unexpected error: it may carry an export path.
    _fail('Unexpected ${error.runtimeType} while aggregating event exports.');
  }
}

void _fail(String message) {
  stderr.writeln('Private Alpha metrics failed: $message');
  stderr.writeln(_usage);
  exitCode = 64;
}

const _usage = 'Usage: dart run tool/private_alpha_metrics.dart --invited 10 '
    '[--format markdown|json] <event-export.json>...';

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
