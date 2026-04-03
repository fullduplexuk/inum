import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/domain/models/chat/message_model.dart';
import 'package:inum/presentation/blocs/messages/messages_state.dart';

class MessagesCubit extends Cubit<MessagesState> {
  final IChatRepository _chatRepository;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  int _page = 0;
  String _channelId = '';

  // Typing indicator state
  final Map<String, Timer> _typingTimers = {};
  final _typingController = StreamController<Set<String>>.broadcast();
  final Set<String> _typingUsers = {};

  Stream<Set<String>> get typingUsers => _typingController.stream;

  MessagesCubit({required IChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const MessagesInitial()) {
    _listenToWsEvents();
  }

  void _listenToWsEvents() {
    _wsSubscription = _chatRepository.wsEvents.listen((event) {
      final eventType = event['event'] as String?;
      final data = event['data'] as Map<String, dynamic>? ?? {};
      final broadcast = event['broadcast'] as Map<String, dynamic>? ?? {};

      switch (eventType) {
        case 'posted':
          _handleNewPost(data);
        case 'post_edited':
          _handleEditedPost(data);
        case 'post_deleted':
          _handleDeletedPost(data);
        case 'reaction_added':
          _handleReactionAdded(data);
        case 'reaction_removed':
          _handleReactionRemoved(data);
        case 'typing':
          _handleTyping(data, broadcast);
      }
    });
  }

  void _handleNewPost(Map<String, dynamic> data) {
    final postStr = data['post'] as String?;
    if (postStr == null) return;
    try {
      final postJson = jsonDecode(postStr) as Map<String, dynamic>;
      if (postJson['channel_id'] != _channelId) return;
      final msg = MessageModel.fromMattermost(postJson);
      final currentState = state;
      if (currentState is MessagesLoaded) {
        final updated = [msg, ...currentState.messages];
        emit(currentState.copyWith(messages: updated));
      }
    } catch (e) {
      debugPrint('MessagesCubit _handleNewPost error: $e');
    }
  }

  void _handleEditedPost(Map<String, dynamic> data) {
    final postStr = data['post'] as String?;
    if (postStr == null) return;
    try {
      final postJson = jsonDecode(postStr) as Map<String, dynamic>;
      if (postJson['channel_id'] != _channelId) return;
      final msg = MessageModel.fromMattermost(postJson);
      final currentState = state;
      if (currentState is MessagesLoaded) {
        final updated = currentState.messages.map((m) => m.id == msg.id ? msg : m).toList();
        emit(currentState.copyWith(messages: updated));
      }
    } catch (e) {
      debugPrint('MessagesCubit _handleEditedPost error: $e');
    }
  }

  void _handleDeletedPost(Map<String, dynamic> data) {
    final postStr = data['post'] as String?;
    if (postStr == null) return;
    try {
      final postJson = jsonDecode(postStr) as Map<String, dynamic>;
      if (postJson['channel_id'] != _channelId) return;
      final deletedId = postJson['id'] as String?;
      final currentState = state;
      if (currentState is MessagesLoaded && deletedId != null) {
        final updated = currentState.messages.where((m) => m.id != deletedId).toList();
        emit(currentState.copyWith(messages: updated));
      }
    } catch (e) {
      debugPrint('MessagesCubit _handleDeletedPost error: $e');
    }
  }

  void _handleReactionAdded(Map<String, dynamic> data) {
    final reactionStr = data['reaction'] as String?;
    if (reactionStr == null) return;
    try {
      final reactionJson = jsonDecode(reactionStr) as Map<String, dynamic>;
      final postId = reactionJson['post_id'] as String?;
      if (postId == null) return;
      _refreshPost(postId);
    } catch (e) {
      debugPrint('MessagesCubit _handleReactionAdded error: $e');
    }
  }

  void _handleReactionRemoved(Map<String, dynamic> data) {
    final reactionStr = data['reaction'] as String?;
    if (reactionStr == null) return;
    try {
      final reactionJson = jsonDecode(reactionStr) as Map<String, dynamic>;
      final postId = reactionJson['post_id'] as String?;
      if (postId == null) return;
      _refreshPost(postId);
    } catch (e) {
      debugPrint('MessagesCubit _handleReactionRemoved error: $e');
    }
  }

  void _handleTyping(Map<String, dynamic> data, Map<String, dynamic> broadcast) {
    final channelId = broadcast['channel_id'] as String?;
    if (channelId != _channelId) return;
    final userId = data['user_id'] as String?;
    if (userId == null || userId == _chatRepository.currentUserId) return;

    _typingUsers.add(userId);
    _typingController.add(Set.from(_typingUsers));

    // Cancel existing timer for this user
    _typingTimers[userId]?.cancel();
    _typingTimers[userId] = Timer(const Duration(seconds: 5), () {
      _typingUsers.remove(userId);
      _typingController.add(Set.from(_typingUsers));
      _typingTimers.remove(userId);
    });
  }

  /// Refresh a single post from the server (for reaction updates)
  Future<void> _refreshPost(String postId) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;
    final idx = currentState.messages.indexWhere((m) => m.id == postId);
    if (idx == -1) return;

    try {
      final messages = await _chatRepository.getChannelMessages(_channelId, 0);
      final freshPost = messages.where((m) => m.id == postId).firstOrNull;
      if (freshPost != null) {
        final updated = currentState.messages.map((m) => m.id == postId ? freshPost : m).toList();
        emit(currentState.copyWith(messages: updated));
      }
    } catch (e) {
      debugPrint('MessagesCubit _refreshPost error: $e');
    }
  }

  Future<void> loadMessages(String channelId) async {
    _channelId = channelId;
    _page = 0;
    emit(const MessagesLoading());
    try {
      final messages = await _chatRepository.getChannelMessages(channelId, _page);
      _page++;
      emit(MessagesLoaded(
        messages: messages,
        hasMore: messages.length >= 60,
        channelId: channelId,
      ));
    } catch (e) {
      emit(MessagesError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! MessagesLoaded || !currentState.hasMore) return;
    try {
      final messages = await _chatRepository.getChannelMessages(_channelId, _page);
      _page++;
      emit(currentState.copyWith(
        messages: [...currentState.messages, ...messages],
        hasMore: messages.length >= 60,
      ));
    } catch (e) {
      debugPrint('MessagesCubit loadMore error: $e');
    }
  }

  Future<void> sendMessage(String channelId, String text, {String? rootId, List<String>? fileIds}) async {
    await _chatRepository.sendMessage(channelId, text, rootId: rootId, fileIds: fileIds);
  }

  Future<void> updateMessage(String postId, String message) async {
    await _chatRepository.updateMessage(postId, message);
  }

  Future<void> deleteMessage(String postId) async {
    await _chatRepository.deleteMessage(postId);
  }

  Future<void> addReaction(String postId, String emojiName) async {
    await _chatRepository.addReaction(postId, emojiName);
  }

  Future<void> removeReaction(String postId, String emojiName) async {
    await _chatRepository.removeReaction(postId, emojiName);
  }

  Future<List<MessageModel>> getThread(String postId) async {
    return _chatRepository.getThread(postId);
  }

  Future<List<String>> uploadFile(String channelId, String filePath, String fileName) async {
    return _chatRepository.uploadFile(channelId, filePath, fileName);
  }

  void sendTyping(String channelId) {
    _chatRepository.sendTyping(channelId);
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingController.close();
    return super.close();
  }
}
