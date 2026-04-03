import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/data/repository/call/recordings_repository.dart';
import 'package:inum/domain/models/call/recording_model.dart';
import 'package:inum/presentation/blocs/recordings/recordings_state.dart';

class RecordingsCubit extends Cubit<RecordingsState> {
  final IRecordingsRepository _repository;

  RecordingsCubit({required IRecordingsRepository repository})
      : _repository = repository,
        super(const RecordingsInitial());

  Future<void> loadRecordings({int page = 0}) async {
    emit(const RecordingsLoading());
    try {
      final recordings = await _repository.getRecordings(page: page);
      emit(RecordingsLoaded(recordings: recordings));
    } catch (e) {
      debugPrint('Error loading recordings: $e');
      emit(RecordingsError(e.toString()));
    }
  }

  Future<RecordingModel?> getRecording(String id) async {
    try {
      return await _repository.getRecording(id);
    } catch (e) {
      debugPrint('Error getting recording: $e');
      return null;
    }
  }

  Future<RecordingModel?> getRecordingForCall(String callId) async {
    try {
      return await _repository.getRecordingForCall(callId);
    } catch (e) {
      debugPrint('Error getting recording for call: $e');
      return null;
    }
  }

  Future<void> saveRecording(RecordingModel recording) async {
    try {
      await _repository.saveRecording(recording);
      final currentState = state;
      if (currentState is RecordingsLoaded) {
        await loadRecordings();
      }
    } catch (e) {
      debugPrint('Error saving recording: $e');
    }
  }

  Future<void> deleteRecording(String id) async {
    try {
      await _repository.deleteRecording(id);
      final currentState = state;
      if (currentState is RecordingsLoaded) {
        await loadRecordings();
      }
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    }
  }
}
