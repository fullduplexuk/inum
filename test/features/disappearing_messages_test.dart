import 'package:flutter_test/flutter_test.dart';
import 'package:inum/core/services/disappearing_messages_service.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';

void main() {
  group('DisappearingMessagesService', () {
    late DisappearingMessagesService service;

    setUp(() {
      // Create a real service with a real (but unused) API client.
      // We only test pure logic methods that don't call the API.
      final api = MattermostApiClient();
      service = DisappearingMessagesService(api: api);
    });

    test('message older than 24h should be marked for deletion', () {
      const channelId = 'ch1';
      service.setChannelDuration(channelId, DisappearingDuration.twentyFourHours);

      // Message created 25 hours ago
      final msgCreateAt = DateTime.now().subtract(const Duration(hours: 25));
      final remaining = service.remainingTime(channelId, msgCreateAt);

      expect(remaining, equals(Duration.zero));
      expect(
        service.formatRemainingTime(channelId, msgCreateAt),
        equals('Expired'),
      );
    });

    test('message newer than 24h should not be deleted', () {
      const channelId = 'ch1';
      service.setChannelDuration(channelId, DisappearingDuration.twentyFourHours);

      // Message created 1 hour ago
      final msgCreateAt = DateTime.now().subtract(const Duration(hours: 1));
      final remaining = service.remainingTime(channelId, msgCreateAt);

      expect(remaining, isNotNull);
      expect(remaining!.inHours, greaterThanOrEqualTo(22));
      expect(
        service.formatRemainingTime(channelId, msgCreateAt),
        startsWith('Expires in'),
      );
    });

    test('disabled channel should not delete anything', () {
      const channelId = 'ch1';
      // Default is off
      expect(service.isEnabled(channelId), isFalse);
      expect(service.getChannelDuration(channelId), DisappearingDuration.off);

      final msgCreateAt = DateTime.now().subtract(const Duration(days: 100));
      final remaining = service.remainingTime(channelId, msgCreateAt);
      expect(remaining, isNull);
      expect(service.formatRemainingTime(channelId, msgCreateAt), isNull);
    });

    test('different durations: 24h, 7d, 30d', () {
      const channelId = 'ch1';

      // 24 hours
      service.setChannelDuration(channelId, DisappearingDuration.twentyFourHours);
      expect(service.getChannelDuration(channelId), DisappearingDuration.twentyFourHours);
      var msgAge = DateTime.now().subtract(const Duration(hours: 23));
      expect(service.remainingTime(channelId, msgAge)!.inMinutes, greaterThan(0));
      msgAge = DateTime.now().subtract(const Duration(hours: 25));
      expect(service.remainingTime(channelId, msgAge), Duration.zero);

      // 7 days
      service.setChannelDuration(channelId, DisappearingDuration.sevenDays);
      expect(service.getChannelDuration(channelId), DisappearingDuration.sevenDays);
      msgAge = DateTime.now().subtract(const Duration(days: 6));
      expect(service.remainingTime(channelId, msgAge)!.inHours, greaterThan(0));
      msgAge = DateTime.now().subtract(const Duration(days: 8));
      expect(service.remainingTime(channelId, msgAge), Duration.zero);

      // 30 days
      service.setChannelDuration(channelId, DisappearingDuration.thirtyDays);
      expect(service.getChannelDuration(channelId), DisappearingDuration.thirtyDays);
      msgAge = DateTime.now().subtract(const Duration(days: 29));
      expect(service.remainingTime(channelId, msgAge)!.inHours, greaterThan(0));
      msgAge = DateTime.now().subtract(const Duration(days: 31));
      expect(service.remainingTime(channelId, msgAge), Duration.zero);
    });

    test('expiring soon detection works', () {
      const channelId = 'ch1';
      service.setChannelDuration(channelId, DisappearingDuration.twentyFourHours);

      // Message close to expiry (23h 50m ago, only 10m left of 24h)
      final nearExpiry = DateTime.now().subtract(
        const Duration(hours: 23, minutes: 50),
      );
      expect(service.isExpiringSoon(channelId, nearExpiry), isTrue);

      // Message with plenty of time (1h ago)
      final fresh = DateTime.now().subtract(const Duration(hours: 1));
      expect(service.isExpiringSoon(channelId, fresh), isFalse);
    });

    test('serialization and deserialization', () {
      service.setChannelDuration('ch1', DisappearingDuration.twentyFourHours);
      service.setChannelDuration('ch2', DisappearingDuration.sevenDays);
      service.setChannelDuration('ch3', DisappearingDuration.thirtyDays);

      final json = service.toJson();

      final api2 = MattermostApiClient();
      final restored = DisappearingMessagesService(api: api2);
      restored.loadFromJson(json);

      expect(restored.getChannelDuration('ch1'), DisappearingDuration.twentyFourHours);
      expect(restored.getChannelDuration('ch2'), DisappearingDuration.sevenDays);
      expect(restored.getChannelDuration('ch3'), DisappearingDuration.thirtyDays);
      expect(restored.getChannelDuration('ch_unknown'), DisappearingDuration.off);
    });

    test('setting to off removes channel from settings', () {
      service.setChannelDuration('ch1', DisappearingDuration.twentyFourHours);
      expect(service.isEnabled('ch1'), isTrue);

      service.setChannelDuration('ch1', DisappearingDuration.off);
      expect(service.isEnabled('ch1'), isFalse);
    });
  });
}
