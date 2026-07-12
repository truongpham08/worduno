Future<List<R>> mapLimitedConcurrent<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T item) mapper,
) async {
  if (items.isEmpty) {
    return const [];
  }

  final results = List<R?>.filled(items.length, null);
  var nextIndex = 0;
  final workerCount = concurrency.clamp(1, items.length);

  Future<void> worker() async {
    while (true) {
      final index = nextIndex++;
      if (index >= items.length) {
        return;
      }
      results[index] = await mapper(items[index]);
    }
  }

  await Future.wait(List.generate(workerCount, (_) => worker()));
  return results.cast<R>();
}
