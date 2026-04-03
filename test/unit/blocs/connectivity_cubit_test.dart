import 'package:flutter_test/flutter_test.dart';
import 'package:inum/presentation/blocs/connectivity/connectivity_state.dart';

void main() {
  group('ConnectivityState', () {
    test('empty factory creates disconnected state', () {
      final state = ConnectivityState.empty();
      expect(state.isUserConnectedToTheInternet, false);
    });

    test('copyWith overrides connectivity', () {
      final state = ConnectivityState.empty();
      final connected = state.copyWith(isUserConnectedToTheInternet: true);
      expect(connected.isUserConnectedToTheInternet, true);
    });

    test('copyWith preserves value when not provided', () {
      const state = ConnectivityState(isUserConnectedToTheInternet: true);
      final same = state.copyWith();
      expect(same.isUserConnectedToTheInternet, true);
    });

    test('equality via Equatable', () {
      const a = ConnectivityState(isUserConnectedToTheInternet: true);
      const b = ConnectivityState(isUserConnectedToTheInternet: true);
      expect(a, equals(b));

      const c = ConnectivityState(isUserConnectedToTheInternet: false);
      expect(a, isNot(equals(c)));
    });

    test('props contains isUserConnectedToTheInternet', () {
      const state = ConnectivityState(isUserConnectedToTheInternet: true);
      expect(state.props, [true]);
    });
  });
}
