class ClozeResponseDto {
  const ClozeResponseDto({
    required this.sentence,
    required this.options,
    required this.correctAnswer,
  });

  factory ClozeResponseDto.fromJson(Map<String, dynamic> json) {
    return ClozeResponseDto(
      sentence: json['sentence'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctAnswer: json['correct_answer'] as String,
    );
  }

  final String sentence;
  final List<String> options;
  final String correctAnswer;
}

class EvaluateSentenceResponseDto {
  const EvaluateSentenceResponseDto({
    required this.score,
    required this.grammar,
    required this.vocabulary,
    required this.naturalness,
    required this.suggestions,
  });

  factory EvaluateSentenceResponseDto.fromJson(Map<String, dynamic> json) {
    return EvaluateSentenceResponseDto(
      score: json['score'] as int,
      grammar: json['grammar'] as String,
      vocabulary: json['vocabulary'] as String,
      naturalness: json['naturalness'] as String,
      suggestions: (json['suggestion'] as List<dynamic>).cast<String>(),
    );
  }

  final int score;
  final String grammar;
  final String vocabulary;
  final String naturalness;
  final List<String> suggestions;

  String get feedbackText {
    final suggestionText = suggestions.join('\n• ');
    return 'Score: $score/10\n\nGrammar: $grammar\n\nVocabulary: $vocabulary\n\nNaturalness: $naturalness\n\nSuggestions:\n• $suggestionText';
  }
}
