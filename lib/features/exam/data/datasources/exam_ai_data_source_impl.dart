import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../dtos/exam_ai_dtos.dart';
import 'i_exam_ai_data_source.dart';

class ExamAiDataSourceImpl implements IExamAiDataSource {
  ExamAiDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ClozeResponseDto> generateCloze({
    required String word,
    required String definition,
    required String level,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.examClozePath,
        data: {
          'word': word,
          'definition': definition,
          'level': _mapLevel(level),
        },
      );
      return ClozeResponseDto.fromJson(response.data!);
    } on DioException catch (error) {
      throw AppException(
        error.message ?? 'Failed to generate cloze question.',
        code: 'exam_cloze_failed',
      );
    }
  }

  @override
  Future<EvaluateSentenceResponseDto> evaluateSentenceWriting({
    required String word,
    required String definition,
    required String sentence,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.examEvaluateSentencePath,
        data: {
          'word': word,
          'definition': definition,
          'sentence': sentence,
        },
      );
      return EvaluateSentenceResponseDto.fromJson(response.data!);
    } on DioException catch (error) {
      throw AppException(
        error.message ?? 'Failed to evaluate sentence.',
        code: 'exam_evaluate_sentence_failed',
      );
    }
  }

  String _mapLevel(String levelCode) {
    final normalized = levelCode.toLowerCase();
    if (normalized.contains('c1') || normalized.contains('c2')) {
      return 'c1&c2';
    }
    if (normalized.contains('b2')) {
      return 'b2';
    }
    return 'b1';
  }
}
