import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/sms/sms_model.dart';

sealed class SmsState extends Equatable {
  const SmsState();

  @override
  List<Object?> get props => [];
}

class SmsInitial extends SmsState {
  const SmsInitial();
}

class SmsLoading extends SmsState {
  const SmsLoading();
}

class SmsLoaded extends SmsState {
  final List<SmsModel> messages;
  final String conversationNumber;

  const SmsLoaded({
    required this.messages,
    required this.conversationNumber,
  });

  @override
  List<Object?> get props => [messages, conversationNumber];
}

class SmsSending extends SmsState {
  final List<SmsModel> messages;
  final String conversationNumber;

  const SmsSending({
    required this.messages,
    required this.conversationNumber,
  });

  @override
  List<Object?> get props => [messages, conversationNumber];
}

class SmsError extends SmsState {
  final String message;
  final List<SmsModel> previousMessages;

  const SmsError({
    required this.message,
    this.previousMessages = const [],
  });

  @override
  List<Object?> get props => [message, previousMessages];
}
