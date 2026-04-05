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
  Future<List<String>> uploadFileBytes(String channelId, List<int> bytes, String fileName);

  /// Get channel member data (includes last_viewed_at)
  Future<Map<String, dynamic>> getChannelMember(String channelId);

  /// Get user details including last_activity_at
  Future<Map<String, dynamic>> getUserDetails(String userId);
  String getFileUrl(String fileId);
  String getFileThumbnailUrl(String fileId);

  // Typing
  void sendTyping(String channelId);

  // Current user
  String? get currentUserId;
  String? get authToken;
  String getProfileImageUrl(String userId);

  // Phase 8: Pin messages
  Future<void> pinMessage(String postId);
  Future<void> unpinMessage(String postId);
  Future<List<MessageModel>> getPinnedMessages(String channelId);

  // User lookup for DM display names
  Future<Map<String, String>> getUserDisplayNames(List<String> userIds);

  // User statuses
  Future<Map<String, String>> getUserStatuses(List<String> userIds);

  // Search users (for new chat)
  Future<List<Map<String, dynamic>>> searchUsers(String term);

  // Create DM channel
  Future<String> createDirectMessage(String otherUserId);

  // Search posts across channels
  Future<Map<String, dynamic>> searchPosts(String terms);

  // Get all channels (raw maps) for forwarding picker
  Future<List<Map<String, dynamic>>> getChannelList();
}
