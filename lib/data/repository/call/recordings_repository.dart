import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:inum/domain/models/call/recording_model.dart';

/// Interface for recording metadata persistence.
abstract class IRecordingsRepository {
  Future<void> init();
  Future<List<RecordingModel>> getRecordings({int page = 0, int perPage = 30});
  Future<RecordingModel?> getRecordingForCall(String callId);
  Future<RecordingModel?> getRecording(String id);
  Future<void> saveRecording(RecordingModel model);
  Future<void> deleteRecording(String id);
}

class RecordingsRepository implements IRecordingsRepository {
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'inum_recordings.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recordings (
            id TEXT PRIMARY KEY,
            room_id TEXT,
            call_id TEXT,
            composite_url TEXT,
            individual_tracks TEXT,
            transcript_url TEXT,
            summary_url TEXT,
            duration_secs INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            participants TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_recordings_created ON recordings(created_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_recordings_call_id ON recordings(call_id)',
        );
      },
    );
  }

  Database get _database {
    if (_db == null) throw StateError('RecordingsRepository not initialized');
    return _db!;
  }

  @override
  Future<List<RecordingModel>> getRecordings({
    int page = 0,
    int perPage = 30,
  }) async {
    final rows = await _database.query(
      'recordings',
      orderBy: 'created_at DESC',
      limit: perPage,
      offset: page * perPage,
    );
    return rows.map(RecordingModel.fromMap).toList();
  }

  @override
  Future<RecordingModel?> getRecordingForCall(String callId) async {
    final rows = await _database.query(
      'recordings',
      where: 'call_id = ?',
      whereArgs: [callId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RecordingModel.fromMap(rows.first);
  }

  @override
  Future<RecordingModel?> getRecording(String id) async {
    final rows = await _database.query(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RecordingModel.fromMap(rows.first);
  }

  @override
  Future<void> saveRecording(RecordingModel model) async {
    await _database.insert(
      'recordings',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteRecording(String id) async {
    await _database.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }
}
