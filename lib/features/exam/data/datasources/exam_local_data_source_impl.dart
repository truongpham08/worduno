import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/exam_history.dart';
import '../../domain/entities/exam_question_type.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/graded_answer.dart';
import 'i_exam_local_data_source.dart';

class ExamLocalDataSourceImpl implements IExamLocalDataSource {
  ExamLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveExamResult(ExamResult result) async {
    final db = await _database.database;
    final unitPayload = jsonEncode({
      'id': result.paper.config.unitId,
      'label': result.paper.config.unitLabel,
    });

    await db.transaction((txn) async {
      await txn.insert('exam_history', {
        'id': result.examId,
        'date': result.completedAt.toIso8601String(),
        'unit_id': unitPayload,
        'score': result.percentage,
      });

      for (final answer in result.answers) {
        await txn.insert('question_history', {
          'exam_id': result.examId,
          'type': answer.question.type.storageKey,
          'question': _encodeQuestion(answer.question),
          'user_answer': answer.userAnswer,
          'correct_answer': answer.correctAnswerText,
          'is_correct': answer.isCorrect ? 1 : 0,
        });
      }
    });
  }

  @override
  Future<List<ExamHistorySummary>> getExamHistory() async {
    final db = await _database.database;
    final rows = await db.query(
      'exam_history',
      orderBy: 'date DESC',
    );

    final summaries = <ExamHistorySummary>[];
    for (final row in rows) {
      final examId = row['id']! as String;
      final countRow = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM question_history WHERE exam_id = ?',
        [examId],
      );
      final count = (countRow.first['count'] as int?) ?? 0;
      final unit = _decodeUnit(row['unit_id']! as String);

      summaries.add(
        ExamHistorySummary(
          id: examId,
          date: DateTime.parse(row['date']! as String),
          unitId: unit.id,
          unitLabel: unit.label,
          score: (row['score']! as num).toDouble(),
          questionCount: count,
        ),
      );
    }
    return summaries;
  }

  @override
  Future<ExamHistoryDetail?> getExamDetail(String examId) async {
    final db = await _database.database;
    final rows = await db.query(
      'exam_history',
      where: 'id = ?',
      whereArgs: [examId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final unit = _decodeUnit(row['unit_id']! as String);
    final questionRows = await db.query(
      'question_history',
      where: 'exam_id = ?',
      whereArgs: [examId],
    );

    final questions = questionRows.map((q) {
      final type = ExamQuestionType.fromStorageKey(q['type']! as String);
      final userAnswer = q['user_answer']! as String;
      final correctAnswer = q['correct_answer']! as String;
      return ExamHistoryQuestion(
        type: type ?? ExamQuestionType.termToDefinition,
        question: q['question']! as String,
        userAnswer: userAnswer,
        correctAnswer: correctAnswer,
        isCorrect: (q['is_correct'] as int? ?? 0) == 1,
      );
    }).toList();

    return ExamHistoryDetail(
      id: examId,
      date: DateTime.parse(row['date']! as String),
      unitId: unit.id,
      unitLabel: unit.label,
      score: (row['score']! as num).toDouble(),
      questionCount: questions.length,
      questions: questions,
    );
  }

  @override
  Future<void> deleteExam(String examId) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        'question_history',
        where: 'exam_id = ?',
        whereArgs: [examId],
      );
      await txn.delete(
        'exam_history',
        where: 'id = ?',
        whereArgs: [examId],
      );
    });
  }

  String _encodeQuestion(dynamic question) {
    return question.displayStem;
  }

  ({String id, String label}) _decodeUnit(String raw) {
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

extension on GradedAnswer {
  String get correctAnswerText {
    final question = this.question;
    if (question.type == ExamQuestionType.matching &&
        question.matchingPairs != null) {
      return question.matchingPairs!
          .map((pair) => '${pair.termText} → ${pair.definition}')
          .join('\n');
    }
    return question.correctAnswer ?? question.definition;
  }
}
