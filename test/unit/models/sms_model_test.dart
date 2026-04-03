import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/sms/sms_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("SmsModel", () {
    test("toMap serializes all fields", () {
      final sms = TestData.sms();
      final map = sms.toMap();
      expect(map["id"], "sms-1");
      expect(map["from_number"], "+441234567890");
      expect(map["to_number"], "+449876543210");
      expect(map["message"], "Test SMS message");
      expect(map["status"], "sent");
    });

    test("fromMap round-trips with toMap", () {
      final original = TestData.sms();
      final restored = SmsModel.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.fromNumber, original.fromNumber);
      expect(restored.toNumber, original.toNumber);
      expect(restored.message, original.message);
      expect(restored.status, original.status);
    });

    test("fromMap parses all status values", () {
      for (final s in SmsStatus.values) {
        final map = {"id": "s1", "sent_at": "2025-01-01T00:00:00.000", "status": s.name};
        expect(SmsModel.fromMap(map).status, s);
      }
    });

    test("fromMap defaults to sent for unknown status", () {
      final map = {"id": "s1", "sent_at": "2025-01-01T00:00:00.000", "status": "nonexistent"};
      expect(SmsModel.fromMap(map).status, SmsStatus.sent);
    });

    test("copyWith overrides specific fields", () {
      final sms = TestData.sms();
      final updated = sms.copyWith(status: SmsStatus.delivered, message: "Updated");
      expect(updated.status, SmsStatus.delivered);
      expect(updated.message, "Updated");
      expect(updated.id, sms.id);
    });

    test("equality via Equatable", () {
      final a = TestData.sms();
      final b = TestData.sms();
      expect(a, equals(b));
    });
  });
}
