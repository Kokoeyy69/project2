import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;
  final Function(String) onSearch;

  Debouncer({required this.delay, required this.onSearch}) {
    _timer = Timer(const Duration(milliseconds: 0), () {});
    _timer!.cancel();
  }

  void call(String query) {
    _timer?.cancel();
    _timer = Timer(delay, () => onSearch(query));
  }

  void dispose() {
    _timer?.cancel();
  }
}