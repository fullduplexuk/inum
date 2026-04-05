import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inum/core/services/disappearing_messages_service.dart';

/// State for disappearing messages settings.
class DisappearingMessagesState extends Equatable {
  /// channelId -> storageKey for duration
  final Map<String, String> channelDurations;

  const DisappearingMessagesState({this.channelDurations = const {}});

  DisappearingMessagesState copyWith({Map<String, String>? channelDurations}) {
    return DisappearingMessagesState(
      channelDurations: channelDurations ?? this.channelDurations,
    );
  }

  @override
  List<Object?> get props => [channelDurations];
}

/// HydratedCubit that persists disappearing messages settings.
class DisappearingMessagesCubit
    extends HydratedCubit<DisappearingMessagesState> {
  final DisappearingMessagesService _service;

  DisappearingMessagesCubit({required DisappearingMessagesService service})
      : _service = service,
        super(const DisappearingMessagesState());

  DisappearingMessagesService get service => _service;

  /// Set the duration for a channel.
  void setDuration(String channelId, DisappearingDuration duration) {
    _service.setChannelDuration(channelId, duration);
    final updated = Map<String, String>.from(state.channelDurations);
    if (duration == DisappearingDuration.off) {
      updated.remove(channelId);
    } else {
      updated[channelId] = duration.storageKey;
    }
    emit(state.copyWith(channelDurations: updated));
  }

  /// Get the duration for a channel.
  DisappearingDuration getDuration(String channelId) {
    final key = state.channelDurations[channelId];
    if (key == null) return DisappearingDuration.off;
    return DisappearingDurationExt.fromStorageKey(key);
  }

  /// Check if a channel has disappearing messages enabled.
  bool isEnabled(String channelId) {
    return state.channelDurations.containsKey(channelId);
  }

  /// Restore settings to the service from persisted state.
  void restoreToService() {
    for (final entry in state.channelDurations.entries) {
      _service.setChannelDuration(
        entry.key,
        DisappearingDurationExt.fromStorageKey(entry.value),
      );
    }
  }

  @override
  DisappearingMessagesState? fromJson(Map<String, dynamic> json) {
    final durations = (json['channelDurations'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as String)) ??
        {};
    // Restore to service.
    for (final entry in durations.entries) {
      _service.setChannelDuration(
        entry.key,
        DisappearingDurationExt.fromStorageKey(entry.value),
      );
    }
    return DisappearingMessagesState(channelDurations: durations);
  }

  @override
  Map<String, dynamic>? toJson(DisappearingMessagesState state) {
    return {'channelDurations': state.channelDurations};
  }
}
