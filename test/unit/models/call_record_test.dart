import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/call/call_record.dart";
import "../../helpers/test_data.dart";

void main() {
  group("CallRecord", () {
    test("toMap serializes all fields", () {
      final record = TestData.callRecord();
      final map = record.toMap();
      expect(map["id"], "rec-1");
      expect(map["room_id"], "room-1");
      expect(map["call_type"], "audio");
      expect(map["initiated_by"], "user-123");
      expect(map["status"], "completed");
      expect(map["direction"], "outgoing");
      expect(map["duration_secs"], 120);
    });

    test("fromMap round-trips with toMap", () {
      final original = TestData.callRecord();
      final restored = CallRecord.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.roomId, original.roomId);
      expect(restored.status, original.status);
      expect(restored.direction, original.direction);
      expect(restored.durationSecs, original.durationSecs);
    });

    test("fromMap parses missed status", () {
      final record = TestData.callRecord(status: CallRecordStatus.missed);
      final restored = CallRecord.fromMap(record.toMap());
      expect(restored.status, CallRecordStatus.missed);
    });

    test("fromMap parses incoming direction", () {
      final record = TestData.callRecord(direction: CallDirection.incoming);
      final restored = CallRecord.fromMap(record.toMap());
      expect(restored.direction, CallDirection.incoming);
    });

    test("fromMap handles null optional fields", () {
      final map = {
        "id": "r1",
        "started_at": "2025-01-01T00:00:00.000",
      };
      final record = CallRecord.fromMap(map);
      expect(record.endedAt, isNull);
      expect(record.recordingUrl, isNull);
      expect(record.transcriptUrl, isNull);
    });

    test("fromMap defaults to completed/outgoing for unknown values", () {
      final map = {
        "id": "r1",
        "started_at": "2025-01-01T00:00:00.000",
        "status": "nonexistent",
        "direction": "nonexistent",
      };
      final record = CallRecord.fromMap(map);
      expect(record.status, CallRecordStatus.completed);
      expect(record.direction, CallDirection.outgoing);
    });

    test("equality via Equatable", () {
      final a = TestData.callRecord();
      final b = TestData.callRecord();
      expect(a, equals(b));
    });

    test("all CallRecordStatus values parse correctly", () {
      for (final s in CallRecordStatus.values) {
        final map = {"id": "r1", "started_at": "2025-01-01T00:00:00.000", "status": s.name};
        expect(CallRecord.fromMap(map).status, s);
      }
    });
  });
}
