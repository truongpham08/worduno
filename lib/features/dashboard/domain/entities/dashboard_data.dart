class DashboardData {
  const DashboardData({
    required this.overallProgress,
    required this.totalTerms,
    required this.knownTerms,
    required this.learnedWordsCount,
    required this.learningWordsCount,
    required this.starredWordsCount,
    required this.levelProgressList,
    required this.examCount,
    required this.averageExamScore,
    required this.strongestUnits,
    required this.weakestUnits,
    required this.recentExams,
    required this.recentCoachFeedback,
  });

  final double overallProgress;
  final int totalTerms;
  final int knownTerms;
  final int learnedWordsCount;
  final int learningWordsCount;
  final int starredWordsCount;
  final List<LevelProgressData> levelProgressList;
  final int examCount;
  final double averageExamScore;
  final List<UnitProgressData> strongestUnits;
  final List<UnitProgressData> weakestUnits;
  final List<RecentExamItem> recentExams;
  final List<RecentCoachItem> recentCoachFeedback;
}

class LevelProgressData {
  const LevelProgressData({
    required this.levelCode,
    required this.levelName,
    required this.progress,
    required this.knownTerms,
    required this.totalTerms,
  });

  final String levelCode;
  final String levelName;
  final double progress;
  final int knownTerms;
  final int totalTerms;
}

class UnitProgressData {
  const UnitProgressData({
    required this.unitId,
    required this.unitName,
    required this.progress,
  });

  final String unitId;
  final String unitName;
  final double progress;
}

class RecentExamItem {
  const RecentExamItem({
    required this.id,
    required this.dateLabel,
    required this.unitId,
    required this.unitName,
    required this.score,
    required this.questionCount,
  });

  final String id;
  final String dateLabel;
  final String unitId;
  final String unitName;
  final double score;
  final int questionCount;
}

class RecentCoachItem {
  const RecentCoachItem({
    required this.id,
    required this.dateLabel,
    required this.word,
    required this.sentence,
    required this.rating,
  });

  final String id;
  final String dateLabel;
  final String word;
  final String sentence;
  final int rating;
}
