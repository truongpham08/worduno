class TermDto {
  const TermDto({
    required this.id,
    required this.text,
    required this.definition,
  });

  factory TermDto.fromJson(Map<String, dynamic> json) {
    return TermDto(
      id: json['id'] as String? ?? json['term'] as String? ?? '',
      text: json['term'] as String? ?? json['text'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
    );
  }

  final String id;
  final String text;
  final String definition;

  Map<String, dynamic> toJson() => {
        'id': id,
        'term': text,
        'definition': definition,
      };
}
