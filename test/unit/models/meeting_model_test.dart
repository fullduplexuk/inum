import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/meeting/meeting_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("MeetingModel", () {
    test("fromJson parses all fields", () {
      final json = {
        "id": "m1",
        "title": "Standup",
        "scheduled_at": "2025-06-01T10:00:00.000",
        "duration_minutes": 30,
        "participants": ["u1", "u2"],
        "notes": "Daily sync",
        "channel_id": "ch-1",
        "created_by": "u1",
      };
      final m = MeetingModel.fromJson(json);
      expect(m.id, "m1");
      expect(m.title, "Standup");
      expect(m.durationMinutes, 30);
      expect(m.participants, ["u1", "u2"]);
      expect(m.notes, "Daily sync");
    });

    test("fromJson handles missing fields", () {
      final m = MeetingModel.fromJson(<String, dynamic>{});
      expect(m.id, "");
      expect(m.title, "");
      expect(m.durationMinutes, 30); // default
      expect(m.participants, isEmpty);
    });

    test("toJson round-trips", () {
      final original = TestData.meeting();
      final json = original.toJson();
      final restored = MeetingModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(restored.participants, original.participants);
    });

    test("endAt calculates correctly", () {
      final m = TestData.meeting();
      expect(m.endAt, m.scheduledAt.add(Duration(minutes: m.durationMinutes)));
    });

    test("isUpcoming is true for future meetings", () {
      final m = MeetingModel(
        id: "m1", title: "Future",
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 30, participants: [],
      );
      expect(m.isUpcoming, true);
    });

    test("isUpcoming is false for past meetings", () {
      final m = MeetingModel(
        id: "m1", title: "Past",
        scheduledAt: DateTime(2020, 1, 1),
        durationMinutes: 30, participants: [],
      );
      expect(m.isUpcoming, false);
    });

    test("copyWith overrides specific fields", () {
      final m = TestData.meeting();
      final updated = m.copyWith(title: "Updated", durationMinutes: 90);
      expect(updated.title, "Updated");
      expect(updated.durationMinutes, 90);
      expect(updated.id, m.id);
    });

    test("equality via Equatable", () {
      final a = TestData.meeting();
      final b = TestData.meeting();
      expect(a, equals(b));
    });
  });
}
