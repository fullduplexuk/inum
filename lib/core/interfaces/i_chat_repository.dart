import 'package:inum/domain/models/chat/channel_model.dart';
import 'package:inum/domain/models/chat/message_model.dart';

abstract class IChatRepository {
  Future<void> connectWebSocket();
  Future<void> disconnectWebSocket();
  Stream<List<ChannelModel>> get channelsStream;
  Future<List<MessageModel>> getChannelMessages(String channelId, int page);
  Future<void> sendMessage(String channelId, String message, {String? rootId});
  Future<void> updateMessage(String postId, String message);
  Future<void> deleteMessage(String postId);
  Future<void> markChannelAsRead(String channelId);
  Stream<Map<String, dynamic>> get wsEvents;
}
