import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:inum/domain/models/sms/sms_model.dart';
import 'package:inum/presentation/blocs/sms/sms_state.dart';

class SmsCubit extends Cubit<SmsState> {
  // In-memory store keyed by phone number
  final Map<String, List<SmsModel>> _conversations = {};
  static const _ownNumber = '+441234567890'; // Placeholder own number

  SmsCubit() : super(const SmsInitial());

  void loadConversation(String number) {
    emit(const SmsLoading());
    try {
      final messages = _conversations[number] ?? [];
      emit(SmsLoaded(messages: messages, conversationNumber: number));
    } catch (e) {
      debugPrint('Error loading SMS conversation: $e');
      emit(SmsError(message: e.toString()));
    }
  }

  void sendSms(String number, String message) {
    final currentState = state;
    final existingMessages = currentState is SmsLoaded
        ? currentState.messages
        : currentState is SmsSending
            ? currentState.messages
            : <SmsModel>[];

    emit(SmsSending(messages: existingMessages, conversationNumber: number));

    try {
      final sms = SmsModel(
        id: const Uuid().v4(),
        fromNumber: _ownNumber,
        toNumber: number,
        message: message,
        sentAt: DateTime.now(),
        status: SmsStatus.sent,
      );

      final updated = [...existingMessages, sms];
      _conversations[number] = updated;

      emit(SmsLoaded(messages: updated, conversationNumber: number));

      debugPrint('SMS sent to $number: $message (placeholder - SIP bridge not deployed)');
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      emit(SmsError(message: e.toString(), previousMessages: existingMessages));
    }
  }

  /// Simulate receiving an SMS (for testing/demo).
  void receiveTestSms(String fromNumber, String message) {
    final currentState = state;
    final isCurrentConversation = currentState is SmsLoaded &&
        currentState.conversationNumber == fromNumber;

    final sms = SmsModel(
      id: const Uuid().v4(),
      fromNumber: fromNumber,
      toNumber: _ownNumber,
      message: message,
      sentAt: DateTime.now(),
      status: SmsStatus.delivered,
    );

    final existing = _conversations[fromNumber] ?? [];
    final updated = [...existing, sms];
    _conversations[fromNumber] = updated;

    if (isCurrentConversation) {
      emit(SmsLoaded(messages: updated, conversationNumber: fromNumber));
    }
  }

  /// Get all conversation numbers that have messages.
  List<String> get conversationNumbers => _conversations.keys.toList();
}
