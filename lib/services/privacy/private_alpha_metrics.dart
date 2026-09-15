enum PrivateAlphaTargetStatus {
  met('met'),
  missed('missed'),
  insufficientData('insufficient_data');

  final String value;

  const PrivateAlphaTargetStatus(this.value);
}

class PrivateAlphaMetricsReport {
  final int invitedUsers;
  final int observedUsers;
  final int importStartedUsers;
  final int coverageReviewUsers;
  final int activatedUsers;
  final double? medianActivationMinutes;
  final int activationOverThirtyMinutesUsers;
  final int groundedClosureUsers;
  final int secondClosureWithinSevenDaysUsers;
  final int weekTwoReturningUsers;
  final int formalGroundedTurns;
  final int evidenceCompliantTurns;
  final int feedbackCount;
  final Map<String, int> feedbackByCategory;
  final Map<String, int> feedbackBySeverity;
  final Duration observationSpan;

  const PrivateAlphaMetricsReport({
    required this.invitedUsers,
    required this.observedUsers,
    required this.importStartedUsers,
    required this.coverageReviewUsers,
    required this.activatedUsers,
    required this.medianActivationMinutes,
    required this.activationOverThirtyMinutesUsers,
    required this.groundedClosureUsers,
    required this.secondClosureWithinSevenDaysUsers,
    required this.weekTwoReturningUsers,
    required this.formalGroundedTurns,
    required this.evidenceCompliantTurns,
    required this.feedbackCount,
    required this.feedbackByCategory,
    required this.feedbackBySeverity,
    required this.observationSpan,
  });

  double? get activationConversion =>
      _ratio(activatedUsers, importStartedUsers);

  double? get importToCoverageConversion =>
      _ratio(coverageReviewUsers, importStartedUsers);

  double? get secondClosureRate =>
      _ratio(secondClosureWithinSevenDaysUsers, activatedUsers);

  double? get weekTwoReturnRate => _ratio(weekTwoReturningUsers, invitedUsers);

  double? get evidenceComplianceRate =>
      _ratio(evidenceCompliantTurns, formalGroundedTurns);

  bool get hasFormalCohort => invitedUsers >= 10 && observedUsers >= 10;

  bool get hasSevenDayObservation => observationSpan >= const Duration(days: 7);

  PrivateAlphaTargetStatus get activationConversionStatus => _status(
        enoughData: hasFormalCohort && importStartedUsers > 0,
        met: (activationConversion ?? 0) >= 0.60,
      );

  PrivateAlphaTargetStatus get activationTimeStatus => _status(
        enoughData: hasFormalCohort && medianActivationMinutes != null,
        met: (medianActivationMinutes ?? double.infinity) <= 15,
      );

  PrivateAlphaTargetStatus get secondClosureStatus => _status(
        enoughData:
            hasFormalCohort && hasSevenDayObservation && activatedUsers > 0,
        met: (secondClosureRate ?? 0) >= 0.50,
      );

  PrivateAlphaTargetStatus get weekTwoReturnStatus => _status(
        enoughData: hasFormalCohort && hasSevenDayObservation,
        met: (weekTwoReturnRate ?? 0) >= 0.30,
      );

  PrivateAlphaTargetStatus get evidenceComplianceStatus => _status(
        enoughData: hasFormalCohort && formalGroundedTurns > 0,
        met: evidenceComplianceRate == 1,
      );

  Map<String, Object?> toJson() {
    return {
      'cohort': {
        'invited_users': invitedUsers,
        'observed_users': observedUsers,
        'observation_days': observationSpan.inHours / 24,
      },
      'activation': {
        'import_started_users': importStartedUsers,
        'coverage_review_users': coverageReviewUsers,
        'activated_users': activatedUsers,
        'import_to_coverage_conversion': importToCoverageConversion,
        'import_to_activation_conversion': activationConversion,
        'median_minutes_to_first_grounded_turn': medianActivationMinutes,
        'over_thirty_minutes_users': activationOverThirtyMinutesUsers,
      },
      'engagement': {
        'grounded_closure_users': groundedClosureUsers,
        'second_closure_within_seven_days_users':
            secondClosureWithinSevenDaysUsers,
        'second_closure_rate': secondClosureRate,
        'week_two_returning_users': weekTwoReturningUsers,
        'week_two_return_rate': weekTwoReturnRate,
      },
      'evidence': {
        'formal_grounded_turns': formalGroundedTurns,
        'compliant_turns': evidenceCompliantTurns,
        'compliance_rate': evidenceComplianceRate,
      },
      'feedback': {
        'count': feedbackCount,
        'by_category': feedbackByCategory,
        'by_severity': feedbackBySeverity,
      },
      'target_status': {
        'activation_conversion': activationConversionStatus.value,
        'activation_time': activationTimeStatus.value,
        'second_closure': secondClosureStatus.value,
        'week_two_return': weekTwoReturnStatus.value,
        'evidence_compliance': evidenceComplianceStatus.value,
      },
    };
  }

  String toMarkdown() {
    String percent(double? value) =>
        value == null ? 'n/a' : '${(value * 100).toStringAsFixed(1)}%';
    String number(double? value) =>
        value == null ? 'n/a' : value.toStringAsFixed(1);

    return [
      '# Anchor Learning Private Alpha Metrics',
      '',
      '- Invited users: $invitedUsers',
      '- Observed event-export users: $observedUsers',
      '- Observation span: ${(observationSpan.inHours / 24).toStringAsFixed(1)} days',
      '',
      '## Activation',
      '',
      '- Import started: $importStartedUsers',
      '- Coverage review reached: $coverageReviewUsers (${percent(importToCoverageConversion)})',
      '- Activated: $activatedUsers (${percent(activationConversion)})',
      '- Median minutes to first grounded turn: ${number(medianActivationMinutes)}',
      '- Sessions over 30 minutes: $activationOverThirtyMinutesUsers',
      '',
      '## Engagement',
      '',
      '- Grounded closure users: $groundedClosureUsers',
      '- Second closure within 7 days: $secondClosureWithinSevenDaysUsers (${percent(secondClosureRate)})',
      '- Week-two return proxy: $weekTwoReturningUsers (${percent(weekTwoReturnRate)})',
      '',
      '## Evidence And Feedback',
      '',
      '- Evidence-compliant formal turns: $evidenceCompliantTurns / $formalGroundedTurns (${percent(evidenceComplianceRate)})',
      '- Feedback exports recorded: $feedbackCount',
      '- Feedback by category: ${_mapText(feedbackByCategory)}',
      '- Feedback by severity: ${_mapText(feedbackBySeverity)}',
      '',
      '## Fixed Target Status',
      '',
      '| Target | Status |',
      '| --- | --- |',
      '| Import-to-activation >= 60% | ${activationConversionStatus.value} |',
      '| Median activation time <= 15 minutes | ${activationTimeStatus.value} |',
      '| Second closure within 7 days >= 50% of activated users | ${secondClosureStatus.value} |',
      '| Week-two return >= 30% of invited users | ${weekTwoReturnStatus.value} |',
      '| Evidence compliance = 100% | ${evidenceComplianceStatus.value} |',
      '',
      'Interview learning claims, crash-free starts, and support interventions require the manual cohort report.',
    ].join('\n');
  }

  static double? _ratio(int numerator, int denominator) {
    if (denominator <= 0) return null;
    return numerator / denominator;
  }

  static PrivateAlphaTargetStatus _status({
    required bool enoughData,
    required bool met,
  }) {
    if (!enoughData) return PrivateAlphaTargetStatus.insufficientData;
    return met ? PrivateAlphaTargetStatus.met : PrivateAlphaTargetStatus.missed;
  }

  static String _mapText(Map<String, int> values) {
    if (values.isEmpty) return 'none';
    final entries = values.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries.map((entry) => '${entry.key}=${entry.value}').join(', ');
  }
}

class PrivateAlphaMetricsAggregator {
  const PrivateAlphaMetricsAggregator();

  PrivateAlphaMetricsReport aggregate(
    Iterable<Map<String, Object?>> exports, {
    required int invitedUsers,
  }) {
    if (invitedUsers < 0) {
      throw ArgumentError.value(invitedUsers, 'invitedUsers');
    }
    final eventsById = <String, _AlphaEvent>{};
    DateTime? earliestEventAt;
    DateTime? latestCollectionAt;

    for (final export in exports) {
      final collectedAt = _dateTime(export['generated_at'], 'generated_at');
      if (latestCollectionAt == null ||
          collectedAt.isAfter(latestCollectionAt)) {
        latestCollectionAt = collectedAt;
      }
      final rawEvents = export['events'];
      if (rawEvents is! List) {
        throw const FormatException(
            'Event export must contain an events list.');
      }
      for (final rawEvent in rawEvents) {
        if (rawEvent is! Map) {
          throw const FormatException(
              'Every exported event must be an object.');
        }
        final event = _AlphaEvent.fromJson(Map<String, Object?>.from(rawEvent));
        eventsById.putIfAbsent(event.id, () => event);
        if (earliestEventAt == null ||
            event.occurredAt.isBefore(earliestEventAt)) {
          earliestEventAt = event.occurredAt;
        }
      }
    }

    final eventsByUser = <String, List<_AlphaEvent>>{};
    for (final event in eventsById.values) {
      eventsByUser.putIfAbsent(event.anonymousInstallId, () => []).add(event);
    }
    for (final events in eventsByUser.values) {
      events.sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
    }

    final activationMinutes = <double>[];
    var importStartedUsers = 0;
    var coverageReviewUsers = 0;
    var activatedUsers = 0;
    var activationOverThirtyMinutesUsers = 0;
    var groundedClosureUsers = 0;
    var secondClosureWithinSevenDaysUsers = 0;
    var weekTwoReturningUsers = 0;
    var formalGroundedTurns = 0;
    var evidenceCompliantTurns = 0;
    var feedbackCount = 0;
    final feedbackByCategory = <String, int>{};
    final feedbackBySeverity = <String, int>{};

    for (final events in eventsByUser.values) {
      if (events.isEmpty) continue;
      final firstEventAt = events.first.occurredAt;
      final importAt = _firstEventTime(events, 'project_import_started');
      if (importAt != null) {
        importStartedUsers++;
        final coverageAt = _firstEventTime(
          events,
          'coverage_review_completed',
          notBefore: importAt,
        );
        if (coverageAt != null) coverageReviewUsers++;
        final activationAt = _firstEventTime(
          events,
          'grounded_turn_completed',
          notBefore: importAt,
        );
        if (activationAt != null) {
          activatedUsers++;
          final minutes = activationAt.difference(importAt).inMilliseconds /
              Duration.millisecondsPerMinute;
          activationMinutes.add(minutes);
          if (minutes > 30) activationOverThirtyMinutesUsers++;
        }
      }

      final closures = _closureTimes(events);
      if (closures.isNotEmpty) groundedClosureUsers++;
      if (closures.length >= 2 &&
          closures[1].difference(closures[0]) <= const Duration(days: 7)) {
        secondClosureWithinSevenDaysUsers++;
      }
      if (events.any((event) {
        final sinceFirst = event.occurredAt.difference(firstEventAt);
        return sinceFirst >= const Duration(days: 7) &&
            sinceFirst < const Duration(days: 14);
      })) {
        weekTwoReturningUsers++;
      }

      for (final event in events) {
        if (event.name == 'grounded_turn_completed') {
          formalGroundedTurns++;
          if (_isEvidenceCompliant(event)) evidenceCompliantTurns++;
        }
        if (event.name == 'feedback_submitted') {
          feedbackCount++;
          _increment(feedbackByCategory, event.stringProperty('category'));
          _increment(feedbackBySeverity, event.stringProperty('severity'));
        }
      }
    }

    final observationSpan =
        earliestEventAt == null || latestCollectionAt == null
            ? Duration.zero
            : latestCollectionAt.difference(earliestEventAt);

    return PrivateAlphaMetricsReport(
      invitedUsers: invitedUsers,
      observedUsers: eventsByUser.length,
      importStartedUsers: importStartedUsers,
      coverageReviewUsers: coverageReviewUsers,
      activatedUsers: activatedUsers,
      medianActivationMinutes: _median(activationMinutes),
      activationOverThirtyMinutesUsers: activationOverThirtyMinutesUsers,
      groundedClosureUsers: groundedClosureUsers,
      secondClosureWithinSevenDaysUsers: secondClosureWithinSevenDaysUsers,
      weekTwoReturningUsers: weekTwoReturningUsers,
      formalGroundedTurns: formalGroundedTurns,
      evidenceCompliantTurns: evidenceCompliantTurns,
      feedbackCount: feedbackCount,
      feedbackByCategory: feedbackByCategory,
      feedbackBySeverity: feedbackBySeverity,
      observationSpan:
          observationSpan.isNegative ? Duration.zero : observationSpan,
    );
  }

  static DateTime? _firstEventTime(
    List<_AlphaEvent> events,
    String name, {
    DateTime? notBefore,
  }) {
    for (final event in events) {
      if (event.name != name) continue;
      if (notBefore != null && event.occurredAt.isBefore(notBefore)) continue;
      return event.occurredAt;
    }
    return null;
  }

  static List<DateTime> _closureTimes(List<_AlphaEvent> events) {
    final closures = <DateTime>[];
    DateTime? pendingTurnAt;
    for (final event in events) {
      if (event.name == 'grounded_turn_completed') {
        pendingTurnAt = event.occurredAt;
        continue;
      }
      final closesTurn = event.name == 'follow_up_completed' ||
          event.name == 'review_scheduled';
      if (!closesTurn || pendingTurnAt == null) continue;
      if (!event.occurredAt.isBefore(pendingTurnAt) &&
          _sameUtcWeek(pendingTurnAt, event.occurredAt)) {
        closures.add(event.occurredAt);
        pendingTurnAt = null;
      }
    }
    return closures;
  }

  static bool _isEvidenceCompliant(_AlphaEvent event) {
    final disposition = event.stringProperty('disposition');
    if (disposition == 'partial' || disposition == 'refused') return true;
    return disposition == 'grounded' && event.intProperty('citation_count') > 0;
  }

  static bool _sameUtcWeek(DateTime left, DateTime right) {
    DateTime weekStart(DateTime value) {
      final utc = value.toUtc();
      final day = DateTime.utc(utc.year, utc.month, utc.day);
      return day.subtract(Duration(days: utc.weekday - DateTime.monday));
    }

    return weekStart(left) == weekStart(right);
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    values.sort();
    final middle = values.length ~/ 2;
    if (values.length.isOdd) return values[middle];
    return (values[middle - 1] + values[middle]) / 2;
  }

  static void _increment(Map<String, int> counts, String value) {
    if (value.isEmpty) return;
    counts[value] = (counts[value] ?? 0) + 1;
  }

  static DateTime _dateTime(Object? value, String field) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Invalid $field timestamp.');
    return parsed.toUtc();
  }
}

class _AlphaEvent {
  final String id;
  final String name;
  final String anonymousInstallId;
  final DateTime occurredAt;
  final Map<String, Object?> properties;

  const _AlphaEvent({
    required this.id,
    required this.name,
    required this.anonymousInstallId,
    required this.occurredAt,
    required this.properties,
  });

  factory _AlphaEvent.fromJson(Map<String, Object?> json) {
    final id = json['event_id']?.toString().trim() ?? '';
    final name = json['event_name']?.toString().trim() ?? '';
    final installId = json['anonymous_install_id']?.toString().trim() ?? '';
    if (id.isEmpty || name.isEmpty || installId.isEmpty) {
      throw const FormatException(
        'Exported events require event_id, event_name, and anonymous_install_id.',
      );
    }
    final rawProperties = json['properties'];
    if (rawProperties is! Map) {
      throw const FormatException(
          'Exported event properties must be an object.');
    }
    return _AlphaEvent(
      id: id,
      name: name,
      anonymousInstallId: installId,
      occurredAt: PrivateAlphaMetricsAggregator._dateTime(
        json['occurred_at'],
        'occurred_at',
      ),
      properties: Map<String, Object?>.from(rawProperties),
    );
  }

  String stringProperty(String key) => properties[key]?.toString() ?? '';

  int intProperty(String key) {
    final value = properties[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
