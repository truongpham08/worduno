import 'dart:convert';

import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/word_state/application/services/i_word_state_service.dart';
import '../../../../shared/word_state/domain/entities/user_word_state.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/i_dashboard_repository.dart';
import '../datasources/i_dashboard_local_data_source.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  DashboardRepositoryImpl(
    this._vocabularyService,
    this._wordStateService,
    this._localDataSource,
  );

  final IVocabularyService _vocabularyService;
  final IWordStateService _wordStateService;
  final IDashboardLocalDataSource _localDataSource;

  @override
  Future<DashboardData> getDashboardData() async {
    final levels = await _vocabularyService.getLevels();
    final levelSummaries = <LevelProgressData>[];
    final unitSummaries = <UnitProgressData>[];

    var totalTerms = 0;
    var knownTerms = 0;
    var learningWordsCount = 0;
    var starredWordsCount = 0;

    for (final level in levels) {
      final units = await _vocabularyService.getUnits(level.code);

      var levelTotalTerms = 0;
      var levelKnownTerms = 0;

      for (final unit in units) {
        final terms = await _vocabularyService.getTerms(
          levelCode: level.code,
          unitName: unit.name,
        );
        final states = await _wordStateService.getByUnit(unit.id);

        final unitTotalTerms = unit.totalTerms > 0
            ? unit.totalTerms
            : terms.length;
        final unitKnownTerms = _countStatus(
          states,
          WordStatus.know,
          knownFallback: unit.knownTerms,
        );

        levelTotalTerms += unitTotalTerms;
        levelKnownTerms += unitKnownTerms;
        learningWordsCount += _countStatus(states, WordStatus.learning);
        starredWordsCount += states.where((state) => state.isStarred).length;

        unitSummaries.add(
          UnitProgressData(
            unitId: unit.id,
            unitName: unit.name,
            progress: _progress(unitKnownTerms, unitTotalTerms),
          ),
        );
      }

      totalTerms += levelTotalTerms;
      knownTerms += levelKnownTerms;
      levelSummaries.add(
        LevelProgressData(
          levelCode: level.code,
          levelName: _levelName(level.code),
          progress: _progress(levelKnownTerms, levelTotalTerms),
          knownTerms: levelKnownTerms,
          totalTerms: levelTotalTerms,
        ),
      );
    }

    final examStats = await _loadExamStats(unitSummaries);
    final recentCoachFeedback = await _loadRecentCoachFeedback();

    final strongestUnits = _strongestUnits(unitSummaries);

    return DashboardData(
      overallProgress: _progress(knownTerms, totalTerms),
      totalTerms: totalTerms,
      knownTerms: knownTerms,
      learnedWordsCount: knownTerms,
      learningWordsCount: learningWordsCount,
      starredWordsCount: starredWordsCount,
      examCount: examStats.examCount,
      averageExamScore: examStats.averageExamScore,
      levelProgressList: levelSummaries,
      strongestUnits: strongestUnits,
      weakestUnits: _weakestUnits(unitSummaries, strongestUnits),
      recentExams: examStats.recentExams,
      recentCoachFeedback: recentCoachFeedback,
    );
  }

  int _countStatus(
    List<UserWordState> states,
    WordStatus status, {
    int knownFallback = 0,
  }) {
    final count = states.where((state) => state.status == status).length;
    return count == 0 && status == WordStatus.know ? knownFallback : count;
  }

  double _progress(int known, int total) {
    if (total <= 0) {
      return 0;
    }
    return (known / total).clamp(0, 1).toDouble();
  }

  List<UnitProgressData> _strongestUnits(List<UnitProgressData> units) {
    final sorted = units.where((unit) => unit.progress > 0).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));

    return sorted.take(3).toList(growable: false);
  }

  List<UnitProgressData> _weakestUnits(
    List<UnitProgressData> units,
    List<UnitProgressData> strongest,
  ) {
    final strongestIds = strongest.map((unit) => unit.unitId).toSet();
    final sorted = units
        .where((unit) => !strongestIds.contains(unit.unitId))
        .toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));

    return sorted.take(3).toList(growable: false);
  }

  double _normalizeScore(double score) {
    if (score <= 1) {
      return score.clamp(0, 1).toDouble();
    }
    return (score / 100).clamp(0, 1).toDouble();
  }

  Future<_ExamStats> _loadExamStats(List<UnitProgressData> units) async {
    final rows = await _localDataSource.getExamHistoryRows();

    if (rows.isEmpty) {
      return const _ExamStats(
        examCount: 0,
        averageExamScore: 0,
        recentExams: [],
      );
    }

    final averageScore =
        rows
            .map((row) => _normalizeScore((row['score'] as num? ?? 0).toDouble()))
            .fold<double>(0, (sum, score) => sum + score) /
        rows.length;
    final unitNameById = {for (final unit in units) unit.unitId: unit.unitName};

    final recentExams = rows
        .take(3)
        .map((row) {
          final rawUnitId = row['unit_id'] as String? ?? '';
          final unit = _decodeExamUnit(rawUnitId);
          return RecentExamItem(
            id: row['id'] as String? ?? '',
            dateLabel: _dateLabel(row['date'] as String?),
            unitId: unit.id,
            unitName: unit.label.isNotEmpty
                ? unit.label
                : (unitNameById[unit.id] ?? unit.id),
            score: _normalizeScore((row['score'] as num? ?? 0).toDouble()),
            questionCount: row['question_count'] as int? ?? 0,
          );
        })
        .toList(growable: false);

    return _ExamStats(
      examCount: rows.length,
      averageExamScore: averageScore,
      recentExams: recentExams,
    );
  }

  Future<List<RecentCoachItem>> _loadRecentCoachFeedback() async {
    final rows = await _localDataSource.getRecentCoachHistoryRows();

    return rows
        .map((row) {
          return RecentCoachItem(
            id: row['id'] as String? ?? '',
            dateLabel: _dateLabel(row['date'] as String?),
            word: _coachDisplayWord(row),
            sentence: _cleanDisplayText(row['user_sentence'] as String? ?? ''),
            rating: _coachRating(row),
          );
        })
        .toList(growable: false);
  }

  String _cleanDisplayText(String value) {
    return value
        .replaceAll('â€œ', '"')
        .replaceAll('â€', '"')
        .replaceAll('â€˜', "'")
        .replaceAll('â€™', "'")
        .replaceAll('Â·', '·')
        .trim();
  }

  String _coachDisplayWord(Map<String, Object?> row) {
    final termId = _cleanDisplayText(row['term_id'] as String? ?? '');
    if (termId.isNotEmpty) {
      return termId;
    }

    final definition = _cleanDisplayText(row['definition'] as String? ?? '');
    if (definition.isNotEmpty) {
      return definition;
    }

    return 'Unknown term';
  }

  int _coachRating(Map<String, Object?> row) {
    final responseJson = row['response_json'] as String?;
    if (responseJson != null && responseJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(responseJson) as Map<String, dynamic>;
        final suggestions = decoded['suggestion'];
        final nonEmptyFeedbackCount =
            [
                  decoded['grammar'],
                  decoded['vocabulary'],
                  decoded['naturalness'],
                  if (suggestions is List && suggestions.isNotEmpty)
                    suggestions,
                ]
                .where(
                  (value) =>
                      value != null && value.toString().trim().isNotEmpty,
                )
                .length;
        return nonEmptyFeedbackCount.clamp(1, 5).toInt();
      } catch (_) {
        return 1;
      }
    }

    const fields = [
      'grammar_feedback',
      'vocabulary_feedback',
      'naturalness_feedback',
      'suggestion_feedback',
    ];
    final nonEmptyFeedbackCount = fields
        .where((field) => (row[field] as String? ?? '').trim().isNotEmpty)
        .length;
    return nonEmptyFeedbackCount.clamp(1, 5).toInt();
  }

  String _levelName(String code) {
    switch (code.toLowerCase()) {
      case 'b1':
        return 'Intermediate';
      case 'b2':
        return 'Upper Intermediate';
      case 'c1&c2':
      case 'c1 & c2':
        return 'Advanced';
      default:
        return '';
    }
  }

  String _dateLabel(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(value);
    if (date == null) {
      return value;
    }

    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final daysAgo = currentDate.difference(targetDate).inDays;

    if (daysAgo == 0) {
      return 'Today';
    }
    if (daysAgo == 1) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  ({String id, String label}) _decodeExamUnit(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        id: map['id'] as String? ?? raw,
        label: map['label'] as String? ?? raw,
      );
    } catch (_) {
      return (id: raw, label: raw);
    }
  }
}

class _ExamStats {
  const _ExamStats({
    required this.examCount,
    required this.averageExamScore,
    required this.recentExams,
  });

  final int examCount;
  final double averageExamScore;
  final List<RecentExamItem> recentExams;
}
