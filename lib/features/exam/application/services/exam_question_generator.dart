import 'dart:math';

import '../../domain/entities/exam_config.dart';
import '../../domain/entities/exam_paper.dart';
import '../../domain/entities/exam_question.dart';
import '../../domain/entities/exam_question_type.dart';
import '../../domain/entities/exam_source_term.dart';
import '../../data/datasources/i_exam_ai_data_source.dart';

class ExamQuestionGenerator {
  ExamQuestionGenerator(this._aiDataSource, {Random? random})
      : _random = random ?? Random();

  final IExamAiDataSource _aiDataSource;
  final Random _random;

  Future<ExamPaper> generate({
    required ExamConfig config,
    required List<ExamSourceTerm> pool,
  }) async {
    if (config.enabledTypes.isEmpty) {
      throw StateError('At least one question type must be enabled.');
    }

    final available = List<ExamSourceTerm>.from(pool)..shuffle(_random);
    final minTerms = _minimumTermsNeeded(config);
    if (available.length < minTerms) {
      throw StateError(
        'Not enough words (${available.length}) for ${config.questionCount} questions.',
      );
    }

    final questions = <ExamQuestion>[];
    var index = 0;
    var termCursor = 0;
    final types = config.enabledTypes.toList()..shuffle(_random);
    var typeCursor = 0;
    var attempts = 0;
    final maxAttempts = config.questionCount * types.length * 6;

    while (questions.length < config.questionCount && attempts < maxAttempts) {
      attempts++;
      final type = types[typeCursor % types.length];
      typeCursor++;

      if (type == ExamQuestionType.matching) {
        if (available.length - termCursor < 5) {
          continue;
        }
        final block = available.sublist(termCursor, termCursor + 5);
        termCursor += 5;
        questions.add(_buildMatchingQuestion(index++, block));
        continue;
      }

      if (termCursor >= available.length) {
        break;
      }

      final term = available[termCursor++];
      final question = await _buildQuestion(
        index: index++,
        type: type,
        term: term,
        pool: available,
        levelCode: config.levelCode,
      );
      questions.add(question);
    }

    if (questions.length < config.questionCount) {
      throw StateError(
        'Could only generate ${questions.length} of ${config.questionCount} questions.',
      );
    }

    return ExamPaper(
      id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
      config: config,
      questions: questions,
      createdAt: DateTime.now(),
    );
  }

  int _minimumTermsNeeded(ExamConfig config) {
    var needed = config.questionCount;
    if (config.enabledTypes.contains(ExamQuestionType.matching)) {
      needed += 4;
    }
    return needed;
  }

  Future<ExamQuestion> _buildQuestion({
    required int index,
    required ExamQuestionType type,
    required ExamSourceTerm term,
    required List<ExamSourceTerm> pool,
    required String levelCode,
  }) async {
    return switch (type) {
      ExamQuestionType.termToDefinition =>
        _buildMultipleChoice(index, type, term, pool, useDefinitions: true),
      ExamQuestionType.definitionToTerm =>
        _buildMultipleChoice(index, type, term, pool, useDefinitions: false),
      ExamQuestionType.clozeAi => _buildCloze(index, term, levelCode),
      ExamQuestionType.englishToVietnamese =>
        _buildFreeText(index, type, term, correctAnswer: term.definition),
      ExamQuestionType.englishToEnglish =>
        _buildFreeText(
          index,
          type,
          term,
          correctAnswer: _stripPosTag(term.text),
        ),
      ExamQuestionType.sentenceWritingAi =>
        _buildFreeText(
          index,
          type,
          term,
          correctAnswer: _stripPosTag(term.text),
        ),
      ExamQuestionType.matching => throw StateError('Use matching block.'),
    };
  }

  ExamQuestion _buildMultipleChoice(
    int index,
    ExamQuestionType type,
    ExamSourceTerm term,
    List<ExamSourceTerm> pool, {
    required bool useDefinitions,
  }) {
    final correct = useDefinitions ? term.definition : term.text;
    final distractors = <String>{};
    final shuffledPool = List<ExamSourceTerm>.from(pool)..shuffle(_random);

    for (final candidate in shuffledPool) {
      if (candidate.termId == term.termId) {
        continue;
      }
      final value = useDefinitions ? candidate.definition : candidate.text;
      if (value != correct) {
        distractors.add(value);
      }
      if (distractors.length == 3) {
        break;
      }
    }

    while (distractors.length < 3) {
      distractors.add('—');
    }

    final options = [correct, ...distractors]..shuffle(_random);

    return ExamQuestion(
      id: 'q_$index',
      type: type,
      prompt: useDefinitions ? term.text : term.definition,
      termId: term.termId,
      termText: term.text,
      definition: term.definition,
      options: options,
      correctAnswer: correct,
    );
  }

  Future<ExamQuestion> _buildCloze(
    int index,
    ExamSourceTerm term,
    String levelCode,
  ) async {
    final cloze = await _aiDataSource.generateCloze(
      word: term.text,
      definition: term.definition,
      level: levelCode,
    );
    return ExamQuestion(
      id: 'q_$index',
      type: ExamQuestionType.clozeAi,
      prompt: cloze.sentence,
      termId: term.termId,
      termText: term.text,
      definition: term.definition,
      options: cloze.options,
      correctAnswer: cloze.correctAnswer,
      clozeSentence: cloze.sentence,
    );
  }

  ExamQuestion _buildFreeText(
    int index,
    ExamQuestionType type,
    ExamSourceTerm term, {
    required String correctAnswer,
  }) {
    return ExamQuestion(
      id: 'q_$index',
      type: type,
      prompt: term.text,
      termId: term.termId,
      termText: term.text,
      definition: term.definition,
      correctAnswer: correctAnswer,
    );
  }

  static final RegExp _posTagPattern = RegExp(
    r'\s*\((?:n|v|adj|adv|prep|conj|pron|interj|phrase|phr)\.?\)\s*$',
    caseSensitive: false,
  );

  String _stripPosTag(String value) {
    return value.replaceFirst(_posTagPattern, '').trim();
  }

  ExamQuestion _buildMatchingQuestion(int index, List<ExamSourceTerm> block) {
    final pairs = block
        .map(
          (term) => MatchingPair(
            termId: term.termId,
            termText: term.text,
            definition: term.definition,
          ),
        )
        .toList();
    final definitions = pairs.map((pair) => pair.definition).toList()
      ..shuffle(_random);

    return ExamQuestion(
      id: 'q_$index',
      type: ExamQuestionType.matching,
      prompt: 'Matching',
      termId: block.first.termId,
      termText: block.first.text,
      definition: block.first.definition,
      matchingPairs: pairs,
      shuffledDefinitions: definitions,
      correctAnswer: pairs
          .map((pair) => '${pair.termText} → ${pair.definition}')
          .join('\n'),
    );
  }
}
