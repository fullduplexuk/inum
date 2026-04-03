import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/call/voicemail_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("VoicemailModel", () {
    test("toMap serializes all fields", () {
      final vm = TestData.voicemail();
      final map = vm.toMap();
      expect(map["id"], "vm-1");
      expect(map["from_user_id"], "user-456");
      expect(map["from_username"], "caller");
      expect(map["audio_url"], "https://example.com/vm.mp3");
      expect(map["transcript"], "Hi, please call me back.");
      expect(map["duration_secs"], 15);
      expect(map["is_read"], 0); // false -> 0
    });

    test("fromMap round-trips with toMap", () {
      final original = TestData.voicemail();
      final restored = VoicemailModel.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.fromUserId, original.fromUserId);
      expect(restored.fromUsername, original.fromUsername);
      expect(restored.audioUrl, original.audioUrl);
      expect(restored.transcript, original.transcript);
      expect(restored.isRead, original.isRead);
    });

    test("fromMap parses is_read as int", () {
      final map = {"id": "vm1", "created_at": "2025-01-01T00:00:00.000", "is_read": 1};
      expect(VoicemailModel.fromMap(map).isRead, true);

      final map2 = {"id": "vm2", "created_at": "2025-01-01T00:00:00.000", "is_read": 0};
      expect(VoicemailModel.fromMap(map2).isRead, false);
    });

    test("copyWith overrides specific fields", () {
      final vm = TestData.voicemail();
      final updated = vm.copyWith(isRead: true, transcript: "Updated");
      expect(updated.isRead, true);
      expect(updated.transcript, "Updated");
      expect(updated.id, vm.id);
    });

    test("toMap stores isRead as int (0/1)", () {
      final vm = TestData.voicemail().copyWith(isRead: true);
      expect(vm.toMap()["is_read"], 1);
    });

    test("equality via Equatable", () {
      final a = TestData.voicemail();
      final b = TestData.voicemail();
      expect(a, equals(b));
    });

    test("fromMap handles null optional fields", () {
      final map = {"id": "vm1", "created_at": "2025-01-01T00:00:00.000"};
      final vm = VoicemailModel.fromMap(map);
      expect(vm.audioUrl, isNull);
      expect(vm.transcript, isNull);
    });
  });
}
