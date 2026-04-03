import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/call/call_record.dart';

enum CallHistoryFilter { all, missed, incoming, outgoing }

sealed class CallHistoryState extends Equatable {
  const CallHistoryState();

  @override
  List<Object?> get props => [];
}

class CallHistoryLoading extends CallHistoryState {
  const CallHistoryLoading();
}

class CallHistoryLoaded extends CallHistoryState {
  final List<CallRecord> records;
  final CallHistoryFilter filter;
  final int missedCount;

  const CallHistoryLoaded({
    required this.records,
    this.filter = CallHistoryFilter.all,
    this.missedCount = 0,
  });

  CallHistoryLoaded copyWith({
    List<CallRecord>? records,
    CallHistoryFilter? filter,
    int? missedCount,
  }) {
    return CallHistoryLoaded(
      records: records ?? this.records,
      filter: filter ?? this.filter,
      missedCount: missedCount ?? this.missedCount,
    );
  }

  @override
  List<Object?> get props => [records, filter, missedCount];
}

class CallHistoryError extends CallHistoryState {
  final String message;
  const CallHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
