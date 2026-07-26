import '../database/database_helper.dart';
import '../models/knowledge_point.dart';
import '../models/knowledge_point_prerequisite.dart';
import '../models/knowledge_point_source.dart';

class KnowledgePointRepository {
  final DatabaseHelper _db;

  KnowledgePointRepository(this._db);

  Future<String> insertKnowledgePoint(KnowledgePoint point) {
    return _db.insertKnowledgePoint(point);
  }

  Future<List<KnowledgePoint>> getAllKnowledgePoints() {
    return _db.getAllKnowledgePoints();
  }

  Future<KnowledgePoint?> getKnowledgePoint(String id) {
    return _db.getKnowledgePoint(id);
  }

  Future<void> updateKnowledgePoint(KnowledgePoint point) {
    return _db.updateKnowledgePoint(point);
  }

  Future<void> deleteKnowledgePoint(String id) {
    return _db.deleteKnowledgePoint(id);
  }

  Future<void> addKnowledgePointSource(KnowledgePointSource source) {
    return _db.addKnowledgePointSource(source);
  }

  Future<List<KnowledgePointSource>> getKnowledgePointSources(
    String knowledgePointId,
  ) {
    return _db.getKnowledgePointSources(knowledgePointId);
  }

  Future<List<KnowledgePointSource>> getAllKnowledgePointSources() {
    return _db.getAllKnowledgePointSources();
  }

  Future<List<KnowledgePointPrerequisite>> getKnowledgePointPrerequisites() {
    return _db.getKnowledgePointPrerequisites();
  }

  Future<void> replaceKnowledgePointPrerequisites({
    required List<String> scopeKnowledgePointIds,
    required List<KnowledgePointPrerequisite> relations,
  }) {
    return _db.replaceKnowledgePointPrerequisites(
      scopeKnowledgePointIds: scopeKnowledgePointIds,
      relations: relations,
    );
  }
}
