import 'package:flutter_test/flutter_test.dart';

import 'package:worduno/features/exam/application/services/exam_grader.dart';
import 'package:worduno/features/exam/data/datasources/i_exam_ai_data_source.dart';
import 'package:worduno/features/exam/data/dtos/exam_ai_dtos.dart';
import 'package:worduno/features/exam/domain/entities/exam_question.dart';
import 'package:worduno/features/exam/domain/entities/exam_question_type.dart';

void main() {
  group('ExamGrader', () {
    late ExamGrader grader;

    setUp(() {
      grader = ExamGrader(_StubAiDataSource());
    });

    test('grades multiple choice correctly', () async {
      const question = ExamQuestion(
        id: 'q1',
        type: ExamQuestionType.termToDefinition,
        prompt: 'happy',
        termId: '1',
        termText: 'happy',
        definition: 'feeling joy',
        options: ['feeling joy', 'sad', 'angry', 'tired'],
        correctAnswer: 'feeling joy',
      );

      final correct = await grader.grade(
        question: question,
        rawAnswer: 'feeling joy',
      );
      final wrong = await grader.grade(
        question: question,
        rawAnswer: 'sad',
      );

      expect(correct.isCorrect, isTrue);
      expect(wrong.isCorrect, isFalse);
    });

    test('grades english to english with case insensitivity', () async {
      const question = ExamQuestion(
        id: 'q2',
        type: ExamQuestionType.englishToEnglish,
        prompt: 'feeling joy',
        termId: '1',
        termText: 'Happy',
        definition: 'feeling joy',
        correctAnswer: 'Happy',
      );

      final result = await grader.grade(question: question, rawAnswer: 'happy');
      expect(result.isCorrect, isTrue);
    });

    test('grades english to vietnamese using definition synonyms', () async {
      const question = ExamQuestion(
        id: 'q3',
        type: ExamQuestionType.englishToVietnamese,
        prompt: 'happy',
        termId: '1',
        termText: 'happy',
        definition: 'vui vẻ, hạnh phúc',
        correctAnswer: 'vui vẻ, hạnh phúc',
      );

      final result =
          await grader.grade(question: question, rawAnswer: 'Hạnh phúc');
      expect(result.isCorrect, isTrue);
    });
  });
}

class _StubAiDataSource implements IExamAiDataSource {
  @override
  Future<ClozeResponseDto> generateCloze({
    required String word,
    required String definition,
    required String level,
  }) {
    return Future.value(
      const ClozeResponseDto(
        sentence: 'She felt _____.',
        options: ['happy', 'sad', 'angry', 'tired'],
        correctAnswer: 'happy',
      ),
    );
  }

  @override
  Future<EvaluateSentenceResponseDto> evaluateSentenceWriting({
    required String word,
    required String definition,
    required String sentence,
  }) {
    return Future.value(
      const EvaluateSentenceResponseDto(
        score: 8,
        grammar: 'Good',
        vocabulary: 'Good',
        naturalness: 'Good',
        suggestions: ['Nice sentence'],
      ),
    );
  }
}
