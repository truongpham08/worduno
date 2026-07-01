import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_error_message.dart';
import 'i_coach_ai_data_source.dart';

class CoachAiDataSourceImpl implements ICoachAiDataSource {
  CoachAiDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> explainWord({
    required String word,
    required String definition,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.coachExplainPath,
        data: {'word': word, 'definition': definition},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw const AppException('Invalid explain response format.');
    } on DioException catch (error) {
      throw AppException(messageFromDioException(error));
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException('Failed to explain word: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> evaluateSentence({
    required String word,
    required String sentence,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.coachEvaluatePath,
        data: {'word': word, 'sentence': sentence},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw const AppException('Invalid evaluate response format.');
    } on DioException catch (error) {
      throw AppException(messageFromDioException(error));
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException('Failed to evaluate sentence: $error');
    }
  }
}
