import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/call/recording_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("RecordingModel", () {
    test("fromJson parses all fields", () {
      final json = {
        "id": "r1",
        "room_id": "room-1",
        "call_id": "call-1",
        "composite_url": "https://example.com/rec.mp4",
        "individual_tracks": ["track1.wav", "track2.wav"],
        "transcript_url": "https://example.com/transcript.json",
        "summary_url": "https://example.com/summary.txt",
        "duration_secs": 300,
        "created_at": "2025-01-01T00:00:00.000",
        "participants": ["user-1", "user-2"],
      };
      final r = RecordingModel.fromJson(json);
      expect(r.id, "r1");
      expect(r.roomId, "room-1");
      expect(r.compositeUrl, "https://example.com/rec.mp4");
      expect(r.individualTracks.length, 2);
      expect(r.durationSecs, 300);
      expect(r.participants.length, 2);
    });

    test("fromJson handles missing fields", () {
      final r = RecordingModel.fromJson(<String, dynamic>{});
      expect(r.id, "");
      expect(r.compositeUrl, isNull);
      expect(r.individualTracks, isEmpty);
      expect(r.participants, isEmpty);
    });

    test("toJson round-trips", () {
      final original = TestData.recording();
      final json = original.toJson();
      final restored = RecordingModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.roomId, original.roomId);
      expect(restored.durationSecs, original.durationSecs);
    });

    test("toMap stores lists as comma-separated strings", () {
      final r = TestData.recording();
      final map = r.toMap();
      expect(map["participants"], isA<String>());
      expect((map["participants"] as String).contains(","), true);
    });

    test("fromMap restores from comma-separated strings", () {
      final original = TestData.recording();
      final map = original.toMap();
      final restored = RecordingModel.fromMap(map);
      expect(restored.participants, original.participants);
    });

    test("fromMap handles empty comma-separated fields", () {
      final map = {
        "id": "r1",
        "created_at": "2025-01-01T00:00:00.000",
        "individual_tracks": "",
        "participants": "",
      };
      final r = RecordingModel.fromMap(map);
      expect(r.individualTracks, isEmpty);
      expect(r.participants, isEmpty);
    });

    test("equality via Equatable", () {
      final a = TestData.recording();
      final b = TestData.recording();
      expect(a, equals(b));
    });
  });
}
