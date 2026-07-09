import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/core/database/app_database.dart';
import 'package:worduno/features/exam/application/services/exam_grader.dart';
import 'package:worduno/features/exam/application/services/exam_question_generator.dart';
import 'package:worduno/features/exam/application/services/exam_service_impl.dart';
import 'package:worduno/features/exam/data/datasources/exam_local_data_source_impl.dart';
import 'package:worduno/features/exam/data/repositories/exam_repository_impl.dart';
import 'package:worduno/features/exam/domain/entities/exam_config.dart';
import 'package:worduno/features/exam/domain/entities/exam_question.dart';
import 'package:worduno/features/exam/domain/entities/exam_question_type.dart';
import 'package:worduno/features/exam/domain/entities/exam_source_term.dart';
import 'package:worduno/features/exam/presentation/viewmodels/exam_view_models.dart';
import 'package:worduno/shared/word_state/application/services/word_state_store.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_database.dart';

void main() {
  group('ExamGrader extended', () {
    late ExamGrader grader;

    setUp(() {
      grader = ExamGrader(StubExamAiDataSource());
    });

    test('grades matching JSON correctly', () async {
      const question = ExamQuestion(
        id: 'q_match',
        type: ExamQuestionType.matching,
        prompt: 'Matching',
        termId: 't1',
        termText: 'happy',
        definition: 'joy',
        matchingPairs: [
          MatchingPair(termId: 't1', termText: 'happy', definition: 'joy'),
          MatchingPair(termId: 't2', termText: 'sad', definition: 'unhappy'),
        ],
      );

      final correct = await grader.grade(
        question: question,
        rawAnswer: '{"t1":"joy","t2":"unhappy"}',
      );
      final wrong = await grader.grade(
        question: question,
        rawAnswer: '{"t1":"wrong","t2":"unhappy"}',
      );

      expect(correct.isCorrect, isTrue);
      expect(wrong.isCorrect, isFalse);
    });

    test('invalid matching JSON is graded wrong', () async {
      const question = ExamQuestion(
        id: 'q_match',
        type: ExamQuestionType.matching,
        prompt: 'Matching',
        termId: 't1',
        termText: 'happy',
        definition: 'joy',
        matchingPairs: [
          MatchingPair(termId: 't1', termText: 'happy', definition: 'joy'),
        ],
      );

      final result = await grader.grade(
        question: question,
        rawAnswer: 'not-json',
      );
      expect(result.isCorrect, isFalse);
    });

    test('sentence writing fails on empty answer', () async {
      const question = ExamQuestion(
        id: 'q_sw',
        type: ExamQuestionType.sentenceWritingAi,
        prompt: 'Write',
        termId: 't1',
        termText: 'happy',
        definition: 'joy',
      );

      final result = await grader.grade(question: question, rawAnswer: '  ');
      expect(result.isCorrect, isFalse);
      expect(result.score, 0);
    });

    test('sentence writing uses AI fallback when service fails', () async {
      final failingGrader = ExamGrader(
        StubExamAiDataSource(throwOnEvaluate: true),
      );
      const question = ExamQuestion(
        id: 'q_sw',
        type: ExamQuestionType.sentenceWritingAi,
        prompt: 'Write',
        termId: 't1',
        termText: 'happy',
        definition: 'joy',
      );

      final withWord = await failingGrader.grade(
        question: question,
        rawAnswer: 'I am happy today.',
      );
      final withoutWord = await failingGrader.grade(
        question: question,
        rawAnswer: 'Good day.',
      );

      expect(withWord.isCorrect, isTrue);
      expect(withoutWord.isCorrect, isFalse);
    });

    test('sentence writing fails when AI score below threshold', () async {
      final lowScoreGrader = ExamGrader(
        StubExamAiDataSource(evaluateScore: 5),
      );
      const question = ExamQuestion(
        id: 'q_sw',
        type: ExamQuestionType.sentenceWritingAi,
        prompt: 'Write',
        termId: 't1',
        termText: 'happy',
        definition: 'joy',
      );

      final result = await lowScoreGrader.grade(
        question: question,
        rawAnswer: 'I feel happy.',
      );
      expect(result.isCorrect, isFalse);
    });

    test('english to vietnamese splits synonyms with or/separator', () async {
      const question = ExamQuestion(
        id: 'q_vi',
        type: ExamQuestionType.englishToVietnamese,
        prompt: 'work out',
        termId: 't1',
        termText: 'work out',
        definition: 'tập thể dục; rèn luyện',
        correctAnswer: 'tập thể dục; rèn luyện',
      );

      final result = await grader.grade(
        question: question,
        rawAnswer: 'rèn luyện',
      );
      expect(result.isCorrect, isTrue);
    });
  });

  group('ExamQuestionGenerator', () {
    List<ExamSourceTerm> pool(int count) => [
          for (var i = 0; i < count; i++)
            ExamSourceTerm(
              unitId: 'b1-0',
              unitName: 'Travel',
              termId: 't$i',
              text: 'word$i',
              definition: 'meaning$i',
            ),
        ];

    test('throws when no question types enabled', () async {
      final generator = ExamQuestionGenerator(
        StubExamAiDataSource(),
        random: Random(1),
      );
      const config = ExamConfig(
        levelCode: 'b1',
        unitId: 'b1-0',
        unitLabel: 'Travel',
        starOnly: false,
        questionCount: 10,
        enabledTypes: {},
      );

      await expectLater(
        generator.generate(config: config, pool: pool(15)),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when not enough terms in pool', () async {
      final generator = ExamQuestionGenerator(
        StubExamAiDataSource(),
        random: Random(1),
      );
      const config = ExamConfig(
        levelCode: 'b1',
        unitId: 'b1-0',
        unitLabel: 'Travel',
        starOnly: false,
        questionCount: 10,
        enabledTypes: {ExamQuestionType.matching},
      );

      await expectLater(
        generator.generate(config: config, pool: pool(5)),
        throwsA(isA<StateError>()),
      );
    });

    test('generates requested number of questions', () async {
      final generator = ExamQuestionGenerator(
        StubExamAiDataSource(),
        random: Random(42),
      );
      const config = ExamConfig(
        levelCode: 'b1',
        unitId: 'b1-0',
        unitLabel: 'Travel',
        starOnly: false,
        questionCount: 5,
        enabledTypes: {ExamQuestionType.termToDefinition},
      );

      final paper = await generator.generate(config: config, pool: pool(10));
      expect(paper.questions.length, 5);
      expect(paper.questions.every((q) => q.options?.length == 4), isTrue);
    });

    test('cloze AI falls back when service fails', () async {
      final generator = ExamQuestionGenerator(
        StubExamAiDataSource(throwOnCloze: true),
        random: Random(7),
      );
      const config = ExamConfig(
        levelCode: 'b1',
        unitId: 'b1-0',
        unitLabel: 'Travel',
        starOnly: false,
        questionCount: 1,
        enabledTypes: {ExamQuestionType.clozeAi},
      );

      final paper = await generator.generate(config: config, pool: pool(5));
      expect(paper.questions.single.type, ExamQuestionType.clozeAi);
      expect(paper.questions.single.options, isNotEmpty);
    });
  });

  group('ExamServiceImpl', () {
    initTestDatabase();

    late DirectoryHolder holder;
    AppDatabase? db;

    setUp(() {
      holder = DirectoryHolder(createTempDbPath());
      db = openTestDatabase(holder.dbPath);
    });

    tearDown(() async {
      await db?.close();
      holder.dispose();
    });

    ExamServiceImpl buildService({
      FakeVocabularyService? vocab,
      WordStateStore? store,
    }) {
      final wordStore = store ?? wordStateStoreFor(db!);
      final vocabulary = vocab ?? FakeVocabularyService();
      final repository = ExamRepositoryImpl(ExamLocalDataSourceImpl(db!));
      final generator = ExamQuestionGenerator(
        StubExamAiDataSource(),
        random: Random(99),
      );
      final grader = ExamGrader(StubExamAiDataSource());
      return ExamServiceImpl(
        vocabulary,
        wordStore,
        repository,
        generator,
        grader,
      );
    }

    test('starOnly filter excludes non-starred terms', () async {
      final store = wordStateStoreFor(db!);
      await store.toggleStar(unitId: 'b1-0', termId: 'term0');
      await store.toggleStar(unitId: 'b1-0', termId: 'term1');
      await store.toggleStar(unitId: 'b1-0', termId: 'term2');

      final vocab = FakeVocabularyService(
        termsByUnit: {
          'b1|Travel': sampleTerms(count: 6),
        },
      );
      final service = buildService(vocab: vocab, store: store);

      final paper = await service.prepareExam(
        const ExamConfig(
          levelCode: 'b1',
          unitName: 'Travel',
          unitId: 'b1-0',
          unitLabel: 'Travel',
          starOnly: true,
          questionCount: 1,
          enabledTypes: {ExamQuestionType.termToDefinition},
        ),
      );

      expect(
        paper.questions.single.termId,
        anyOf('term0', 'term1', 'term2'),
      );
    });

    test('submitExam without active paper throws', () async {
      final service = buildService();
      await expectLater(
        service.submitExam({}),
        throwsA(isA<StateError>()),
      );
    });

    test('submitExam saves result to history', () async {
      final vocab = FakeVocabularyService(
        termsByUnit: {
          'b1|Travel': sampleTerms(count: 8),
        },
      );
      final service = buildService(vocab: vocab);

      final paper = await service.prepareExam(
        const ExamConfig(
          levelCode: 'b1',
          unitName: 'Travel',
          unitId: 'b1-0',
          unitLabel: 'Travel',
          starOnly: false,
          questionCount: 2,
          enabledTypes: {ExamQuestionType.termToDefinition},
        ),
      );

      final answers = {
        for (final q in paper.questions) q.id: q.correctAnswer,
      };
      final result = await service.submitExam(answers);

      expect(result.correctCount, 2);
      expect(result.percentage, 100);

      final history = await service.getHistory();
      expect(history, isNotEmpty);
    });
  });

  group('ExamConfigViewModel', () {
    test('cannot disable last question type', () async {
      final vm = ExamConfigViewModel(
        initialLevelCode: 'b1',
        vocabularyService: FakeVocabularyService(),
        examService: FakeExamService(),
      );
      await vm.initialize();

      for (final type in ExamQuestionType.values) {
        if (type != ExamQuestionType.termToDefinition) {
          vm.toggleQuestionType(type, false);
        }
      }
      vm.toggleQuestionType(ExamQuestionType.termToDefinition, false);

      expect(vm.enabledTypes, {ExamQuestionType.termToDefinition});
    });

    test('buildConfig reflects starOnly and question count', () async {
      final vm = ExamConfigViewModel(
        initialLevelCode: 'b1',
        vocabularyService: FakeVocabularyService(),
        examService: FakeExamService(),
      );
      await vm.initialize();

      vm.setStarOnly(true);
      vm.setQuestionCount(20);

      final config = vm.buildConfig();
      expect(config.starOnly, isTrue);
      expect(config.questionCount, 20);
    });
  });
}

class DirectoryHolder {
  DirectoryHolder(({Directory tempDir, String dbPath}) record)
      : tempDir = record.tempDir,
        dbPath = record.dbPath;

  final Directory tempDir;
  final String dbPath;

  void dispose() => deleteTempDir(tempDir);
}
