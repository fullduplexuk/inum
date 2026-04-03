import "dart:async";
import "package:mocktail/mocktail.dart";
import "package:http/http.dart" as http;
import "package:inum/core/interfaces/i_auth_repository.dart";
import "package:inum/core/interfaces/i_chat_repository.dart";
import "package:inum/data/api/mattermost/mattermost_api_client.dart";
import "package:inum/data/api/mattermost/mattermost_ws_client.dart";
import "package:inum/data/api/livekit/livekit_service.dart";
import "package:inum/data/repository/call/call_history_repository.dart";
import "package:inum/data/repository/call/recordings_repository.dart";
import "package:inum/domain/models/chat/channel_model.dart";
import "package:inum/domain/models/chat/message_model.dart";

class MockHttpClient extends Mock implements http.Client {}

class MockIAuthRepository extends Mock implements IAuthRepository {}

class MockIChatRepository extends Mock implements IChatRepository {}

class MockMattermostApiClient extends Mock implements MattermostApiClient {}

class MockMattermostWsClient extends Mock implements MattermostWsClient {
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void emitEvent(Map<String, dynamic> event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}

class MockLiveKitService extends Mock implements LiveKitService {
  final StreamController<LiveKitEvent> _eventController =
      StreamController<LiveKitEvent>.broadcast();

  @override
  Stream<LiveKitEvent> get events => _eventController.stream;

  void emitEvent(LiveKitEvent event) {
    _eventController.add(event);
  }
}

class MockCallHistoryRepository extends Mock
    implements ICallHistoryRepository {}

class MockRecordingsRepository extends Mock implements IRecordingsRepository {}
