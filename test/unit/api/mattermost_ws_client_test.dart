import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:inum/data/api/mattermost/mattermost_ws_client.dart';

void main() {
  group('MattermostWsClient', () {
    late MattermostWsClient wsClient;

    setUp(() {
      wsClient = MattermostWsClient();
    });

    tearDown(() {
      wsClient.dispose();
    });

    test('isConnected returns false initially', () {
      expect(wsClient.isConnected, false);
    });

    test('events stream is a broadcast stream', () {
      // Should not throw when listening twice
      wsClient.events.listen((_) {});
      wsClient.events.listen((_) {});
    });

    test('disconnect sets isConnected to false', () {
      wsClient.disconnect();
      expect(wsClient.isConnected, false);
    });

    test('userTyping does not throw when not connected', () {
      // Should silently do nothing
      wsClient.userTyping('ch-1');
    });

    test('sendCallSignal does not throw when not connected', () {
      wsClient.sendCallSignal('custom_call_invite', {'room_id': 'r1'});
    });
  });

  group('WS message parsing', () {
    test('posted event structure', () {
      final rawEvent = {
        'event': 'posted',
        'data': {
          'channel_display_name': 'General',
          'channel_name': 'general',
          'channel_type': 'O',
          'post': jsonEncode({
            'id': 'p1',
            'channel_id': 'ch1',
            'user_id': 'u1',
            'message': 'Hello',
            'create_at': 1704110400000,
            'update_at': 1704110400000,
            'delete_at': 0,
          }),
        },
        'broadcast': {
          'channel_id': 'ch1',
          'team_id': 't1',
        },
      };

      expect(rawEvent['event'], 'posted');
      final data = rawEvent['data'] as Map<String, dynamic>;
      final postJson =
          jsonDecode(data['post'] as String) as Map<String, dynamic>;
      expect(postJson['id'], 'p1');
      expect(postJson['message'], 'Hello');
    });

    test('typing event structure', () {
      final rawEvent = {
        'event': 'typing',
        'data': {
          'user_id': 'u1',
          'parent_id': '',
        },
        'broadcast': {
          'channel_id': 'ch1',
        },
      };

      final data = rawEvent['data'] as Map<String, dynamic>;
      expect(data['user_id'], 'u1');
      final broadcast = rawEvent['broadcast'] as Map<String, dynamic>;
      expect(broadcast['channel_id'], 'ch1');
    });

    test('reaction_added event structure', () {
      final rawEvent = {
        'event': 'reaction_added',
        'data': {
          'reaction': jsonEncode({
            'user_id': 'u1',
            'post_id': 'p1',
            'emoji_name': 'thumbsup',
          }),
        },
      };

      final data = rawEvent['data'] as Map<String, dynamic>;
      final reaction =
          jsonDecode(data['reaction'] as String) as Map<String, dynamic>;
      expect(reaction['emoji_name'], 'thumbsup');
    });

    test('post_edited event structure', () {
      final rawEvent = {
        'event': 'post_edited',
        'data': {
          'post': jsonEncode({
            'id': 'p1',
            'channel_id': 'ch1',
            'message': 'Updated message',
            'create_at': 1704110400000,
            'update_at': 1704110405000,
            'delete_at': 0,
          }),
        },
      };

      final data = rawEvent['data'] as Map<String, dynamic>;
      final postJson =
          jsonDecode(data['post'] as String) as Map<String, dynamic>;
      expect(postJson['message'], 'Updated message');
      expect(postJson['update_at'], greaterThan(postJson['create_at']));
    });

    test('post_deleted event structure', () {
      final rawEvent = {
        'event': 'post_deleted',
        'data': {
          'post': jsonEncode({
            'id': 'p1',
            'channel_id': 'ch1',
            'delete_at': 1704110410000,
          }),
        },
      };

      final data = rawEvent['data'] as Map<String, dynamic>;
      final postJson =
          jsonDecode(data['post'] as String) as Map<String, dynamic>;
      expect(postJson['delete_at'], greaterThan(0));
    });
  });
}
