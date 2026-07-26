import '../database/database_helper.dart';
import '../models/question.dart';

class QuestionRepository {
  final DatabaseHelper _db;

  QuestionRepository(this._db);

  Future<String> insertQuestion(Question question) {
    return _db.insertQuestion(question);
  }

  Future<List<Question>> getQuestionsByDeck(String deckId) {
    return _db.getQuestionsByDeck(deckId);
  }

  Future<List<Question>> getAllQuestions() {
    return _db.getAllQuestions();
  }

  Future<List<Question>> getRandomQuestions(int count) {
    return _db.getRandomQuestions(count);
  }

  Future<void> updateQuestion(Question question) {
    return _db.updateQuestion(question);
  }

  Future<void> updateQuestions(List<Question> questions) {
    return _db.updateQuestions(questions);
  }
}
