import 'dart:async';

class SearchQueryDebouncer {
  final Duration delay;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  SearchQueryDebouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  void schedule(String query, void Function(String query) onCommit) {
    if (_disposed) return;
    _timer?.cancel();
    final generation = ++_generation;
    if (query.trim().isEmpty) return;
    _timer = Timer(delay, () {
      if (_disposed || generation != _generation) return;
      onCommit(query);
    });
  }

  void cancel() {
    _timer?.cancel();
    _generation++;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancel();
  }
}
