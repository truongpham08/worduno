import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../dtos/level_dto.dart';
import '../dtos/term_dto.dart';
import '../dtos/unit_dto.dart';
import 'i_vocabulary_remote_data_source.dart';

class VocabularyRemoteDataSourceImpl implements IVocabularyRemoteDataSource {
  VocabularyRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<LevelDto>> getLevels() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.levelsPath);
      return _parseList(response.data, LevelDto.fromJson);
    } catch (error) {
      throw AppException('Failed to load levels: $error');
    }
  }

  @override
  Future<List<UnitDto>> getUnits(String levelCode) async {
    try {
      final response =
          await _dio.get<dynamic>(ApiConstants.unitsPath(levelCode));
      return _parseList(response.data, UnitDto.fromJson);
    } catch (error) {
      throw AppException('Failed to load units: $error');
    }
  }

  @override
  Future<List<TermDto>> getTerms({
    required String levelCode,
    required String unitName,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.termsPath(levelCode, unitName),
      );
      return _parseList(response.data, TermDto.fromJson);
    } catch (error) {
      throw AppException('Failed to load terms: $error');
    }
  }

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
    }

    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['data'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(fromJson)
            .toList(growable: false);
      }
    }

    return const [];
  }
}
