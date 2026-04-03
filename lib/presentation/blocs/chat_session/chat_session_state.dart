import 'package:equatable/equatable.dart';

abstract class ChatSessionState extends Equatable {
  const ChatSessionState();

  @override
  List<Object?> get props => [];
}

class ChatSessionDisconnected extends ChatSessionState {
  const ChatSessionDisconnected();
}

class ChatSessionConnecting extends ChatSessionState {
  const ChatSessionConnecting();
}

class ChatSessionConnected extends ChatSessionState {
  const ChatSessionConnected();
}
