import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/chat/message_model.dart';

abstract class MessagesState extends Equatable {
  const MessagesState();

  @override
  List<Object?> get props => [];
}

class MessagesInitial extends MessagesState {
  const MessagesInitial();
}

class MessagesLoading extends MessagesState {
  const MessagesLoading();
}

class MessagesLoaded extends MessagesState {
  final List<MessageModel> messages;
  final bool hasMore;
  final String channelId;

  const MessagesLoaded({
    required this.messages,
    required this.hasMore,
    required this.channelId,
  });

  MessagesLoaded copyWith({
    List<MessageModel>? messages,
    bool? hasMore,
    String? channelId,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      channelId: channelId ?? this.channelId,
    );
  }

  @override
  List<Object?> get props => [messages, hasMore, channelId];
}

class MessagesError extends MessagesState {
  final String message;
  const MessagesError(this.message);

  @override
  List<Object?> get props => [message];
}
