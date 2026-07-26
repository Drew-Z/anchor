import '../database/database_helper.dart';
import '../models/deck.dart';

class DeckRepository {
  final DatabaseHelper _db;

  DeckRepository(this._db);

  Future<String> insertDeck(Deck deck) {
    return _db.insertDeck(deck);
  }

  Future<List<Deck>> getAllDecks() {
    return _db.getAllDecks();
  }

  Future<Deck?> getDeck(String id) {
    return _db.getDeck(id);
  }

  Future<void> updateDeck(Deck deck) {
    return _db.updateDeck(deck);
  }

  Future<void> deleteDeck(String id) {
    return _db.deleteDeck(id);
  }
}
