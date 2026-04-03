import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/call/forwarding_rule.dart";
import "../../helpers/test_data.dart";

void main() {
  group("ForwardingRule", () {
    test("toMap serializes all fields", () {
      final rule = TestData.forwardingRule();
      final map = rule.toMap();
      expect(map["condition"], "always");
      expect(map["enabled"], true);
      expect(map["destination"], "+441234567890");
      expect(map["delay_seconds"], 20);
    });

    test("fromMap round-trips with toMap", () {
      final original = TestData.forwardingRule(condition: ForwardingCondition.busy, enabled: false);
      final restored = ForwardingRule.fromMap(original.toMap());
      expect(restored.condition, ForwardingCondition.busy);
      expect(restored.enabled, false);
      expect(restored.destination, original.destination);
    });

    test("fromMap parses all condition values", () {
      for (final c in ForwardingCondition.values) {
        final map = {"condition": c.name, "enabled": true, "destination": "+1234"};
        expect(ForwardingRule.fromMap(map).condition, c);
      }
    });

    test("fromMap defaults to always for unknown condition", () {
      final map = {"condition": "nonexistent"};
      expect(ForwardingRule.fromMap(map).condition, ForwardingCondition.always);
    });

    test("conditionLabel returns human-readable label", () {
      expect(
        ForwardingRule(condition: ForwardingCondition.always).conditionLabel,
        "Always",
      );
      expect(
        ForwardingRule(condition: ForwardingCondition.busy).conditionLabel,
        "When Busy",
      );
      expect(
        ForwardingRule(condition: ForwardingCondition.noAnswer).conditionLabel,
        "When No Answer",
      );
      expect(
        ForwardingRule(condition: ForwardingCondition.offline).conditionLabel,
        "When Offline",
      );
    });

    test("copyWith overrides specific fields", () {
      final rule = TestData.forwardingRule();
      final updated = rule.copyWith(enabled: false, delaySeconds: 30);
      expect(updated.enabled, false);
      expect(updated.delaySeconds, 30);
      expect(updated.condition, rule.condition);
    });

    test("default values are correct", () {
      const rule = ForwardingRule(condition: ForwardingCondition.always);
      expect(rule.enabled, false);
      expect(rule.destination, "");
      expect(rule.delaySeconds, 20);
    });

    test("equality via Equatable", () {
      final a = TestData.forwardingRule();
      final b = TestData.forwardingRule();
      expect(a, equals(b));
    });
  });
}
