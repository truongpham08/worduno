class Level {
  const Level({
    required this.code,
    required this.totalTerms,
    required this.knownTerms,
  });

  final String code;
  final int totalTerms;
  final int knownTerms;

  double get progress =>
      totalTerms == 0 ? 0 : knownTerms / totalTerms;
}
