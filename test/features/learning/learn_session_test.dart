import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/features/learning/domain/entities/learn_session.dart';
import 'package:worduno/shared/vocabulary/domain/entities/term.dart';
import 'package:worduno/shared/word_state/domain/entities/word_status.dart';

List<Term> _terms(int count) => [
      for (var i = 0; i < count; i++)
        Term(id: 't$i', text: 'term$i', definition: 'def$i'),
    ];

void main() {
  group('LearnSession (spec §6 session rule)', () {
    test('starts with all not-known terms in the queue', () {
      final session = LearnSession.fromTerms(
        terms: _terms(3),
        initialStatuses: const {},
      );

      expect(session.totalCards, 3);
      expect(session.currentTerm?.id, 't0');
      expect(session.isCompleted, isFalse);
      expect(session.knownCount, 0);
    });

    test('already-known terms are excluded from the queue', () {
      final session = LearnSession.fromTerms(
        terms: _terms(3),
        initialStatuses: const {'t0': WordStatus.know},
      );

      // t0 is done, so the queue starts at t1.
      expect(session.currentTerm?.id, 't1');
      expect(session.knownCount, 1);
    });

    test('Learning terms reappear after the first round, Known ones do not',
        () {
      final session = LearnSession.fromTerms(
        terms: _terms(2),
        initialStatuses: const {},
      );

      // Round 1: t0 -> Learning, t1 -> Know.
      expect(session.currentTerm?.id, 't0');
      session.markLearning();
      expect(session.currentTerm?.id, 't1');
      session.markKnow();

      // Round 1 finished. t0 (Learning) must reappear; t1 (Know) must not.
      expect(session.isCompleted, isFalse);
      expect(session.currentTerm?.id, 't0');
    });

    test('session only completes when every term is Known', () {
      final session = LearnSession.fromTerms(
        terms: _terms(2),
        initialStatuses: const {},
      );

      session.markLearning(); // t0 requeued
      session.markKnow(); // t1 known
      expect(session.isCompleted, isFalse);

      session.markKnow(); // t0 known on round 2
      expect(session.isCompleted, isTrue);
      expect(session.knownCount, 2);
      expect(session.progress, 1.0);
    });

    test('undo reverts the queue and the term status', () {
      final session = LearnSession.fromTerms(
        terms: _terms(2),
        initialStatuses: const {},
      );

      session.markKnow(); // t0 -> Know
      expect(session.knownCount, 1);
      expect(session.currentTerm?.id, 't1');

      final restore = session.undo();
      expect(restore, isNotNull);
      expect(restore!.termId, 't0');
      expect(restore.status, WordStatus.newWord);
      expect(session.currentTerm?.id, 't0');
      expect(session.knownCount, 0);
      expect(session.canUndo, isFalse);
    });

    test('startTermId rotates the queue to begin at that term', () {
      final session = LearnSession.fromTerms(
        terms: _terms(4),
        initialStatuses: const {},
        startTermId: 't2',
      );

      expect(session.currentTerm?.id, 't2');
    });
  });
}
