import '../../domain/entities/exam_history.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/repositories/i_exam_repository.dart';
import '../datasources/i_exam_local_data_source.dart';

class ExamRepositoryImpl implements IExamRepository {
  ExamRepositoryImpl(this._localDataSource);

  final IExamLocalDataSource _localDataSource;

  @override
  Future<void> saveExamResult(ExamResult result) {
    return _localDataSource.saveExamResult(result);
  }

  @override
  Future<List<ExamHistorySummary>> getExamHistory() {
    return _localDataSource.getExamHistory();
  }

  @override
  Future<ExamHistoryDetail?> getExamDetail(String examId) {
    return _localDataSource.getExamDetail(examId);
  }

  @override
  Future<void> deleteExam(String examId) {
    return _localDataSource.deleteExam(examId);
  }
}
