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

  /// Cache of userId -> display name for DM channels
  final Map<String, String> _userDisplayNameCache = {};

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
      final currentUid = _apiClient.currentUserId ?? '';

      for (final team in teams) {
        final teamId = team['id'] as String;
        final channels = await _apiClient.getMyChannels(teamId);
        for (final ch in channels) {
          allChannels.add(ChannelModel.fromMattermost(ch as Map<String, dynamic>));
        }
      }

      // Collect DM other-user IDs for batch lookup
      final dmUserIds = <String>{};
      for (final ch in allChannels) {
        if (ch.isDirect) {
          final otherId = ch.otherUserId(currentUid);
          if (otherId != null && otherId.isNotEmpty && !_userDisplayNameCache.containsKey(otherId)) {
            dmUserIds.add(otherId);
          }
        }
      }

      // Batch fetch user display names
      if (dmUserIds.isNotEmpty) {
        try {
          final users = await _apiClient.getUsersByIds(dmUserIds.toList());
          for (final u in users) {
            final userData = u as Map<String, dynamic>;
            final uid = userData['id'] as String? ?? '';
            final first = userData['first_name'] as String? ?? '';
            final last = userData['last_name'] as String? ?? '';
            final username = userData['username'] as String? ?? '';
            final name = (first.isNotEmpty || last.isNotEmpty)
                ? '$first $last'.trim()
                : username;
            if (uid.isNotEmpty) _userDisplayNameCache[uid] = name;
          }
        } catch (e) {
          debugPrint('Error fetching DM user names: $e');
        }
      }

      // Set display names for DM channels
      final enriched = <ChannelModel>[];
      for (var ch in allChannels) {
        if (ch.isDirect) {
          final otherId = ch.otherUserId(currentUid);
          if (otherId != null && _userDisplayNameCache.containsKey(otherId)) {
            ch = ch.copyWith(displayName: _userDisplayNameCache[otherId]);
          }
        }
        enriched.add(ch);
      }

      // Fetch unread counts
      try {
        final memberData = await _fetchMyChannelUnreads();
        final readCountMap = <String, int>{};
        final mentionMap = <String, int>{};
        for (final m in memberData) {
          final cid = m['channel_id'] as String? ?? '';
          final msgCount = m['msg_count'] as int? ?? 0;
          final mentionCount = m['mention_count'] as int? ?? 0;
          readCountMap[cid] = msgCount;
          mentionMap[cid] = mentionCount;
        }

        // Apply unread counts
        final withUnreads = <ChannelModel>[];
        for (var ch in enriched) {
          final readCount = readCountMap[ch.id] ?? ch.totalMsgCount;
          final unread = ch.totalMsgCount - readCount;
          final mentionCount = mentionMap[ch.id] ?? 0;
          final effectiveUnread = unread > 0 ? unread : mentionCount;
          withUnreads.add(ch.copyWith(unreadCount: effectiveUnread > 0 ? effectiveUnread : 0));
        }

        // Fetch last messages
        final withMessages = await _enrichWithLastMessages(withUnreads);

        withMessages.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));
        _cachedChannels = withMessages;
        _channelsController.add(_cachedChannels);
      } catch (e) {
        debugPrint('Error enriching channels: $e');
        enriched.sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));
        _cachedChannels = enriched;
        _channelsController.add(_cachedChannels);
      }
    } catch (e) {
      debugPrint('Error loading channels: $e');
    }
  }

  Future<List<dynamic>> _fetchMyChannelUnreads() async {
    final uid = _apiClient.currentUserId;
    if (uid == null) return [];
    try {
      return await _apiClient.getChannelMembersForUser(uid);
    } catch (e) {
      debugPrint('Error fetching unread counts: $e');
      return [];
    }
  }

  Future<List<ChannelModel>> _enrichWithLastMessages(List<ChannelModel> channels) async {
    // Fetch last post for top 30 channels to avoid too many requests
    final toFetch = channels.take(30).toList();
    final remaining = channels.skip(30).toList();

    final futures = toFetch.map((ch) async {
      try {
        final posts = await _apiClient.getPosts(ch.id, page: 0, perPage: 1);
        final order = posts['order'] as List<dynamic>? ?? [];
        final postsMap = posts['posts'] as Map<String, dynamic>? ?? {};
        if (order.isNotEmpty) {
          final lastPostId = order.first as String;
          final lastPost = postsMap[lastPostId] as Map<String, dynamic>?;
          if (lastPost != null) {
            var msg = lastPost['message'] as String? ?? '';
            final fileIds = lastPost['file_ids'] as List<dynamic>?;
            if (msg.isEmpty && fileIds != null && fileIds.isNotEmpty) {
              msg = '[Attachment]';
            }
            return ch.copyWith(lastMessage: msg);
          }
        }
      } catch (e) {
        debugPrint('Error fetching last post for ${ch.id}: $e');
      }
      return ch;
    });

    final results = await Future.wait(futures);
    return [...results, ...remaining];
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
      messages.sort((a, b) => a.createAt.compareTo(b.createAt));
      return messages;
    } catch (e) {
      debugPrint('Error fetching thread: $e');
      return [];
    }
  }

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

  @override
  void sendTyping(String channelId) {
    _wsClient.userTyping(channelId);
  }

  @override
  Future<Map<String, String>> getUserDisplayNames(List<String> userIds) async {
    final result = <String, String>{};
    final toFetch = userIds.where((id) => !_userDisplayNameCache.containsKey(id)).toList();
    for (final id in userIds) {
      if (_userDisplayNameCache.containsKey(id)) {
        result[id] = _userDisplayNameCache[id]!;
      }
    }
    if (toFetch.isNotEmpty) {
      try {
        final users = await _apiClient.getUsersByIds(toFetch);
        for (final u in users) {
          final userData = u as Map<String, dynamic>;
          final uid = userData['id'] as String? ?? '';
          final first = userData['first_name'] as String? ?? '';
          final last = userData['last_name'] as String? ?? '';
          final username = userData['username'] as String? ?? '';
          final name = (first.isNotEmpty || last.isNotEmpty)
              ? '$first $last'.trim()
              : username;
          if (uid.isNotEmpty) {
            _userDisplayNameCache[uid] = name;
            result[uid] = name;
          }
        }
      } catch (e) {
        debugPrint('Error fetching user display names: $e');
      }
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String term) async {
    try {
      final users = await _apiClient.searchUsers(term);
      return users.map((u) => u as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  @override
  Future<String> createDirectMessage(String otherUserId) async {
    final uid = _apiClient.currentUserId ?? '';
    final ch = await _apiClient.createDirectChannel([uid, otherUserId]);
    return ch['id'] as String? ?? '';
  }

  @override
  Future<Map<String, String>> getUserStatuses(List<String> userIds) async {
    final result = <String, String>{};
    if (userIds.isEmpty) return result;
    try {
      final statuses = await _apiClient.getUserStatusesByIds(userIds);
      for (final s in statuses) {
        final data = s as Map<String, dynamic>;
        final uid = data['user_id'] as String? ?? '';
        final status = data['status'] as String? ?? 'offline';
        if (uid.isNotEmpty) result[uid] = status;
      }
    } catch (e) {
      debugPrint('Error fetching user statuses: $e');
    }
    return result;
  }

  @override
  Future<List<String>> uploadFileBytes(String channelId, List<int> bytes, String fileName) async {
    final result = await _apiClient.uploadFileBytes(channelId, bytes, fileName);
    final fileInfos = result['file_infos'] as List<dynamic>? ?? [];
    return fileInfos.map((fi) => (fi as Map<String, dynamic>)['id'] as String).toList();
  }

  @override
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    return _apiClient.getUser(userId);
  }

  void dispose() {
    _wsSubscription?.cancel();
    _channelsController.close();
  }


  @override
  Future<Map<String, dynamic>> searchPosts(String terms) async {
    return _apiClient.searchPosts(terms);
  }

  @override
  Future<List<Map<String, dynamic>>> getChannelList() async {
    try {
      final teams = await _apiClient.getMyTeams();
      final result = <Map<String, dynamic>>[];
      for (final team in teams) {
        final teamId = team['id'] as String;
        final channels = await _apiClient.getMyChannels(teamId);
        for (final ch in channels) {
          result.add(ch as Map<String, dynamic>);
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error getting channel list: $e');
      return [];
    }
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
