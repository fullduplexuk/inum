import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inum/presentation/views/call/widgets/floating_reaction.dart';

void main() {
  group('Feature 4C: Meeting/Call Reactions', () {
    testWidgets('reaction creates a floating animation entry',
        (WidgetTester tester) async {
      final key = GlobalKey<FloatingReactionsOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingReactionsOverlay(key: key),
          ),
        ),
      );

      expect(key.currentState, isNotNull);
      expect(key.currentState!.activeCount, 0);

      key.currentState!.addReaction('\u{1F44D}', 'Arif');
      await tester.pump();
      expect(key.currentState!.activeCount, 1);
    });

    testWidgets('reaction auto-removes after animation completes',
        (WidgetTester tester) async {
      final key = GlobalKey<FloatingReactionsOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingReactionsOverlay(key: key),
          ),
        ),
      );

      key.currentState!.addReaction('\u{2764}\u{FE0F}', 'Test');
      await tester.pump();
      expect(key.currentState!.activeCount, 1);

      // Pump past the full animation duration (2500ms)
      await tester.pumpAndSettle(const Duration(milliseconds: 3000));
      expect(key.currentState!.activeCount, 0);
    });

    testWidgets('multiple reactions can coexist',
        (WidgetTester tester) async {
      final key = GlobalKey<FloatingReactionsOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingReactionsOverlay(key: key),
          ),
        ),
      );

      key.currentState!.addReaction('\u{1F44D}', 'User1');
      key.currentState!.addReaction('\u{2764}\u{FE0F}', 'User2');
      key.currentState!.addReaction('\u{1F602}', 'User3');
      await tester.pump();
      expect(key.currentState!.activeCount, 3);
    });
  });
}
