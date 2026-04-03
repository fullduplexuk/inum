import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/call/recording_model.dart';

sealed class RecordingsState extends Equatable {
  const RecordingsState();

  @override
  List<Object?> get props => [];
}

class RecordingsInitial extends RecordingsState {
  const RecordingsInitial();
}

class RecordingsLoading extends RecordingsState {
  const RecordingsLoading();
}

class RecordingsLoaded extends RecordingsState {
  final List<RecordingModel> recordings;

  const RecordingsLoaded({required this.recordings});

  @override
  List<Object?> get props => [recordings];
}

class RecordingsError extends RecordingsState {
  final String message;
  const RecordingsError(this.message);

  @override
  List<Object?> get props => [message];
}
