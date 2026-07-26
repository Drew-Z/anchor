import '../database/database_helper.dart';
import '../models/source.dart';

class SourceRepository {
  final DatabaseHelper _db;

  SourceRepository(this._db);

  Future<String> insertSource(Source source) {
    return _db.insertSource(source);
  }

  Future<List<Source>> getAllSources() {
    return _db.getAllSources();
  }

  Future<Source?> getSource(String id) {
    return _db.getSource(id);
  }

  Future<void> updateSource(Source source) {
    return _db.updateSource(source);
  }

  Future<void> deleteSource(String id) {
    return _db.deleteSource(id);
  }
}
