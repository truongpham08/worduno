import 'exam_question_type.dart';

class ExamConfig {
  const ExamConfig({
    required this.levelCode,
    this.unitName,
    required this.unitId,
    required this.unitLabel,
    required this.starOnly,
    required this.questionCount,
    required this.enabledTypes,
  });

  final String levelCode;
  final String? unitName;
  final String unitId;
  final String unitLabel;
  final bool starOnly;
  final int questionCount;
  final Set<ExamQuestionType> enabledTypes;

  ExamConfig copyWith({
    String? levelCode,
    String? unitName,
    String? unitId,
    String? unitLabel,
    bool? starOnly,
    int? questionCount,
    Set<ExamQuestionType>? enabledTypes,
  }) {
    return ExamConfig(
      levelCode: levelCode ?? this.levelCode,
      unitName: unitName ?? this.unitName,
      unitId: unitId ?? this.unitId,
      unitLabel: unitLabel ?? this.unitLabel,
      starOnly: starOnly ?? this.starOnly,
      questionCount: questionCount ?? this.questionCount,
      enabledTypes: enabledTypes ?? this.enabledTypes,
    );
  }

  static const questionCountOptions = [10, 20, 50, 100];
}
