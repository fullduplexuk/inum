import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/call/call_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("CallModel", () {
    test("fromJson parses all fields", () {
      final json = {
        "room_name": "call-room-1",
        "room_id": "room-1",
        "participants": [
          {"user_id": "u1", "username": "alice", "is_audio_enabled": true, "is_video_enabled": false},
        ],
        "call_type": "audio",
        "initiated_by": "u1",
        "started_at": "2025-01-01T00:00:00.000",
        "status": "ringing",
        "channel_id": "ch-1",
        "livekit_url": "wss://lk.example.com",
      };
      final call = CallModel.fromJson(json);
      expect(call.roomName, "call-room-1");
      expect(call.roomId, "room-1");
      expect(call.participants.length, 1);
      expect(call.callType, CallType.audio);
      expect(call.status, CallStatus.ringing);
      expect(call.livekitUrl, "wss://lk.example.com");
    });

    test("fromJson with video call type", () {
      final call = CallModel.fromJson({"call_type": "video", "started_at": "2025-01-01T00:00:00.000"});
      expect(call.callType, CallType.video);
    });

    test("fromJson defaults to ringing status", () {
      final call = CallModel.fromJson({"started_at": "2025-01-01T00:00:00.000"});
      expect(call.status, CallStatus.ringing);
    });

    test("toJson round-trips correctly", () {
      final original = TestData.call();
      final json = original.toJson();
      expect(json["room_name"], "call-room-1");
      expect(json["call_type"], "audio");
      expect(json["status"], "ringing");
      expect(json["channel_id"], "ch-1");
    });

    test("copyWith overrides fields", () {
      final call = TestData.call();
      final updated = call.copyWith(status: CallStatus.active);
      expect(updated.status, CallStatus.active);
      expect(updated.roomName, call.roomName);
    });

    test("equality via Equatable", () {
      final a = TestData.call();
      final b = TestData.call();
      expect(a, equals(b));
    });
  });

  group("CallParticipant", () {
    test("fromJson parses fields", () {
      final p = CallParticipant.fromJson({
        "user_id": "u1",
        "username": "alice",
        "is_audio_enabled": true,
        "is_video_enabled": true,
      });
      expect(p.userId, "u1");
      expect(p.username, "alice");
      expect(p.isVideoEnabled, true);
    });

    test("toJson serializes", () {
      const p = CallParticipant(userId: "u1", username: "alice", isVideoEnabled: true);
      final json = p.toJson();
      expect(json["user_id"], "u1");
      expect(json["is_video_enabled"], true);
    });

    test("copyWith preserves and overrides", () {
      const p = CallParticipant(userId: "u1", username: "alice");
      final updated = p.copyWith(isSpeaking: true, connectionQuality: ConnectionQuality.excellent);
      expect(updated.isSpeaking, true);
      expect(updated.connectionQuality, ConnectionQuality.excellent);
      expect(updated.userId, "u1");
    });

    test("defaults are correct", () {
      const p = CallParticipant(userId: "u1", username: "alice");
      expect(p.isAudioEnabled, true);
      expect(p.isVideoEnabled, false);
      expect(p.isSpeaking, false);
      expect(p.connectionQuality, ConnectionQuality.good);
    });
  });
}
