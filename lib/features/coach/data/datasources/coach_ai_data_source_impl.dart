import '../../../../core/errors/app_exception.dart';
import 'i_coach_ai_data_source.dart';

/// Stub until AI endpoints are published on the backend OpenAPI.
class CoachAiDataSourceImpl implements ICoachAiDataSource {
  @override
  Future<Map<String, dynamic>> evaluateSentence({
    required String word,
    required String userSentence,
  }) {
    throw const AppException(
      'Coach AI endpoint is not available yet.',
      code: 'coach_ai_unimplemented',
    );
  }
}
