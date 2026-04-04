import "package:inum/data/repository/call/call_history_repository.dart";
import "package:inum/domain/models/call/call_record.dart";
import "package:inum/domain/models/call/voicemail_model.dart";

/// In-memory stub for web where SQLite is not available.
class CallHistoryRepositoryWeb implements ICallHistoryRepository {
  @override
  Future<void> init() async {}

  @override
  Future<void> saveCallRecord(CallRecord record) async {}

  @override
  Future<CallRecord?> getCallRecord(String id) async => null;

  @override
  Future<List<CallRecord>> getCallHistory({int page = 0, int perPage = 30}) async => [];

  @override
  Future<List<CallRecord>> getMissedCalls({int page = 0, int perPage = 30}) async => [];

  @override
  Future<List<CallRecord>> getIncomingCalls({int page = 0, int perPage = 30}) async => [];

  @override
  Future<List<CallRecord>> getOutgoingCalls({int page = 0, int perPage = 30}) async => [];

  @override
  Future<int> getMissedCallCount() async => 0;

  @override
  Future<void> deleteCallRecord(String id) async {}

  @override
  Future<void> clearMissedCallBadge() async {}

  @override
  Future<void> saveVoicemail(VoicemailModel vm) async {}

  @override
  Future<List<VoicemailModel>> getVoicemails({int page = 0, int perPage = 30}) async => [];

  @override
  Future<void> markVoicemailRead(String id) async {}

  @override
  Future<void> deleteVoicemail(String id) async {}

  @override
  Future<int> getUnreadVoicemailCount() async => 0;
}
