import '../database/database_helper.dart';
import '../models/source_chunk.dart';

class SourceChunkRepository {
  final DatabaseHelper _db;

  SourceChunkRepository(this._db);

  Future<String> insertSourceChunk(SourceChunk chunk) {
    return _db.insertSourceChunk(chunk);
  }

  Future<List<SourceChunk>> getSourceChunks(String sourceId) {
    return _db.getSourceChunks(sourceId);
  }

  Future<SourceChunk?> getSourceChunk(String id) {
    return _db.getSourceChunk(id);
  }

  Future<void> updateSourceChunk(SourceChunk chunk) {
    return _db.updateSourceChunk(chunk);
  }

  Future<void> deleteSourceChunk(String id) {
    return _db.deleteSourceChunk(id);
  }
}
