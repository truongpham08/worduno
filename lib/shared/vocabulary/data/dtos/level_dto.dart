class LevelDto {
  const LevelDto({
    required this.code,
    this.totalTerms = 0,
    this.knownTerms = 0,
  });

  factory LevelDto.fromJson(Map<String, dynamic> json) {
    return LevelDto(
      code: json['code'] as String? ?? json['level'] as String? ?? '',
      totalTerms: json['total_terms'] as int? ?? 0,
      knownTerms: json['known_terms'] as int? ?? 0,
    );
  }

  final String code;
  final int totalTerms;
  final int knownTerms;

  Map<String, dynamic> toJson() => {
        'code': code,
        'total_terms': totalTerms,
        'known_terms': knownTerms,
      };
}
