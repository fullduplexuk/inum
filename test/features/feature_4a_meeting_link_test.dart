import 'package:flutter_test/flutter_test.dart';
import 'package:inum/core/services/meeting_link_service.dart';

void main() {
  group('Feature 4A: Meeting Link Generation', () {
    test('meeting link format matches expected pattern INUM-XXXX-YYYY', () {
      final roomId = MeetingLinkService.generateRoomId();
      expect(
        RegExp(r'^INUM-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(roomId),
        isTrue,
        reason: 'Room ID "$roomId" does not match INUM-XXXX-YYYY pattern',
      );
    });

    test('room ID generation produces unique values', () {
      final ids = List.generate(100, (_) => MeetingLinkService.generateRoomId());
      final unique = ids.toSet();
      expect(unique.length, ids.length,
          reason: 'Generated room IDs should be unique');
    });

    test('meeting card detected from message text containing link', () {
      const msg =
          'Hey join my call: https://app.vista.inum.com/#/join/INUM-AB12-CD34';
      expect(MeetingLinkService.containsMeetingLink(msg), isTrue);

      final roomId = MeetingLinkService.extractRoomId(msg);
      expect(roomId, 'INUM-AB12-CD34');
    });

    test('meeting card not detected from normal message text', () {
      const msg = 'Just a normal message with no link';
      expect(MeetingLinkService.containsMeetingLink(msg), isFalse);
      expect(MeetingLinkService.extractRoomId(msg), isNull);
    });

    test('meeting link URL format is correct', () {
      final roomId = MeetingLinkService.generateRoomId();
      final expectedUrl = 'https://app.vista.inum.com/#/join/$roomId';
      // The URL should be constructible from the room ID
      expect(
        MeetingLinkService.meetingLinkPattern
            .hasMatch(expectedUrl),
        isTrue,
      );
    });
  });
}
