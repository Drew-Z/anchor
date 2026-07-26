class SearchQueryTermService {
  const SearchQueryTermService();

  static const _concepts = <_BilingualSearchConcept>[
    _BilingualSearchConcept('mode', ['模式']),
    _BilingualSearchConcept('guarantee', ['保证', '保障']),
    _BilingualSearchConcept('conformance', ['一致性', '符合', '遵循']),
    _BilingualSearchConcept('transaction', ['事务']),
    _BilingualSearchConcept('atomic', ['原子', '原子性']),
    _BilingualSearchConcept(
      'rollback',
      ['回滚'],
      englishAliases: [
        'roll back',
        'rolls back',
        'rolls them back',
        'rolled back',
      ],
    ),
    _BilingualSearchConcept('retry', ['重试']),
    _BilingualSearchConcept('backoff', ['退避']),
    _BilingualSearchConcept('timeout', ['超时']),
    _BilingualSearchConcept('citation', ['引用']),
    _BilingualSearchConcept('evidence', ['证据']),
  ];

  List<String> terms(String query) {
    final normalized =
        query.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return const [];
    if (!RegExp(r'[\u3400-\u9fff]').hasMatch(normalized)) {
      final terms = _deduplicatedWhitespaceTerms(normalized).toSet();
      for (final concept in _concepts) {
        final matchesCanonical = terms.contains(concept.englishTerm);
        final matchesAlias = concept.englishAliases.any(
          (alias) => normalized.contains(alias),
        );
        if (!matchesCanonical && !matchesAlias) continue;
        terms
          ..add(concept.englishTerm)
          ..addAll(concept.englishAliases);
      }
      return terms.toList(growable: false);
    }

    final terms = <String>{};
    for (final match in RegExp(r'[a-z0-9_+.#-]+').allMatches(normalized)) {
      final term = match.group(0);
      if (term != null && term.isNotEmpty) terms.add(term);
    }

    var matchedChineseConcept = false;
    for (final concept in _concepts) {
      for (final alias in concept.chineseAliases) {
        if (!normalized.contains(alias)) continue;
        terms
          ..add(concept.englishTerm)
          ..addAll(concept.englishAliases)
          ..add(alias);
        matchedChineseConcept = true;
      }
    }

    if (!matchedChineseConcept) {
      for (final match in RegExp(r'[\u3400-\u9fff]+').allMatches(normalized)) {
        final term = match.group(0);
        if (term != null && term.isNotEmpty) terms.add(term);
      }
    }
    return terms.toList(growable: false);
  }

  List<String> _deduplicatedWhitespaceTerms(String query) {
    return query
        .split(RegExp(r'\s+'))
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList();
  }
}

class _BilingualSearchConcept {
  final String englishTerm;
  final List<String> chineseAliases;
  final List<String> englishAliases;

  const _BilingualSearchConcept(
    this.englishTerm,
    this.chineseAliases, {
    this.englishAliases = const [],
  });
}
