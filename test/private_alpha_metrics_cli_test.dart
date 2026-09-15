import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/dart_cli_test_support.dart';

void main() {
  test(
    'CLI reports export failures without printing participant paths',
    () async {
      final dart = await findDartCliExecutable();
      final exportRoot = await Directory.systemTemp.createTemp(
        'anchor-learning-participant-A07-',
      );
      addTearDown(() => exportRoot.delete(recursive: true));

      final missingPath = p.join(exportRoot.path, 'A07-events.json');
      final missing = await _runCli(dart, paths: [missingPath]);
      expect(missing.exitCode, 64);
      final missingStderr = missing.stderr as String;
      expect(missingStderr, contains('Private Alpha metrics failed:'));
      expect(missingStderr, contains('event export 1'));
      expect(missingStderr, isNot(contains(exportRoot.path)));
      expect(missingStderr, isNot(contains('A07')));

      final malformed = File(p.join(exportRoot.path, 'A07-malformed.json'));
      await malformed.writeAsString('{"answer": "participant secret answer"');
      final invalidJson = await _runCli(dart, paths: [malformed.path]);
      expect(invalidJson.exitCode, 64);
      final invalidJsonStderr = invalidJson.stderr as String;
      expect(invalidJsonStderr, contains('event export 1'));
      expect(invalidJsonStderr, isNot(contains(exportRoot.path)));
      expect(invalidJsonStderr, isNot(contains('A07')));
      expect(invalidJsonStderr, isNot(contains('participant secret answer')));

      final notAnObject = File(p.join(exportRoot.path, 'A07-array.json'));
      await notAnObject.writeAsString('[]');
      final wrongShape = await _runCli(
        dart,
        paths: [notAnObject.path],
      );
      expect(wrongShape.exitCode, 64);
      final wrongShapeStderr = wrongShape.stderr as String;
      expect(
        wrongShapeStderr,
        contains('event export 1 does not contain a JSON object.'),
      );
      expect(wrongShapeStderr, isNot(contains(exportRoot.path)));
      expect(wrongShapeStderr, isNot(contains('A07')));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'CLI identifies the failing export by position, not by name',
    () async {
      final dart = await findDartCliExecutable();
      final exportRoot = await Directory.systemTemp.createTemp(
        'anchor-learning-participant-A09-',
      );
      addTearDown(() => exportRoot.delete(recursive: true));
      final valid = File(p.join(exportRoot.path, 'A09-first.json'));
      await valid.writeAsString('{"events": []}');
      final invalid = File(p.join(exportRoot.path, 'A09-second.json'));
      await invalid.writeAsString('[]');

      final result = await _runCli(dart, paths: [valid.path, invalid.path]);

      expect(result.exitCode, 64);
      final stderr = result.stderr as String;
      expect(
        stderr,
        contains('event export 2 does not contain a JSON object.'),
      );
      expect(stderr, isNot(contains(exportRoot.path)));
      expect(stderr, isNot(contains('A09')));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<ProcessResult> _runCli(
  String dart, {
  required List<String> paths,
}) {
  return Process.run(
    dart,
    [
      'run',
      'tool/private_alpha_metrics.dart',
      '--invited',
      '10',
      ...paths,
    ],
    workingDirectory: Directory.current.path,
  );
}
