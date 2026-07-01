import '../entities/exam_history.dart';
import '../entities/exam_result.dart';

abstract class IExamRepository {
  Future<void> saveExamResult(ExamResult result);

  Future<List<ExamHistorySummary>> getExamHistory();

  Future<ExamHistoryDetail?> getExamDetail(String examId);

  Future<void> deleteExam(String examId);
}
