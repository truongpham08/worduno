import 'dart:convert';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../data/datasources/i_exam_ai_data_source.dart';
import '../../domain/entities/exam_question.dart';
import '../../domain/entities/exam_question_type.dart';
import '../../domain/entities/graded_answer.dart';

class ExamGrader {
  ExamGrader(this._aiDataSource);

  final IExamAiDataSource _aiDataSource;

  static const int sentencePassScore = 7;

  /// Matches trailing POS tags like " (n)", " (v)", " (adj)".
  static final RegExp _posTagPattern = RegExp(
    r'\s*\((?:n|v|adj|adv|prep|conj|pron|interj|phrase|phr)\.?\)\s*$',
    caseSensitive: false,
  );

  Future<GradedAnswer> grade({
    required ExamQuestion question,
    required String? rawAnswer,
  }) async {
    final answer = rawAnswer?.trim() ?? '';

    return switch (question.type) {
      ExamQuestionType.termToDefinition ||
      ExamQuestionType.definitionToTerm ||
      ExamQuestionType.clozeAi =>
        _gradeMultipleChoice(question, answer),
      ExamQuestionType.matching => _gradeMatching(question, answer),
      ExamQuestionType.englishToVietnamese =>
        _gradeEnglishToVietnamese(question, answer),
      ExamQuestionType.englishToEnglish =>
        _gradeEnglishToEnglish(question, answer),
      ExamQuestionType.sentenceWritingAi =>
        _gradeSentenceWriting(question, answer),
    };
  }

  GradedAnswer _gradeMultipleChoice(ExamQuestion question, String answer) {
    final isCorrect =
        _normalize(answer) == _normalize(question.correctAnswer ?? '');
    return GradedAnswer(
      question: question,
      userAnswer: answer,
      isCorrect: isCorrect,
    );
  }

  GradedAnswer _gradeMatching(ExamQuestion question, String answer) {
    final expected = question.matchingPairs ?? const [];
    final submitted = _decodeMatchingAnswer(answer);
    var isCorrect = submitted.length == expected.length;
    if (isCorrect) {
      for (final pair in expected) {
        if (_normalize(submitted[pair.termId] ?? '') !=
            _normalize(pair.definition)) {
          isCorrect = false;
          break;
        }
      }
    }

    return GradedAnswer(
      question: question,
      userAnswer: _formatMatchingAnswer(expected, submitted),
      isCorrect: isCorrect,
    );
  }

  GradedAnswer _gradeEnglishToVietnamese(ExamQuestion question, String answer) {
    final synonyms = _splitSynonyms(question.definition);
    final isCorrect = synonyms.any(
      (synonym) => _normalize(answer) == _normalize(synonym),
    );

    return GradedAnswer(
      question: question,
      userAnswer: answer,
      isCorrect: isCorrect,
    );
  }

  GradedAnswer _gradeEnglishToEnglish(ExamQuestion question, String answer) {
    final expected = _stripPosTag(question.termText);
    final isCorrect = _normalize(answer) == _normalize(expected) ||
        _normalize(answer) == _normalize(question.termText);
    return GradedAnswer(
      question: question,
      userAnswer: answer,
      isCorrect: isCorrect,
    );
  }

  Future<GradedAnswer> _gradeSentenceWriting(
    ExamQuestion question,
    String answer,
  ) async {
    if (answer.isEmpty) {
      return GradedAnswer(
        question: question,
        userAnswer: answer,
        isCorrect: false,
        feedback: 'No sentence submitted.',
        score: 0,
      );
    }

    try {
      final evaluation = await _aiDataSource.evaluateSentenceWriting(
        word: question.termText,
        definition: question.definition,
        sentence: answer,
      );
      return GradedAnswer(
        question: question,
        userAnswer: answer,
        isCorrect: evaluation.score >= sentencePassScore,
        feedback: evaluation.feedbackText,
        score: evaluation.score,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      final mapped = messageFromError(error);
      if (mapped == kNoInternetMessage ||
          mapped == kTimeoutMessage ||
          mapped == kAiUnavailableMessage ||
          mapped.startsWith('Server error')) {
        throw AppException(mapped);
      }
      final target = _stripPosTag(question.termText).toLowerCase();
      final containsWord = answer.toLowerCase().contains(target);
      return GradedAnswer(
        question: question,
        userAnswer: answer,
        isCorrect: containsWord,
        feedback:
            'AI evaluation unavailable. Accepted if the target word appears.',
        score: containsWord ? sentencePassScore : 0,
      );
    }
  }

  Map<String, String> _decodeMatchingAnswer(String answer) {
    if (answer.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(answer) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      return {};
    }
  }

  String _formatMatchingAnswer(
    List<MatchingPair> expected,
    Map<String, String> submitted,
  ) {
    return expected
        .map((pair) {
          final definition = submitted[pair.termId] ?? '(blank)';
          return '${pair.termText} → $definition';
        })
        .join('\n');
  }

  List<String> _splitSynonyms(String definition) {
    return definition
        .split(RegExp(r'[,;/]|(\bor\b)', caseSensitive: false))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  String _stripPosTag(String value) {
    return value.replaceFirst(_posTagPattern, '').trim();
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
