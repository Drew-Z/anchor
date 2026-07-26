import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/deck.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('question bulk verification database', () {
    late DatabaseHelper databaseHelper;

    setUp(() {
      databaseHelper = DatabaseHelper.forTesting(
        databaseFactory: databaseFactoryFfi,
      );
    });

    tearDown(() => databaseHelper.close());

    test('bulk database update rolls back when any question is missing',
        () async {
      await _seedDatabase(databaseHelper);
      final questions = await databaseHelper.getQuestionsByDeck('deck-1');
      final readable = questions.singleWhere(
        (question) => question.id == 'question-readable',
      );
      final missingRow = readable.copyWith(id: 'question-does-not-exist');

      await expectLater(
        databaseHelper.updateQuestions([
          readable.copyWith(sourceStatus: SourceStatus.verified),
          missingRow.copyWith(sourceStatus: SourceStatus.verified),
        ]),
        throwsA(isA<StateError>()),
      );

      final reloaded = (await databaseHelper.getQuestionsByDeck('deck-1'))
          .singleWhere((question) => question.id == readable.id);
      expect(reloaded.sourceStatus, SourceStatus.pending);
    });
  });
}

Future<void> _seedDatabase(DatabaseHelper databaseHelper) async {
  final now = DateTime(2026, 7, 17);
  await databaseHelper.insertSource(
    Source(
      id: 'source-1',
      title: 'Project source',
      type: SourceType.project,
      contentHash: 'source-hash',
      trustLevel: SourceTrustLevel.sourceCode,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await databaseHelper.insertSourceChunk(
    SourceChunk(
      id: 'chunk-readable',
      sourceId: 'source-1',
      chunkIndex: 0,
      content: 'Readable project evidence',
      locator: 'lib/app.dart:1-10',
      contentHash: 'chunk-hash',
      createdAt: now,
    ),
  );
  await databaseHelper.insertDeck(
    Deck(
      id: 'deck-1',
      title: 'Project interview',
      questionCount: 2,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await databaseHelper.insertQuestion(
    Question(
      id: 'question-readable',
      deckId: 'deck-1',
      type: QuestionType.fillBlank,
      content: 'Readable question',
      answer: 'answer',
      sourceStatus: SourceStatus.pending,
      citationIds: const ['chunk-readable', 'chunk-missing'],
    ),
  );
  await databaseHelper.insertQuestion(
    Question(
      id: 'question-missing',
      deckId: 'deck-1',
      type: QuestionType.fillBlank,
      content: 'Missing citation question',
      answer: 'answer',
      sourceStatus: SourceStatus.pending,
      citationIds: const ['chunk-missing'],
    ),
  );
}
