import 'exam_question_type.dart';

class MatchingPair {
  const MatchingPair({
    required this.termId,
    required this.termText,
    required this.definition,
  });

  final String termId;
  final String termText;
  final String definition;
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.termId,
    required this.termText,
    required this.definition,
    this.options,
    this.correctAnswer,
    this.clozeSentence,
    this.matchingPairs,
    this.shuffledDefinitions,
  });

  final String id;
  final ExamQuestionType type;
  final String prompt;
  final String termId;
  final String termText;
  final String definition;
  final List<String>? options;
  final String? correctAnswer;
  final String? clozeSentence;
  final List<MatchingPair>? matchingPairs;
  final List<String>? shuffledDefinitions;

  String get displayStem {
    return switch (type) {
      ExamQuestionType.clozeAi => clozeSentence ?? prompt,
      ExamQuestionType.matching => 'Match each term with its definition.',
      ExamQuestionType.sentenceWritingAi =>
        'Write a sentence in English using the word "$termText".',
      ExamQuestionType.englishToVietnamese =>
        'Translate "$termText" into Vietnamese.',
      ExamQuestionType.englishToEnglish =>
        'Write the English word for this definition:\n$definition',
      ExamQuestionType.termToDefinition => termText,
      ExamQuestionType.definitionToTerm => definition,
    };
  }
}
