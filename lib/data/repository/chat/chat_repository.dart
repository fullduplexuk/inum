import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/data/api/mattermost/mattermost_ws_client.dart';
import 'package:inum/domain/models/chat/channel_model.dart';
import 'package:inum/domain/models/chat/message_model.dart';

class ChatRepository implements IChatRepository {
  final MattermostApiClient _apiClient;
  final MattermostWsClient _wsClient;

  final StreamController<List<ChannelModel>> _channelsController =
      StreamController<List<ChannelModel>>.broadcast();

  List<ChannelModel> _cachedChannels = [];
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  ChatRepository({
    required MattermostApiClient apiClient,
    required MattermostWsClient wsClient,
  })  : _apiClient = apiClient,
        _wsClient = wsClient;

  @override
  Stream<List<ChannelModel>> get channelsStream => _channelsController.stream;

  @override
  Stream<Map<String, dynamic>> get wsEvents => _wsClient.events;

  @override
  String? get currentUserId => _apiClient.currentUserId;

  @override
  String? get authToken => _apiClient.token;

  @override
  String getProfileImageUrl(String userId) => _apiClient.getProfileImageUrl(userId);

  @override
  Future<void> connectWebSocket() async {
    final token = _apiClient.token;
    if (token == null) {
      debugPrint('Cannot connect WS: no token');
      return;
    }

    await _wsClient.connect(token);

    _wsSubscription?.cancel();
    _wsSubscription = _wsClient.events.listen(_handleWsEvent);

    await _loadChannels();
  }

  @override
  Future<void> disconnectWebSocket() async {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsClient.disconnect();
  }

  Future<void> _loadChannels() async {
    try {
      final teams = await _apiClient.getMyTeams();
      final allChannels = <ChannelModel>[];

      for (final team in teams) {
        final teamId = team['id'] as String;
        final channels = await _apiClient.getMyChannels(teamId);
        for (final ch in channels) {
          allChannels.add(ChannelModel.fromMattermost(ch as Map<String, dynamic>));
        }
      }

      allChannels.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));
      _cachedChannels = allChannels;
      _channelsController.add(_cachedChannels);
    } catch (e) {
      debugPrint('Error loading channels: $e');
    }
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    final eventType = event['event'] as String?;
    if (eventType == null) return;

    switch (eventType) {
      case 'posted':
      case 'post_edited':
      case 'post_deleted':
      case 'channel_viewed':
        _loadChannels();
      default:
        break;
    }
  }

  @override
  Future<List<MessageModel>> getChannelMessages(String channelId, int page) async {
    try {
      final data = await _apiClient.getPosts(channelId, page: page);
      final order = data['order'] as List<dynamic>? ?? [];
      final posts = data['posts'] as Map<String, dynamic>? ?? {};

      final messages = <MessageModel>[];
      for (final postId in order) {
        final post = posts[postId as String];
        if (post != null) {
          messages.add(MessageModel.fromMattermost(post as Map<String, dynamic>));
        }
      }
      return messages;
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  @override
  Future<void> sendMessage(String channelId, String message, {String? rootId, List<String>? fileIds}) async {
    await _apiClient.createPost(channelId, message, rootId: rootId, fileIds: fileIds);
  }

  @override
  Future<void> updateMessage(String postId, String message) async {
    await _apiClient.updatePost(postId, message);
  }

  @override
  Future<void> deleteMessage(String postId) async {
    await _apiClient.deletePost(postId);
  }

  @override
  Future<void> markChannelAsRead(String channelId) async {
    await _apiClient.viewChannel(channelId);
  }

  // --- Reactions ---

  @override
  Future<void> addReaction(String postId, String emojiName) async {
    final userId = _apiClient.currentUserId;
    if (userId == null) return;
    await _apiClient.addReaction(userId, postId, emojiName);
  }

  @override
  Future<void> removeReaction(String postId, String emojiName) async {
    final userId = _apiClient.currentUserId;
    if (userId == null) return;
    await _apiClient.removeReaction(userId, postId, emojiName);
  }

  // --- Threads ---

  @override
  Future<List<MessageModel>> getThread(String postId) async {
    try {
      final data = await _apiClient.getThread(postId);
      final order = data['order'] as List<dynamic>? ?? [];
      final posts = data['posts'] as Map<String, dynamic>? ?? {};

      final messages = <MessageModel>[];
      for (final id in order) {
        final post = posts[id as String];
        if (post != null) {
          messages.add(MessageModel.fromMattermost(post as Map<String, dynamic>));
        }
      }
      // Sort: root first, then by create_at
      messages.sort((a, b) => a.createAt.compareTo(b.createAt));
      return messages;
    } catch (e) {
      debugPrint('Error fetching thread: $e');
      return [];
    }
  }

  // --- Files ---

  @override
  Future<List<String>> uploadFile(String channelId, String filePath, String fileName) async {
    final result = await _apiClient.uploadFile(channelId, filePath, fileName);
    final fileInfos = result['file_infos'] as List<dynamic>? ?? [];
    return fileInfos.map((f) => (f as Map<String, dynamic>)['id'] as String).toList();
  }

  @override
  String getFileUrl(String fileId) => _apiClient.getFileUrl(fileId);

  @override
  String getFileThumbnailUrl(String fileId) => _apiClient.getFileThumbnailUrl(fileId);

  // --- Typing ---

  @override
  void sendTyping(String channelId) {
    _wsClient.userTyping(channelId);
  }

  void dispose() {
    _wsSubscription?.cancel();
    _channelsController.close();
  }

  @override
  Future<void> pinMessage(String postId) async {
    await _apiClient.pinPost(postId);
  }

  @override
  Future<void> unpinMessage(String postId) async {
    await _apiClient.unpinPost(postId);
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String channelId) async {
    final rawPosts = await _apiClient.getPinnedPosts(channelId);
    return rawPosts.map((p) => MessageModel.fromMattermost(p as Map<String, dynamic>)).toList();
  }
}
