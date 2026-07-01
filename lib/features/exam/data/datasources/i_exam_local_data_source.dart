import '../../domain/entities/exam_history.dart';
import '../../domain/entities/exam_result.dart';

abstract class IExamLocalDataSource {
  Future<void> saveExamResult(ExamResult result);

  Future<List<ExamHistorySummary>> getExamHistory();

  Future<ExamHistoryDetail?> getExamDetail(String examId);

  Future<void> deleteExam(String examId);
}
