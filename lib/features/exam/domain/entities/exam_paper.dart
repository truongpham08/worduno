import 'exam_config.dart';
import 'exam_question.dart';

class ExamPaper {
  const ExamPaper({
    required this.id,
    required this.config,
    required this.questions,
    required this.createdAt,
  });

  final String id;
  final ExamConfig config;
  final List<ExamQuestion> questions;
  final DateTime createdAt;
}
