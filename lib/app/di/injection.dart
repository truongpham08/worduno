import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../core/network/dio_client.dart';
import '../../features/coach/application/services/coach_service_impl.dart';
import '../../features/coach/application/services/i_coach_service.dart';
import '../../features/coach/data/datasources/coach_ai_data_source_impl.dart';
import '../../features/coach/data/datasources/coach_history_local_data_source_impl.dart';
import '../../features/coach/data/datasources/i_coach_ai_data_source.dart';
import '../../features/coach/data/datasources/i_coach_history_local_data_source.dart';
import '../../features/coach/data/repositories/coach_repository_impl.dart';
import '../../features/coach/domain/repositories/i_coach_repository.dart';
import '../../features/dashboard/application/services/dashboard_service_impl.dart';
import '../../features/dashboard/application/services/i_dashboard_service.dart';
import '../../features/dashboard/data/datasources/dashboard_local_data_source_impl.dart';
import '../../features/dashboard/data/datasources/i_dashboard_local_data_source.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/i_dashboard_repository.dart';
import '../../features/exam/application/services/exam_grader.dart';
import '../../features/exam/application/services/exam_question_generator.dart';
import '../../features/exam/application/services/exam_service_impl.dart';
import '../../features/exam/application/services/i_exam_service.dart';
import '../../features/exam/data/datasources/exam_ai_data_source_impl.dart';
import '../../features/exam/data/datasources/exam_local_data_source_impl.dart';
import '../../features/exam/data/datasources/i_exam_ai_data_source.dart';
import '../../features/exam/data/datasources/i_exam_local_data_source.dart';
import '../../features/exam/data/repositories/exam_repository_impl.dart';
import '../../features/exam/domain/repositories/i_exam_repository.dart';
import '../../features/home/application/services/home_service_impl.dart';
import '../../features/home/application/services/i_home_service.dart';
import '../../features/learning/application/services/i_learn_service.dart';
import '../../features/learning/application/services/learn_service_impl.dart';
import '../../features/learning/data/repositories/learn_repository_impl.dart';
import '../../features/learning/domain/repositories/i_learn_repository.dart';
import '../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../shared/vocabulary/application/services/vocabulary_service_impl.dart';
import '../../shared/vocabulary/data/datasources/i_vocabulary_remote_data_source.dart';
import '../../shared/vocabulary/data/datasources/vocabulary_remote_data_source_impl.dart';
import '../../shared/vocabulary/data/repositories/vocabulary_repository_impl.dart';
import '../../shared/vocabulary/domain/repositories/i_vocabulary_repository.dart';
import '../../shared/word_state/application/services/i_word_state_service.dart';
import '../../shared/word_state/application/services/word_state_service_impl.dart';
import '../../shared/word_state/application/services/word_state_store.dart';
import '../../shared/word_state/data/datasources/i_word_state_local_data_source.dart';
import '../../shared/word_state/data/datasources/word_state_local_data_source_impl.dart';
import '../../shared/word_state/data/repositories/word_state_repository_impl.dart';
import '../../shared/word_state/domain/repositories/i_word_state_repository.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  if (getIt.isRegistered<Dio>()) {
    return;
  }

  getIt.registerLazySingleton<Dio>(DioClient.create);
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);

  getIt.registerLazySingleton<IVocabularyRemoteDataSource>(
    () => VocabularyRemoteDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<IVocabularyRepository>(
    () => VocabularyRepositoryImpl(getIt<IVocabularyRemoteDataSource>()),
  );
  getIt.registerLazySingleton<IVocabularyService>(
    () => VocabularyServiceImpl(getIt<IVocabularyRepository>()),
  );

  getIt.registerLazySingleton<IWordStateLocalDataSource>(
    () => WordStateLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<IWordStateRepository>(
    () => WordStateRepositoryImpl(getIt<IWordStateLocalDataSource>()),
  );
  getIt.registerLazySingleton<IWordStateService>(
    () => WordStateServiceImpl(getIt<IWordStateRepository>()),
  );
  getIt.registerLazySingleton<WordStateStore>(
    () => WordStateStore(getIt<IWordStateRepository>()),
  );

  getIt.registerLazySingleton<IHomeService>(
    () => HomeServiceImpl(
      getIt<IVocabularyService>(),
      getIt<IWordStateService>(),
    ),
  );
  getIt.registerLazySingleton<ILearnRepository>(
    () => LearnRepositoryImpl(
      getIt<IVocabularyService>(),
      getIt<WordStateStore>(),
    ),
  );
  getIt.registerLazySingleton<ILearnService>(
    () => LearnServiceImpl(getIt<ILearnRepository>(), getIt<WordStateStore>()),
  );
  getIt.registerLazySingleton<IExamLocalDataSource>(
    () => ExamLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<IExamRepository>(
    () => ExamRepositoryImpl(getIt<IExamLocalDataSource>()),
  );
  getIt.registerLazySingleton<IExamAiDataSource>(
    () => ExamAiDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ExamQuestionGenerator>(
    () => ExamQuestionGenerator(getIt<IExamAiDataSource>()),
  );
  getIt.registerLazySingleton<ExamGrader>(
    () => ExamGrader(getIt<IExamAiDataSource>()),
  );
  getIt.registerLazySingleton<IExamService>(
    () => ExamServiceImpl(
      getIt<IVocabularyService>(),
      getIt<WordStateStore>(),
      getIt<IExamRepository>(),
      getIt<ExamQuestionGenerator>(),
      getIt<ExamGrader>(),
    ),
  );
  getIt.registerLazySingleton<IDashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<IDashboardRepository>(
    () => DashboardRepositoryImpl(
      getIt<IVocabularyService>(),
      getIt<IWordStateService>(),
      getIt<IDashboardLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<IDashboardService>(
    () => DashboardServiceImpl(getIt<IDashboardRepository>()),
  );

  getIt.registerLazySingleton<ICoachAiDataSource>(
    () => CoachAiDataSourceImpl(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ICoachHistoryLocalDataSource>(
    () => CoachHistoryLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<ICoachRepository>(
    () => CoachRepositoryImpl(
      getIt<IVocabularyService>(),
      getIt<WordStateStore>(),
      getIt<ICoachAiDataSource>(),
      getIt<ICoachHistoryLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ICoachService>(
    () => CoachServiceImpl(getIt<ICoachRepository>()),
  );
}
