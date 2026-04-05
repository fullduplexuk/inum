import 'package:flutter_test/flutter_test.dart';
import 'package:inum/presentation/views/chat/widgets/unread_separator.dart';
import 'package:inum/domain/models/chat/message_model.dart';

void main() {
  group('computeUnreadSeparatorIndex', () {
    MessageModel _makeMsg(String id, int createAtMs) {
      return MessageModel(
        id: id,
        channelId: 'ch1',
        userId: 'u1',
        message: 'msg $id',
        createAt: DateTime.fromMillisecondsSinceEpoch(createAtMs),
        updateAt: DateTime.fromMillisecondsSinceEpoch(createAtMs),
      );
    }

    test('correctly identifies separator position with mixed read/unread', () {
      // Messages sorted newest-first (as in reverse ListView)
      final messages = [
        _makeMsg('5', 5000), // newest, unread
        _makeMsg('4', 4000), // unread
        _makeMsg('3', 3000), // unread
        _makeMsg('2', 2000), // read (at or before lastViewedAt)
        _makeMsg('1', 1000), // read
      ];

      // last_viewed_at = 2000 means messages with createAt > 2000 are unread
      final idx = computeUnreadSeparatorIndex(messages, 2000);

      // The last unread message (oldest unread) is at index 2 (msg '3', createAt=3000)
      // Separator goes after index 2 in the reverse list
      expect(idx, equals(2));
    });

    test('returns null when all messages are read', () {
      final messages = [
        _makeMsg('3', 3000),
        _makeMsg('2', 2000),
        _makeMsg('1', 1000),
      ];

      // last_viewed_at = 5000 -> all messages are before this -> all read
      final idx = computeUnreadSeparatorIndex(messages, 5000);
      expect(idx, isNull);
    });

    test('returns last index when all messages are unread', () {
      final messages = [
        _makeMsg('3', 3000),
        _makeMsg('2', 2000),
        _makeMsg('1', 1000),
      ];

      // last_viewed_at = 500 -> all messages are after this -> all unread
      final idx = computeUnreadSeparatorIndex(messages, 500);

      // Last unread index is 2 (the oldest message, which is still unread)
      expect(idx, equals(2));
    });

    test('returns null for null lastViewedAt', () {
      final messages = [_makeMsg('1', 1000)];
      expect(computeUnreadSeparatorIndex(messages, null), isNull);
    });

    test('returns null for zero lastViewedAt', () {
      final messages = [_makeMsg('1', 1000)];
      expect(computeUnreadSeparatorIndex(messages, 0), isNull);
    });

    test('returns null for empty messages', () {
      expect(computeUnreadSeparatorIndex([], 1000), isNull);
    });

    test('works with Map-based messages', () {
      final messages = [
        {'create_at': 5000},
        {'create_at': 4000},
        {'create_at': 3000},
        {'create_at': 2000},
      ];

      final idx = computeUnreadSeparatorIndex(messages, 3000);
      // Messages with createAt > 3000: index 0 (5000) and index 1 (4000)
      // Last unread = index 1
      expect(idx, equals(1));
    });

    test('single unread message', () {
      final messages = [
        _makeMsg('2', 2000), // unread
        _makeMsg('1', 1000), // read
      ];

      final idx = computeUnreadSeparatorIndex(messages, 1000);
      expect(idx, equals(0));
    });
  });
}
