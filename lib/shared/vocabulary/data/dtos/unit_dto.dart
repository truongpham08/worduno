class UnitDto {
  const UnitDto({
    required this.id,
    required this.name,
    this.totalTerms = 0,
    this.knownTerms = 0,
  });

  factory UnitDto.fromJson(Map<String, dynamic> json) {
    return UnitDto(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      totalTerms: json['total_terms'] as int? ?? 0,
      knownTerms: json['known_terms'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final int totalTerms;
  final int knownTerms;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'total_terms': totalTerms,
        'known_terms': knownTerms,
      };
}
