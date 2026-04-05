import 'package:flutter_test/flutter_test.dart';
import 'package:inum/presentation/blocs/call/call_state.dart';
import 'package:inum/domain/models/call/call_model.dart';

void main() {
  group('Feature 4B: Raise Hand in Group Calls', () {
    final testCallModel = CallModel(
      roomName: 'test-room',
      roomId: 'r1',
      participants: const [],
      callType: CallType.video,
      initiatedBy: 'u1',
      startedAt: DateTime(2026, 1, 1),
      status: CallStatus.active,
      channelId: 'ch1',
    );

    test('raise hand toggles state in CallActive', () {
      final initial = CallActive(
        callModel: testCallModel,
        participants: const [],
        handRaisedUserIds: const [],
      );

      expect(initial.handRaisedUserIds, isEmpty);

      // Raise hand for user u1
      final raised = initial.copyWith(
        handRaisedUserIds: [...initial.handRaisedUserIds, 'u1'],
      );
      expect(raised.handRaisedUserIds, contains('u1'));

      // Lower hand for user u1
      final lowered = raised.copyWith(
        handRaisedUserIds:
            raised.handRaisedUserIds.where((id) => id != 'u1').toList(),
      );
      expect(lowered.handRaisedUserIds, isEmpty);
    });

    test('raised hand count is correct', () {
      final state = CallActive(
        callModel: testCallModel,
        participants: const [],
        handRaisedUserIds: const ['u1', 'u2', 'u3'],
      );

      expect(state.handRaisedUserIds.length, 3);
    });
  });
}
