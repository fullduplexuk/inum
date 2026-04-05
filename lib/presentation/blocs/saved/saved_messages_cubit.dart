import 'dart:convert';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:inum/presentation/blocs/saved/saved_messages_state.dart';

class SavedMessagesCubit extends HydratedCubit<SavedMessagesState> {
  SavedMessagesCubit() : super(const SavedMessagesState());

  void saveMessage(SavedMessageEntry entry) {
    if (state.savedMessages.any((e) => e.messageId == entry.messageId)) return;
    emit(state.copyWith(
      savedMessages: [entry, ...state.savedMessages],
    ));
  }

  void unsaveMessage(String messageId) {
    emit(state.copyWith(
      savedMessages: state.savedMessages
          .where((e) => e.messageId != messageId)
          .toList(),
    ));
  }

  bool isSaved(String messageId) {
    return state.savedMessages.any((e) => e.messageId == messageId);
  }

  @override
  SavedMessagesState? fromJson(Map<String, dynamic> json) {
    try {
      final list = json['saved'] as List<dynamic>? ?? [];
      final entries = list
          .map((e) => SavedMessageEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return SavedMessagesState(savedMessages: entries);
    } catch (_) {
      return const SavedMessagesState();
    }
  }

  @override
  Map<String, dynamic>? toJson(SavedMessagesState state) {
    return {
      'saved': state.savedMessages.map((e) => e.toJson()).toList(),
    };
  }
}
