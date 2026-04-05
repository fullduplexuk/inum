import 'dart:math';
import 'package:flutter/material.dart';

/// A single floating emoji reaction entry.
class _ReactionEntry {
  final String emoji;
  final String senderName;
  final AnimationController controller;
  final double xDrift;
  final Key key;

  _ReactionEntry({
    required this.emoji,
    required this.senderName,
    required this.controller,
    required this.xDrift,
    required this.key,
  });
}

/// Overlay widget that renders floating emoji reactions during a call.
class FloatingReactionsOverlay extends StatefulWidget {
  const FloatingReactionsOverlay({super.key});

  /// Global key for accessing the overlay state from outside.
  static final globalKey = GlobalKey<FloatingReactionsOverlayState>();

  @override
  State<FloatingReactionsOverlay> createState() =>
      FloatingReactionsOverlayState();
}

class FloatingReactionsOverlayState extends State<FloatingReactionsOverlay>
    with TickerProviderStateMixin {
  final List<_ReactionEntry> _reactions = [];
  final _random = Random();

  /// Add a reaction to the overlay. Called externally.
  void addReaction(String emoji, String senderName) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    final drift = (_random.nextDouble() - 0.5) * 120;
    final entry = _ReactionEntry(
      emoji: emoji,
      senderName: senderName,
      controller: controller,
      xDrift: drift,
      key: UniqueKey(),
    );

    setState(() => _reactions.add(entry));

    controller.forward().then((_) {
      controller.dispose();
      if (mounted) {
        setState(() => _reactions.remove(entry));
      }
    });
  }

  int get activeCount => _reactions.length;

  @override
  void dispose() {
    for (final r in _reactions) {
      r.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _reactions
            .map((entry) => _FloatingEmoji(entry: entry))
            .toList(),
      ),
    );
  }
}

class _FloatingEmoji extends StatelessWidget {
  final _ReactionEntry entry;
  const _FloatingEmoji({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entry.controller,
      builder: (context, child) {
        final t = entry.controller.value;
        final screenSize = MediaQuery.of(context).size;
        final startX = screenSize.width / 2 + entry.xDrift - 24;
        final startY = screenSize.height - 160;
        // Rise up 60% of screen height
        final y = startY - (t * screenSize.height * 0.6);
        final x = startX + sin(t * 3 * pi) * 15;
        // Scale: grow slightly then shrink
        final scale = t < 0.2 ? (t / 0.2) * 1.2 : 1.2 - (t - 0.2) * 0.5;
        // Fade out in last 30%
        final opacity = t > 0.7 ? (1.0 - t) / 0.3 : 1.0;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale.clamp(0.3, 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  if (entry.senderName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.senderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
