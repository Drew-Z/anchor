import '../database/database_helper.dart';
import '../models/study_record.dart';

class StudyRecordRepository {
  final DatabaseHelper _db;

  StudyRecordRepository(this._db);

  Future<void> upsertStudyRecord(StudyRecord record) {
    return _db.upsertStudyRecord(record);
  }

  Future<StudyRecord?> getStudyRecord(String deckId) {
    return _db.getStudyRecord(deckId);
  }
}
