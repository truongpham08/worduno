enum ExamQuestionType {
  termToDefinition(
    'term_to_definition',
    'Term → Definition',
    'Pick the correct definition for a term',
  ),
  definitionToTerm(
    'definition_to_term',
    'Definition → Term',
    'Pick the correct term for a definition',
  ),
  clozeAi(
    'cloze_ai',
    'Cloze AI',
    'Fill in the blank with AI-generated context',
    isAiPowered: true,
  ),
  matching(
    'matching',
    'Matching',
    'Match terms with their definitions',
  ),
  englishToVietnamese(
    'english_to_vietnamese',
    'English → Vietnamese',
    'Translate from English to Vietnamese',
  ),
  englishToEnglish(
    'english_to_english',
    'English → English',
    'Paraphrase or synonym in English',
  ),
  sentenceWritingAi(
    'sentence_writing_ai',
    'Sentence Writing AI',
    'Write a sentence using the target word',
    isAiPowered: true,
  );

  const ExamQuestionType(
    this.storageKey,
    this.label,
    this.description, {
    this.isAiPowered = false,
  });

  final String storageKey;
  final String label;
  final String description;
  final bool isAiPowered;

  static ExamQuestionType? fromStorageKey(String key) {
    for (final type in ExamQuestionType.values) {
      if (type.storageKey == key) {
        return type;
      }
    }
    return null;
  }

  static const List<ExamQuestionType> defaults = ExamQuestionType.values;
}
