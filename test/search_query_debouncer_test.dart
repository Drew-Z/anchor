import 'package:dlg_q/services/agent/search_query_debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('commits only the latest query after the delay', () async {
    final committed = <String>[];
    final debouncer = SearchQueryDebouncer(
      delay: const Duration(milliseconds: 30),
    );

    debouncer.schedule('a', committed.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    debouncer.schedule('agent state', committed.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(committed, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(committed, ['agent state']);
    debouncer.dispose();
  });

  test('empty input and dispose cancel pending commits', () async {
    final committed = <String>[];
    final debouncer = SearchQueryDebouncer(
      delay: const Duration(milliseconds: 10),
    );

    debouncer.schedule('pending', committed.add);
    debouncer.schedule('', committed.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(committed, isEmpty);

    debouncer.schedule('disposed', committed.add);
    debouncer.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(committed, isEmpty);
  });
}
