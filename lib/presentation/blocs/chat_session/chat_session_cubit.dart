import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_state.dart';

class ChatSessionCubit extends Cubit<ChatSessionState> {
  final IChatRepository _chatRepository;

  ChatSessionCubit({required IChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatSessionDisconnected());

  Future<void> connect() async {
    emit(const ChatSessionConnecting());
    try {
      await _chatRepository.connectWebSocket();
      emit(const ChatSessionConnected());
    } catch (e) {
      debugPrint('ChatSession connect error: $e');
      emit(const ChatSessionDisconnected());
    }
  }

  Future<void> disconnect() async {
    await _chatRepository.disconnectWebSocket();
    emit(const ChatSessionDisconnected());
  }
}
