import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/call/transcript_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("TranscriptModel", () {
    test("fromJson parses all fields", () {
      final json = {
        "room_id": "room-1",
        "duration_seconds": 120,
        "speakers": ["Alice", "Bob"],
        "segments": [
          {"speaker_id": "u1", "speaker_name": "Alice", "start_ms": 0, "end_ms": 5000, "text": "Hello"},
          {"speaker_id": "u2", "speaker_name": "Bob", "start_ms": 5000, "end_ms": 10000, "text": "Hi there"},
        ],
      };
      final t = TranscriptModel.fromJson(json);
      expect(t.roomId, "room-1");
      expect(t.durationSeconds, 120);
      expect(t.speakers.length, 2);
      expect(t.segments.length, 2);
      expect(t.segments[0].text, "Hello");
      expect(t.segments[1].speakerName, "Bob");
    });

    test("fromJson handles empty input", () {
      final t = TranscriptModel.fromJson(<String, dynamic>{});
      expect(t.roomId, "");
      expect(t.durationSeconds, 0);
      expect(t.speakers, isEmpty);
      expect(t.segments, isEmpty);
    });

    test("toJson round-trips correctly", () {
      final original = TestData.transcript();
      final json = original.toJson();
      final restored = TranscriptModel.fromJson(json);
      expect(restored.roomId, original.roomId);
      expect(restored.segments.length, original.segments.length);
      expect(restored.segments[0].text, original.segments[0].text);
    });

    test("equality via Equatable", () {
      final a = TestData.transcript();
      final b = TestData.transcript();
      expect(a, equals(b));
    });
  });

  group("TranscriptSegment", () {
    test("fromJson parses durations", () {
      final s = TranscriptSegment.fromJson({
        "speaker_id": "u1",
        "speaker_name": "Alice",
        "start_ms": 1500,
        "end_ms": 5500,
        "text": "Hello",
      });
      expect(s.startTime, const Duration(milliseconds: 1500));
      expect(s.endTime, const Duration(milliseconds: 5500));
    });

    test("toJson serializes durations as milliseconds", () {
      const s = TranscriptSegment(
        speakerId: "u1",
        speakerName: "Alice",
        startTime: Duration(seconds: 3),
        endTime: Duration(seconds: 8),
        text: "Hello",
      );
      final json = s.toJson();
      expect(json["start_ms"], 3000);
      expect(json["end_ms"], 8000);
    });
  });
}
