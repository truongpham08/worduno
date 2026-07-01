import 'exam_paper.dart';
import 'graded_answer.dart';

class ExamResult {
  const ExamResult({
    required this.examId,
    required this.paper,
    required this.answers,
    required this.correctCount,
    required this.wrongCount,
    required this.percentage,
    required this.completedAt,
  });

  final String examId;
  final ExamPaper paper;
  final List<GradedAnswer> answers;
  final int correctCount;
  final int wrongCount;
  final double percentage;
  final DateTime completedAt;
}
