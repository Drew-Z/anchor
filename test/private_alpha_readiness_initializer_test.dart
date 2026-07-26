import 'dart:convert';
import 'dart:io';

import 'package:dlg_q/services/release/private_alpha_readiness.dart';
import 'package:dlg_q/services/release/private_alpha_readiness_evaluator.dart';
import 'package:dlg_q/services/release/private_alpha_readiness_initializer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dart_cli_test_support.dart';

void main() {
  test('builds a real-APK draft that evaluates to the five external blockers',
      () async {
    final root = await Directory.systemTemp.createTemp('duoduo-init-');
    addTearDown(() => root.delete(recursive: true));
    final apk = File('${root.path}${Platform.pathSeparator}build'
        '${Platform.pathSeparator}app.apk');
    await apk.parent.create(recursive: true);
    await apk.writeAsBytes([1, 2, 3, 4]);
    final completedAt = DateTime.utc(2026, 7, 17, 12);
    final evidence = await const PrivateAlphaReadinessInitializer().build(
      repositoryRoot: root.path,
      apkPath: 'build/app.apk',
      outputPath: 'build/validation/readiness.json',
      completedAt: completedAt,
      testsPassed: 303,
      analyzerErrors: 0,
      analyzerWarnings: 0,
      formatPassed: true,
      diffCheckPassed: true,
      arm64Only: true,
      v2Signed: true,
    );
    final output = File('${root.path}${Platform.pathSeparator}build'
        '${Platform.pathSeparator}validation${Platform.pathSeparator}'
        'readiness.json');
    await output.parent.create(recursive: true);
    await output.writeAsString(jsonEncode(evidence));

    final report = await const PrivateAlphaReadinessEvaluator().evaluate(
      json: evidence,
      repositoryRoot: root.path,
      evaluatedAt: completedAt,
    );

    expect(report.status, PrivateAlphaReadinessStatus.hold);
    expect(report.blockers, [
      'physical_device_pending',
      'controlled_credential_required',
      'data_processing_owner_required',
      'release_day_acceptance_pending',
      'cohort_pending',
    ]);
    expect(evidence['physical_device_evidence'], isNull);
    expect(jsonEncode(evidence), isNot(contains('credential_reference')));
  });

  test('rejects paths outside the repository or ignored build output',
      () async {
    final root = await Directory.systemTemp.createTemp('duoduo-init-path-');
    addTearDown(() => root.delete(recursive: true));
    final apk = File('${root.path}${Platform.pathSeparator}app.apk');
    await apk.writeAsBytes([1]);
    const initializer = PrivateAlphaReadinessInitializer();

    Future<Map<String, dynamic>> build(String output) => initializer.build(
          repositoryRoot: root.path,
          apkPath: 'app.apk',
          outputPath: output,
          completedAt: DateTime.utc(2026),
          testsPassed: 1,
          analyzerErrors: 0,
          analyzerWarnings: 0,
          formatPassed: false,
          diffCheckPassed: false,
          arm64Only: false,
          v2Signed: false,
        );

    expect(() => build('readiness.json'), throwsA(isA<FormatException>()));
    expect(() => build('../readiness.json'), throwsA(isA<FormatException>()));
  });

  test(
    'initializer CLI writes a safe draft consumed by readiness CLI',
    () async {
      final dart = await findDartCliExecutable();
      final root = await Directory.systemTemp.createTemp('duoduo-init-cli-');
      addTearDown(() => root.delete(recursive: true));
      final apk = File('${root.path}${Platform.pathSeparator}build'
          '${Platform.pathSeparator}app.apk');
      await apk.parent.create(recursive: true);
      await apk.writeAsBytes([1, 2, 3]);
      const output = 'build/validation/private-alpha-readiness.json';

      final initialized = await Process.run(
        dart,
        [
          'run',
          'tool/private_alpha_readiness_init.dart',
          '--repository-root',
          root.path,
          '--apk',
          'build/app.apk',
          '--tests-passed',
          '303',
          '--format-passed',
          '--diff-check-passed',
          '--arm64-only',
          '--v2-signed',
          '--output',
          output,
        ],
        workingDirectory: Directory.current.path,
      );
      expect(initialized.exitCode, 0, reason: initialized.stderr.toString());
      expect(initialized.stdout.toString().trim(), output);

      final readiness = await Process.run(
        dart,
        [
          'run',
          'tool/private_alpha_readiness.dart',
          '--repository-root',
          root.path,
          '--evidence',
          '${root.path}${Platform.pathSeparator}'
              '${output.replaceAll('/', Platform.pathSeparator)}',
          '--format',
          'json',
        ],
        workingDirectory: Directory.current.path,
      );
      expect(readiness.exitCode, 2, reason: readiness.stderr.toString());
      final report = jsonDecode(readiness.stdout.toString());
      expect(report['status'], 'HOLD');
      expect((report['blockers'] as List), hasLength(5));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('committed schema is Draft 2020-12 with all conditional gates',
      () async {
    final decoded = jsonDecode(
      await File('schema/private-alpha-readiness-v2.schema.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    expect(
      decoded[r'$schema'],
      'https://json-schema.org/draft/2020-12/schema',
    );
    expect(decoded['additionalProperties'], false);
    final conditions = decoded['allOf'] as List;
    expect(conditions, hasLength(5));
    expect(
      jsonEncode(conditions),
      allOf(
        contains('physical_device_evidence'),
        contains('controlled_credential'),
        contains('operator_pack'),
        contains('release_day_acceptance'),
        contains('cohort_evidence'),
      ),
    );
  });
}
