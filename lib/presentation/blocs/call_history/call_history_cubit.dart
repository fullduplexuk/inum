import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:inum/data/repository/call/call_history_repository.dart';
import 'package:inum/domain/models/call/call_record.dart';
import 'package:inum/presentation/blocs/call_history/call_history_state.dart';

class CallHistoryCubit extends Cubit<CallHistoryState> {
  final ICallHistoryRepository _repository;

  CallHistoryCubit({required ICallHistoryRepository repository})
      : _repository = repository,
        super(const CallHistoryLoading());

  Future<void> loadHistory({CallHistoryFilter filter = CallHistoryFilter.all}) async {
    emit(const CallHistoryLoading());
    try {
      final List<CallRecord> records;
      switch (filter) {
        case CallHistoryFilter.all:
          records = await _repository.getCallHistory();
        case CallHistoryFilter.missed:
          records = await _repository.getMissedCalls();
        case CallHistoryFilter.incoming:
          records = await _repository.getIncomingCalls();
        case CallHistoryFilter.outgoing:
          records = await _repository.getOutgoingCalls();
      }
      final missedCount = await _repository.getMissedCallCount();
      emit(CallHistoryLoaded(
        records: records,
        filter: filter,
        missedCount: missedCount,
      ));
    } catch (e) {
      debugPrint('Error loading call history: $e');
      emit(CallHistoryError(e.toString()));
    }
  }

  /// Call this when a call ends to persist the record.
  Future<void> recordCallEnded({
    required String roomId,
    required String callType,
    required String initiatedBy,
    required String initiatedByUsername,
    required String targetUserId,
    required String targetUsername,
    required DateTime startedAt,
    required Duration duration,
    required CallRecordStatus status,
    required CallDirection direction,
  }) async {
    try {
      final record = CallRecord(
        id: const Uuid().v4(),
        roomId: roomId,
        callType: callType,
        initiatedBy: initiatedBy,
        initiatedByUsername: initiatedByUsername,
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        durationSecs: duration.inSeconds,
        status: status,
        direction: direction,
      );
      await _repository.saveCallRecord(record);

      // Reload if we are in the loaded state
      final currentState = state;
      if (currentState is CallHistoryLoaded) {
        await loadHistory(filter: currentState.filter);
      }
    } catch (e) {
      debugPrint('Error saving call record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _repository.deleteCallRecord(id);
      final currentState = state;
      if (currentState is CallHistoryLoaded) {
        await loadHistory(filter: currentState.filter);
      }
    } catch (e) {
      debugPrint('Error deleting call record: $e');
    }
  }

  Future<void> clearMissedBadge() async {
    try {
      await _repository.clearMissedCallBadge();
      final currentState = state;
      if (currentState is CallHistoryLoaded) {
        emit(currentState.copyWith(missedCount: 0));
      }
    } catch (e) {
      debugPrint('Error clearing missed badge: $e');
    }
  }

  int get missedCount {
    final s = state;
    if (s is CallHistoryLoaded) return s.missedCount;
    return 0;
  }
}
