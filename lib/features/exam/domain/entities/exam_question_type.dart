enum ExamQuestionType {
  termToDefinition('term_to_definition', 'Term → Definition'),
  definitionToTerm('definition_to_term', 'Definition → Term'),
  clozeAi('cloze_ai', 'Cloze AI'),
  matching('matching', 'Matching'),
  englishToVietnamese('english_to_vietnamese', 'English → Vietnamese'),
  englishToEnglish('english_to_english', 'English → English'),
  sentenceWritingAi('sentence_writing_ai', 'Sentence Writing AI');

  const ExamQuestionType(this.storageKey, this.label);

  final String storageKey;
  final String label;

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
