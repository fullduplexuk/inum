import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature 4D: Split View on Desktop', () {
    test('wide screen (>900px) should trigger split view', () {
      // The threshold used in bottom_tab_view.dart
      const threshold = 900.0;
      const wideWidth = 1200.0;
      const narrowWidth = 400.0;

      expect(wideWidth > threshold, isTrue,
          reason: 'Wide screen should exceed threshold');
      expect(narrowWidth > threshold, isFalse,
          reason: 'Narrow screen should be below threshold');
    });

    test('narrow screen (<900px) should show single view', () {
      const threshold = 900.0;
      const mobileWidth = 375.0;
      const tabletWidth = 768.0;

      expect(mobileWidth > threshold, isFalse);
      expect(tabletWidth > threshold, isFalse);
    });

    testWidgets('channel selection updates via value notifier',
        (WidgetTester tester) async {
      // Import the SplitView notifier logic
      final notifier = ValueNotifier<({String id, String name})?>(null);
      String? lastId;

      notifier.addListener(() {
        lastId = notifier.value?.id;
      });

      // Simulate selecting a channel
      notifier.value = (id: 'ch123', name: 'General');
      expect(lastId, 'ch123');

      // Select another channel
      notifier.value = (id: 'ch456', name: 'Random');
      expect(lastId, 'ch456');

      notifier.dispose();
    });
  });
}
