import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/dart_cli_test_support.dart';
import 'support/private_alpha_readiness_test_fixture.dart';

void main() {
  test(
    'CLI preserves GO and HOLD process contracts without evidence leakage',
    () async {
      final dart = await findDartCliExecutable();
      final evaluatedAt = DateTime.now().toUtc();
      final fixture = await createPrivateAlphaReadinessFixture(evaluatedAt);
      addTearDown(() => fixture.root.delete(recursive: true));
      final evidence = await fixture.writeEvidence();

      final go = await _runCli(
        dart,
        evidencePath: evidence.path,
        repositoryRoot: fixture.root.path,
        format: 'json',
      );
      expect(go.exitCode, 0, reason: go.stderr.toString());
      expect(jsonDecode(go.stdout.toString()), {
        'status': 'GO',
        'blockers': <dynamic>[],
      });
      _expectNoEvidenceEcho(go);

      final cohort = fixture.evidence['cohort_evidence'];
      (cohort as Map<String, dynamic>)['decision'] = 'noGo';
      await fixture.writeEvidence();
      final hold = await _runCli(
        dart,
        evidencePath: evidence.path,
        repositoryRoot: fixture.root.path,
        format: 'markdown',
      );
      expect(hold.exitCode, 2, reason: hold.stderr.toString());
      expect(hold.stdout, contains('Status: `HOLD`'));
      expect(
        hold.stdout,
        contains('release_consistency_cohort_decision_not_go'),
      );
      _expectNoEvidenceEcho(hold);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'CLI maps input and file failures to stable process exit codes',
    () async {
      final dart = await findDartCliExecutable();
      final invalidFormat = await Process.run(
        dart,
        [
          'run',
          'tool/private_alpha_readiness.dart',
          '--evidence',
          'unused.json',
          '--format',
          'xml',
        ],
        workingDirectory: Directory.current.path,
      );
      expect(invalidFormat.exitCode, 64);
      expect(
        invalidFormat.stderr,
        contains('Private Alpha readiness failed:'),
      );

      final missingFile = await Process.run(
        dart,
        [
          'run',
          'tool/private_alpha_readiness.dart',
          '--evidence',
          'definitely-missing-readiness.json',
        ],
        workingDirectory: Directory.current.path,
      );
      expect(missingFile.exitCode, 66);
      expect(
        missingFile.stderr,
        contains('Private Alpha readiness failed:'),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<ProcessResult> _runCli(
  String dart, {
  required String evidencePath,
  required String repositoryRoot,
  required String format,
}) {
  return Process.run(
    dart,
    [
      'run',
      'tool/private_alpha_readiness.dart',
      '--evidence',
      evidencePath,
      '--format',
      format,
      '--repository-root',
      repositoryRoot,
    ],
    workingDirectory: Directory.current.path,
  );
}

void _expectNoEvidenceEcho(ProcessResult result) {
  final output = '${result.stdout}\n${result.stderr}';
  for (final sentinel in [
    'https://relay.example/v1',
    'grok-4.5',
    'CRED-PRIMARY-001',
    'OPS-ALPHA-001',
    'A01',
  ]) {
    expect(output, isNot(contains(sentinel)));
  }
}
