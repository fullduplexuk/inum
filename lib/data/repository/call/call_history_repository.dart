import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:inum/domain/models/call/call_record.dart';
import 'package:inum/domain/models/call/voicemail_model.dart';

/// Interface for call history persistence.
abstract class ICallHistoryRepository {
  Future<void> init();
  Future<void> saveCallRecord(CallRecord record);
  Future<CallRecord?> getCallRecord(String id);
  Future<List<CallRecord>> getCallHistory({int page = 0, int perPage = 30});
  Future<List<CallRecord>> getMissedCalls({int page = 0, int perPage = 30});
  Future<List<CallRecord>> getIncomingCalls({int page = 0, int perPage = 30});
  Future<List<CallRecord>> getOutgoingCalls({int page = 0, int perPage = 30});
  Future<int> getMissedCallCount();
  Future<void> deleteCallRecord(String id);
  Future<void> clearMissedCallBadge();

  // Voicemail
  Future<void> saveVoicemail(VoicemailModel vm);
  Future<List<VoicemailModel>> getVoicemails({int page = 0, int perPage = 30});
  Future<void> markVoicemailRead(String id);
  Future<void> deleteVoicemail(String id);
  Future<int> getUnreadVoicemailCount();
}

class CallHistoryRepository implements ICallHistoryRepository {
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'inum_call_history.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE call_records (
            id TEXT PRIMARY KEY,
            room_id TEXT,
            call_type TEXT,
            initiated_by TEXT,
            initiated_by_username TEXT,
            target_user_id TEXT,
            target_username TEXT,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_secs INTEGER DEFAULT 0,
            status TEXT DEFAULT 'completed',
            direction TEXT DEFAULT 'outgoing',
            recording_url TEXT,
            transcript_url TEXT,
            badge_cleared INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE voicemails (
            id TEXT PRIMARY KEY,
            from_user_id TEXT,
            from_username TEXT,
            audio_url TEXT,
            transcript TEXT,
            duration_secs INTEGER DEFAULT 0,
            is_read INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_call_records_started ON call_records(started_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_voicemails_created ON voicemails(created_at DESC)',
        );
      },
    );
  }

  Database get _database {
    if (_db == null) throw StateError('CallHistoryRepository not initialized');
    return _db!;
  }

  @override
  Future<void> saveCallRecord(CallRecord record) async {
    await _database.insert(
      'call_records',
      {...record.toMap(), 'badge_cleared': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<CallRecord?> getCallRecord(String id) async {
    final rows = await _database.query(
      'call_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CallRecord.fromMap(rows.first);
  }

  @override
  Future<List<CallRecord>> getCallHistory({int page = 0, int perPage = 30}) async {
    final rows = await _database.query(
      'call_records',
      orderBy: 'started_at DESC',
      limit: perPage,
      offset: page * perPage,
    );
    return rows.map(CallRecord.fromMap).toList();
  }

  @override
  Future<List<CallRecord>> getMissedCalls({int page = 0, int perPage = 30}) async {
    final rows = await _database.query(
      'call_records',
      where: 'status = ?',
      whereArgs: ['missed'],
      orderBy: 'started_at DESC',
      limit: perPage,
      offset: page * perPage,
    );
    return rows.map(CallRecord.fromMap).toList();
  }

  @override
  Future<List<CallRecord>> getIncomingCalls({int page = 0, int perPage = 30}) async {
    final rows = await _database.query(
      'call_records',
      where: 'direction = ?',
      whereArgs: ['incoming'],
      orderBy: 'started_at DESC',
      limit: perPage,
      offset: page * perPage,
    );
    return rows.map(CallRecord.fromMap).toList();
  }

  @override
  Future<List<CallRecord>> getOutgoingCalls({int page = 0, int perPage = 30}) async {
    final rows = await _database.query(
      'call_records',
      where: 'direction = ?',
      whereArgs: ['outgoing'],
      orderBy: 'started_at DESC',
      limit: perPage,
      offset: page * perPage,
    );
    return rows.map(CallRecord.fromMap).toList();
  }

  @override
  Future<int> getMissedCallCount() async {
    final result = await _database.rawQuery(
      "SELECT COUNT(*) as cnt FROM call_records WHERE status = 'missed' AND badge_cleared = 0",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> clearMissedCallBadge() async {
    await _database.update(
      'call_records',
      {'badge_cleared': 1},
      where: 'status = ? AND badge_cleared = ?',
      whereArgs: ['missed', 0],
    );
  }

  @override
  Future<void> deleteCallRecord(String id) async {
    await _database.delete('call_records', where: 'id = ?', whereArgs: [id]);
  }

  // --- Voicemail ---

  @override
  Future<void> saveVoicemail(VoicemailModel vm) async {
    await _database.insert(
      'voicemails',
      vm.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<VoicemailModel>> getVoicemails({int page = 0, int perPage = 30}) async {
    final rows = await _database.query(
      'voicemails',
      orderBy: 'created_at DESC',
      limit: perPage,
      offset: page * perPage,
    );
    return rows.map(VoicemailModel.fromMap).toList();
  }

  @override
  Future<void> markVoicemailRead(String id) async {
    await _database.update(
      'voicemails',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteVoicemail(String id) async {
    await _database.delete('voicemails', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> getUnreadVoicemailCount() async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) as cnt FROM voicemails WHERE is_read = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
