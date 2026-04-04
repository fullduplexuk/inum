import "package:inum/data/repository/call/recordings_repository.dart";
import "package:inum/domain/models/call/recording_model.dart";

/// In-memory stub for web where SQLite is not available.
class RecordingsRepositoryWeb implements IRecordingsRepository {
  @override
  Future<void> init() async {}

  @override
  Future<List<RecordingModel>> getRecordings({int page = 0, int perPage = 30}) async => [];

  @override
  Future<RecordingModel?> getRecordingForCall(String callId) async => null;

  @override
  Future<RecordingModel?> getRecording(String id) async => null;

  @override
  Future<void> saveRecording(RecordingModel model) async {}

  @override
  Future<void> deleteRecording(String id) async {}
}
