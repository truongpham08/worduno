import 'exam_question_type.dart';

class ExamHistorySummary {
  const ExamHistorySummary({
    required this.id,
    required this.date,
    required this.unitId,
    required this.unitLabel,
    required this.score,
    required this.questionCount,
  });

  final String id;
  final DateTime date;
  final String unitId;
  final String unitLabel;
  final double score;
  final int questionCount;
}

class ExamHistoryQuestion {
  const ExamHistoryQuestion({
    required this.type,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  final ExamQuestionType type;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
}

class ExamHistoryDetail extends ExamHistorySummary {
  const ExamHistoryDetail({
    required super.id,
    required super.date,
    required super.unitId,
    required super.unitLabel,
    required super.score,
    required super.questionCount,
    required this.questions,
  });

  final List<ExamHistoryQuestion> questions;
}
