import '../../domain/entities/exam_config.dart';
import '../../domain/entities/exam_history.dart';
import '../../domain/entities/exam_paper.dart';
import '../../domain/entities/exam_result.dart';

abstract class IExamService {
  ExamPaper? get currentPaper;
  ExamResult? get currentResult;
  bool get isGenerating;

  Future<ExamPaper> prepareExam(ExamConfig config);

  Future<ExamResult> submitExam(Map<String, String?> answersByQuestionId);

  void clearSession();

  Future<List<ExamHistorySummary>> getHistory();

  Future<ExamHistoryDetail?> getHistoryDetail(String examId);

  Future<void> deleteHistory(String examId);
}
