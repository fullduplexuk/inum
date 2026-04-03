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

  MessagesCubit({required IChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const MessagesInitial()) {
    _listenToWsEvents();
  }

  void _listenToWsEvents() {
    _wsSubscription = _chatRepository.wsEvents.listen((event) {
      final eventType = event['event'] as String?;
      final data = event['data'] as Map<String, dynamic>? ?? {};

      if (eventType == 'posted') {
        _handleNewPost(data);
      } else if (eventType == 'post_edited') {
        _handleEditedPost(data);
      } else if (eventType == 'post_deleted') {
        _handleDeletedPost(data);
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

  Future<void> sendMessage(String channelId, String text) async {
    await _chatRepository.sendMessage(channelId, text);
  }

  Future<void> deleteMessage(String postId) async {
    await _chatRepository.deleteMessage(postId);
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
