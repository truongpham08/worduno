import '../../../../core/errors/app_exception.dart';
import 'i_exam_ai_data_source.dart';

/// Stub until AI endpoints are published on the backend OpenAPI.
class ExamAiDataSourceImpl implements IExamAiDataSource {
  @override
  Future<Map<String, dynamic>> generateClozeQuestion({
    required String term,
    required String definition,
  }) {
    throw const AppException(
      'Exam AI endpoint is not available yet.',
      code: 'exam_ai_unimplemented',
    );
  }

  @override
  Future<bool> evaluateEnglishToVietnamese({
    required String term,
    required String userAnswer,
  }) {
    throw const AppException(
      'Exam AI endpoint is not available yet.',
      code: 'exam_ai_unimplemented',
    );
  }

  @override
  Future<Map<String, dynamic>> evaluateSentenceWriting({
    required String term,
    required String userSentence,
  }) {
    throw const AppException(
      'Exam AI endpoint is not available yet.',
      code: 'exam_ai_unimplemented',
    );
  }
}
