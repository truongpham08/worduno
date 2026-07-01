import 'exam_question.dart';

class GradedAnswer {
  const GradedAnswer({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    this.feedback,
    this.score,
  });

  final ExamQuestion question;
  final String userAnswer;
  final bool isCorrect;
  final String? feedback;
  final int? score;
}
