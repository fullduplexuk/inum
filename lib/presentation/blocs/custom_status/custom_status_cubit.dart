import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inum/core/services/custom_status_service.dart';

/// State for custom status feature.
class CustomStatusState extends Equatable {
  final CustomStatus? currentStatus;
  final bool isLoading;
  final String? error;
  final bool justSet; // true briefly after setting status (for animation)

  const CustomStatusState({
    this.currentStatus,
    this.isLoading = false,
    this.error,
    this.justSet = false,
  });

  CustomStatusState copyWith({
    CustomStatus? currentStatus,
    bool? isLoading,
    String? error,
    bool? justSet,
    bool clearStatus = false,
    bool clearError = false,
  }) {
    return CustomStatusState(
      currentStatus: clearStatus ? null : (currentStatus ?? this.currentStatus),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      justSet: justSet ?? false,
    );
  }

  @override
  List<Object?> get props => [currentStatus, isLoading, error, justSet];
}

class CustomStatusCubit extends Cubit<CustomStatusState> {
  final CustomStatusService _service;

  CustomStatusCubit({required CustomStatusService service})
      : _service = service,
        super(const CustomStatusState()) {
    _service.onStatusCleared = _onAutoCleared;
  }

  CustomStatusService get service => _service;

  /// Set a custom status.
  Future<void> setStatus({
    required String emojiName,
    required String text,
    StatusExpiryOption expiry = StatusExpiryOption.dontClear,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _service.setCustomStatus(
        emoji: emojiName,
        text: text,
        expiresAt: expiry.expiresAt(),
      );
      emit(state.copyWith(
        currentStatus: _service.currentStatus,
        isLoading: false,
        justSet: true,
      ));
      // Reset justSet after a moment
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(state.copyWith(justSet: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Set a preset status.
  Future<void> setPreset(StatusPreset preset) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      DateTime? expiresAt;
      if (preset.duration != null) {
        expiresAt = DateTime.now().add(preset.duration!);
      }
      await _service.setCustomStatus(
        emoji: preset.emojiName,
        text: preset.text,
        expiresAt: expiresAt,
      );
      emit(state.copyWith(
        currentStatus: _service.currentStatus,
        isLoading: false,
        justSet: true,
      ));
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(state.copyWith(justSet: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Clear the custom status.
  Future<void> clearStatus() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _service.clearCustomStatus();
      emit(state.copyWith(isLoading: false, clearStatus: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Fetch current status from server.
  Future<void> fetchStatus() async {
    try {
      await _service.fetchCurrentStatus();
      if (!isClosed) {
        emit(state.copyWith(currentStatus: _service.currentStatus));
      }
    } catch (e) {
      debugPrint('CustomStatusCubit: fetch failed: $e');
    }
  }

  void _onAutoCleared() {
    if (!isClosed) {
      emit(state.copyWith(clearStatus: true));
    }
  }

  @override
  Future<void> close() {
    _service.onStatusCleared = null;
    return super.close();
  }
}
