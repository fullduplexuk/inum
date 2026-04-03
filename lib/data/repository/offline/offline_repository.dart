import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Basic offline mode: caches channels and recent messages, queues outgoing
/// messages and sends them when connectivity is restored.
class OfflineRepository {
  Database? _db;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;

  /// Callback to send a queued message. Set by the chat layer.
  Future<void> Function(String channelId, String message)? onSendMessage;

  bool get isOnline => _isOnline;

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'inum_offline.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_channels (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_messages (
            id TEXT PRIMARY KEY,
            channel_id TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE outgoing_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            channel_id TEXT NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_cached_messages_channel ON cached_messages(channel_id, created_at DESC)',
        );
      },
    );
    _startConnectivityMonitor();
  }

  Database get _database {
    if (_db == null) throw StateError('OfflineRepository not initialized');
    return _db!;
  }

  void _startConnectivityMonitor() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      if (wasOffline && _isOnline) {
        _flushOutgoingQueue();
      }
    });
  }

  // --- Channel cache ---

  Future<void> cacheChannels(List<Map<String, dynamic>> channels) async {
    final batch = _database.batch();
    final now = DateTime.now().toIso8601String();
    for (final ch in channels) {
      batch.insert(
        'cached_channels',
        {
          'id': ch['id'] as String? ?? '',
          'data': jsonEncode(ch),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedChannels() async {
    final rows = await _database.query('cached_channels', orderBy: 'updated_at DESC');
    return rows.map((r) {
      return jsonDecode(r['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // --- Message cache ---

  Future<void> cacheMessages(String channelId, List<Map<String, dynamic>> messages) async {
    final batch = _database.batch();
    // Keep only last 50 per channel
    final toCache = messages.take(50).toList();
    // Clear old messages for this channel
    batch.delete('cached_messages', where: 'channel_id = ?', whereArgs: [channelId]);
    for (final msg in toCache) {
      batch.insert(
        'cached_messages',
        {
          'id': msg['id'] as String? ?? '',
          'channel_id': channelId,
          'data': jsonEncode(msg),
          'created_at': msg['create_at']?.toString() ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedMessages(String channelId) async {
    final rows = await _database.query(
      'cached_messages',
      where: 'channel_id = ?',
      whereArgs: [channelId],
      orderBy: 'created_at DESC',
      limit: 50,
    );
    return rows.map((r) {
      return jsonDecode(r['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // --- Outgoing message queue ---

  Future<void> queueMessage(String channelId, String message) async {
    await _database.insert('outgoing_queue', {
      'channel_id': channelId,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
    // Try to flush immediately if online
    if (_isOnline) {
      await _flushOutgoingQueue();
    }
  }

  Future<int> getQueuedMessageCount() async {
    final result = await _database.rawQuery('SELECT COUNT(*) as cnt FROM outgoing_queue');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _flushOutgoingQueue() async {
    if (onSendMessage == null) return;
    try {
      final rows = await _database.query('outgoing_queue', orderBy: 'created_at ASC');
      for (final row in rows) {
        final channelId = row['channel_id'] as String;
        final message = row['message'] as String;
        final id = row['id'] as int;
        try {
          await onSendMessage!(channelId, message);
          await _database.delete('outgoing_queue', where: 'id = ?', whereArgs: [id]);
        } catch (e) {
          debugPrint('Failed to send queued message: $e');
          break; // Stop flushing on first failure
        }
      }
    } catch (e) {
      debugPrint('Error flushing outgoing queue: $e');
    }
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _db?.close();
    _db = null;
  }
}
