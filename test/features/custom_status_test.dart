import 'package:flutter_test/flutter_test.dart';
import 'package:inum/core/services/custom_status_service.dart';

void main() {
  group('CustomStatusService', () {
    test('status with 1h expiry calculates correct expires_at', () {
      final now = DateTime.now();
      final expiresAt = StatusExpiryOption.oneHour.expiresAt();

      expect(expiresAt, isNotNull);
      // Should be approximately 1 hour from now (within 5 seconds tolerance)
      final diff = expiresAt!.difference(now);
      expect(diff.inMinutes, greaterThanOrEqualTo(59));
      expect(diff.inMinutes, lessThanOrEqualTo(61));
    });

    test("Don't clear has no expires_at", () {
      final expiresAt = StatusExpiryOption.dontClear.expiresAt();
      expect(expiresAt, isNull);
    });

    test('preset statuses have correct emoji and duration', () {
      // In a meeting - 1 hour
      final meeting = kStatusPresets[0];
      expect(meeting.emoji, '\u{1F3E2}');
      expect(meeting.text, 'In a meeting');
      expect(meeting.duration, const Duration(hours: 1));

      // Commuting - 30 minutes
      final commuting = kStatusPresets[1];
      expect(commuting.emoji, '\u{1F697}');
      expect(commuting.text, 'Commuting');
      expect(commuting.duration, const Duration(minutes: 30));

      // Working from home - Today (8 hours)
      final wfh = kStatusPresets[2];
      expect(wfh.emoji, '\u{1F3E0}');
      expect(wfh.text, 'Working from home');
      expect(wfh.duration, const Duration(hours: 8));

      // Out sick - Today (8 hours)
      final sick = kStatusPresets[3];
      expect(sick.emoji, '\u{1F912}');
      expect(sick.text, 'Out sick');
      expect(sick.duration, const Duration(hours: 8));

      // On vacation - no expiry
      final vacation = kStatusPresets[4];
      expect(vacation.emoji, '\u{1F334}');
      expect(vacation.text, 'On vacation');
      expect(vacation.duration, isNull);
    });

    test('30 minute expiry calculates correctly', () {
      final now = DateTime.now();
      final expiresAt = StatusExpiryOption.thirtyMinutes.expiresAt();

      expect(expiresAt, isNotNull);
      final diff = expiresAt!.difference(now);
      expect(diff.inMinutes, greaterThanOrEqualTo(29));
      expect(diff.inMinutes, lessThanOrEqualTo(31));
    });

    test('4 hour expiry calculates correctly', () {
      final now = DateTime.now();
      final expiresAt = StatusExpiryOption.fourHours.expiresAt();

      expect(expiresAt, isNotNull);
      final diff = expiresAt!.difference(now);
      expect(diff.inHours, greaterThanOrEqualTo(3));
      expect(diff.inHours, lessThanOrEqualTo(5));
    });

    test('today expiry is end of current day', () {
      final now = DateTime.now();
      final expiresAt = StatusExpiryOption.today.expiresAt();

      expect(expiresAt, isNotNull);
      expect(expiresAt!.year, now.year);
      expect(expiresAt.month, now.month);
      expect(expiresAt.day, now.day);
      expect(expiresAt.hour, 23);
      expect(expiresAt.minute, 59);
    });

    test('CustomStatus.fromJson parses correctly', () {
      final status = CustomStatus.fromJson({
        'emoji': 'office',
        'text': 'In a meeting',
        'expires_at': '2026-04-05T15:00:00Z',
      });

      expect(status.emoji, 'office');
      expect(status.text, 'In a meeting');
      expect(status.expiresAt, isNotNull);
      expect(status.expiresAt!.year, 2026);
    });

    test('CustomStatus.fromJson handles missing expires_at', () {
      final status = CustomStatus.fromJson({
        'emoji': 'palm_tree',
        'text': 'On vacation',
      });

      expect(status.emoji, 'palm_tree');
      expect(status.text, 'On vacation');
      expect(status.expiresAt, isNull);
    });

    test('CustomStatus remaining time text formats correctly', () {
      // Status expiring in 45 minutes
      final soon = CustomStatus(
        emoji: 'office',
        text: 'Test',
        expiresAt: DateTime.now().add(const Duration(minutes: 45)),
      );
      expect(soon.remainingTimeText, startsWith('Clears in'));
      expect(soon.remainingTimeText, contains('m'));

      // Status with no expiry
      const noExpiry = CustomStatus(emoji: 'palm_tree', text: 'Test');
      expect(noExpiry.remainingTimeText, isNull);

      // Already expired
      final expired = CustomStatus(
        emoji: 'office',
        text: 'Test',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(expired.remainingTimeText, 'Expired');
      expect(expired.isExpired, isTrue);
    });

    test('all expiry option labels are defined', () {
      for (final option in StatusExpiryOption.values) {
        expect(option.label, isNotEmpty);
      }
    });
  });
}
