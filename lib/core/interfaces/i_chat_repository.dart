import 'package:inum/domain/models/chat/channel_model.dart';
import 'package:inum/domain/models/chat/message_model.dart';

abstract class IChatRepository {
  Future<void> connectWebSocket();
  Future<void> disconnectWebSocket();
  Stream<List<ChannelModel>> get channelsStream;
  Future<List<MessageModel>> getChannelMessages(String channelId, int page);
  Future<void> sendMessage(String channelId, String message, {String? rootId, List<String>? fileIds});
  Future<void> updateMessage(String postId, String message);
  Future<void> deleteMessage(String postId);
  Future<void> markChannelAsRead(String channelId);
  Stream<Map<String, dynamic>> get wsEvents;

  // Reactions
  Future<void> addReaction(String postId, String emojiName);
  Future<void> removeReaction(String postId, String emojiName);

  // Threads
  Future<List<MessageModel>> getThread(String postId);

  // Files
  Future<List<String>> uploadFile(String channelId, String filePath, String fileName);
  String getFileUrl(String fileId);
  String getFileThumbnailUrl(String fileId);

  // Typing
  void sendTyping(String channelId);

  // Current user
  String? get currentUserId;
  String? get authToken;
  String getProfileImageUrl(String userId);
}
