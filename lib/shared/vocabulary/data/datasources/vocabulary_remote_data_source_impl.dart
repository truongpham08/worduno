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
      final data = response.data;

      // API returns: ["b1", "b2", "c1&c2"]
      if (data is List) {
        return data
            .whereType<String>()
            .map((code) => LevelDto(code: code))
            .toList(growable: false);
      }
      return const [];
    } catch (error) {
      throw AppException('Failed to load levels: $error');
    }
  }

  @override
  Future<List<UnitDto>> getUnits(String levelCode) async {
    try {
      final response =
          await _dio.get<dynamic>(ApiConstants.unitsPath(levelCode));
      final data = response.data;

      // API returns: ["Phrasal verbs", "Problems and solutions", ...]
      if (data is List) {
        return data
            .whereType<String>()
            .mapIndexed(
              (index, name) => UnitDto(
                id: '$levelCode-$index',
                name: name,
              ),
            )
            .toList(growable: false);
      }
      return const [];
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
      final data = response.data;

      // API returns: [{"term": "add up", "definition": "tính tổng số"}, ...]
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TermDto.fromJson)
            .toList(growable: false);
      }
      return const [];
    } catch (error) {
      throw AppException('Failed to load terms: $error');
    }
  }
}

// Helper extension for indexed map
extension _IterableIndexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) f) sync* {
    var index = 0;
    for (final element in this) {
      yield f(index++, element);
    }
  }
}
