class Unit {
  const Unit({
    required this.id,
    required this.name,
    required this.totalTerms,
    required this.knownTerms,
  });

  final String id;
  final String name;
  final int totalTerms;
  final int knownTerms;

  double get progress =>
      totalTerms == 0 ? 0 : knownTerms / totalTerms;
}
