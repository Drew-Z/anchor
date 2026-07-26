import 'package:dlg_q/services/release/private_alpha_readiness.dart';
import 'package:dlg_q/services/release/private_alpha_readiness_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/private_alpha_readiness_test_fixture.dart';

void main() {
  final evaluatedAt = DateTime.utc(2026, 7, 17, 12);

  test('evaluates one complete anonymous evidence bundle as GO', () async {
    final fixture = await createPrivateAlphaReadinessFixture(evaluatedAt);
    addTearDown(() => fixture.root.delete(recursive: true));

    final report = await const PrivateAlphaReadinessEvaluator().evaluate(
      json: fixture.evidence,
      repositoryRoot: fixture.root.path,
      evaluatedAt: evaluatedAt,
    );

    expect(report.status, PrivateAlphaReadinessStatus.go);
    expect(report.blockers, isEmpty);
  });

  test('keeps a complete NO-GO study bundle on HOLD', () async {
    final fixture = await createPrivateAlphaReadinessFixture(
      evaluatedAt,
      decision: 'noGo',
    );
    addTearDown(() => fixture.root.delete(recursive: true));

    final report = await const PrivateAlphaReadinessEvaluator().evaluate(
      json: fixture.evidence,
      repositoryRoot: fixture.root.path,
      evaluatedAt: evaluatedAt,
    );

    expect(report.status, PrivateAlphaReadinessStatus.hold);
    expect(
      report.blockers,
      ['release_consistency_cohort_decision_not_go'],
    );
  });
}
