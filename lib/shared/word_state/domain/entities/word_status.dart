enum WordStatus {
  newWord('new'),
  learning('learning'),
  know('know');

  const WordStatus(this.storageValue);

  final String storageValue;

  static WordStatus fromStorage(String value) {
    return WordStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => WordStatus.newWord,
    );
  }
}
