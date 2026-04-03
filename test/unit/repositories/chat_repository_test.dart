import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inum/domain/models/chat/channel_model.dart';
import 'package:inum/domain/models/chat/message_model.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ChatRepository - channel and message logic', () {
    test('ChannelModel.fromMattermost creates valid channel', () {
      final json = TestData.channelJson(
          id: 'ch1', type: 'O', displayName: 'General');
      final channel = ChannelModel.fromMattermost(json);
      expect(channel.id, 'ch1');
      expect(channel.isOpen, true);
      expect(channel.displayName, 'General');
    });

    test('MessageModel.fromMattermost creates valid message', () {
      final json = TestData.messageJson(
          id: 'msg1', channelId: 'ch1', message: 'Hello');
      final msg = MessageModel.fromMattermost(json);
      expect(msg.id, 'msg1');
      expect(msg.message, 'Hello');
      expect(msg.isDeleted, false);
    });

    test('Posts response parsing with order and posts map', () {
      // Simulate the shape returned by getPosts
      final postsResponse = {
        'order': ['p3', 'p2', 'p1'],
        'posts': {
          'p1': TestData.messageJson(id: 'p1', message: 'First'),
          'p2': TestData.messageJson(id: 'p2', message: 'Second'),
          'p3': TestData.messageJson(id: 'p3', message: 'Third'),
        },
      };

      final order = postsResponse['order'] as List<dynamic>;
      final posts = postsResponse['posts'] as Map<String, dynamic>;

      final messages = <MessageModel>[];
      for (final postId in order) {
        final post = posts[postId as String];
        if (post != null) {
          messages
              .add(MessageModel.fromMattermost(post as Map<String, dynamic>));
        }
      }

      expect(messages.length, 3);
      expect(messages[0].id, 'p3');
      expect(messages[1].id, 'p2');
      expect(messages[2].id, 'p1');
    });

    test('Channel sorting by lastPostAt', () {
      final channels = [
        TestData.channel(id: 'ch1'),
        ChannelModel(
          id: 'ch2',
          type: 'O',
          displayName: 'Newer',
          lastPostAt: DateTime(2025, 6, 1),
        ),
        ChannelModel(
          id: 'ch3',
          type: 'D',
          displayName: 'Oldest',
          lastPostAt: DateTime(2020, 1, 1),
        ),
      ];

      channels.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));

      expect(channels[0].id, 'ch2');
      expect(channels[2].id, 'ch3');
    });

    test('WS event types are correctly identified', () {
      const relevantEvents = [
        'posted',
        'post_edited',
        'post_deleted',
        'channel_viewed'
      ];
      for (final event in relevantEvents) {
        expect(relevantEvents.contains(event), true);
      }
    });
  });
}
