import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/core/services/web/notification_helper.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_state.dart';

class ChatSessionCubit extends Cubit<ChatSessionState> {
  final IChatRepository _chatRepository;
  StreamSubscription<Map<String, dynamic>>? _notifSubscription;
  String? _activeChannelId;
  bool _notificationsEnabled = false;

  ChatSessionCubit({required IChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatSessionDisconnected());

  Future<void> connect() async {
    emit(const ChatSessionConnecting());
    try {
      await _chatRepository.connectWebSocket();
      emit(const ChatSessionConnected());
      _initNotifications();
    } catch (e) {
      debugPrint('ChatSession connect error: \$e');
      emit(const ChatSessionDisconnected());
    }
  }

  Future<void> _initNotifications() async {
    if (!kIsWeb) return;
    try {
      _notificationsEnabled = await requestNotificationPermission();
      if (_notificationsEnabled) {
        _listenForNotifications();
      }
    } catch (e) {
      debugPrint('Notification init error: \$e');
    }
  }

  void _listenForNotifications() {
    _notifSubscription?.cancel();
    _notifSubscription = _chatRepository.wsEvents.listen((event) {
      final eventType = event['event'] as String?;
      if (eventType != 'posted') return;

      final data = event['data'] as Map<String, dynamic>? ?? {};
      _handleNotification(data);
    });
  }

  void _handleNotification(Map<String, dynamic> data) {
    if (!_notificationsEnabled) return;

    final postStr = data['post'] as String?;
    if (postStr == null) return;

    try {
      final postJson = jsonDecode(postStr) as Map<String, dynamic>;
      final userId = postJson['user_id'] as String? ?? '';
      final channelId = postJson['channel_id'] as String? ?? '';
      final message = postJson['message'] as String? ?? '';

      // Don't notify for own messages
      if (userId == _chatRepository.currentUserId) return;

      // Don't notify for active channel
      if (channelId == _activeChannelId) return;

      final senderName = data['sender_name'] as String? ?? 'New message';
      final preview = message.length > 50 ? '\${message.substring(0, 50)}...' : message;

      showBrowserNotification(senderName, preview);
      playNotificationSound();
    } catch (e) {
      debugPrint('Notification handling error: \$e');
    }
  }

  /// Set the active channel to suppress notifications for it.
  void setActiveChannel(String? channelId) {
    _activeChannelId = channelId;
  }

  Future<void> disconnect() async {
    _notifSubscription?.cancel();
    await _chatRepository.disconnectWebSocket();
    emit(const ChatSessionDisconnected());
  }

  @override
  Future<void> close() {
    _notifSubscription?.cancel();
    return super.close();
  }
}
