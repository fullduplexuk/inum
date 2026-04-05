import 'package:flutter/material.dart';

/// A visual separator line between read and unread messages.
///
/// Shows a horizontal line with "New Messages" text centered,
/// with fade-in animation on first display and auto-fade-out after a delay.
class UnreadSeparator extends StatefulWidget {
  /// Duration before the separator fades out (default 5 seconds).
  final Duration fadeOutDelay;

  const UnreadSeparator({
    super.key,
    this.fadeOutDelay = const Duration(seconds: 5),
  });

  @override
  State<UnreadSeparator> createState() => _UnreadSeparatorState();
}

class _UnreadSeparatorState extends State<UnreadSeparator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-fade-out after delay
    Future.delayed(widget.fadeOutDelay, () {
      if (mounted && !_fadingOut) {
        _fadingOut = true;
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFFFF6D00)],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _GlowingLabel(),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6D00), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowingLabel extends StatefulWidget {
  const _GlowingLabel();

  @override
  State<_GlowingLabel> createState() => _GlowingLabelState();
}

class _GlowingLabelState extends State<_GlowingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowRadius = _pulseController.value * 4.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6D00).withAlpha(80),
            blurRadius: glowRadius,
            spreadRadius: glowRadius / 2,
          ),
        ],
      ),
      child: const Text(
        'New Messages',
        style: TextStyle(
          color: Color(0xFFFF6D00),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Utility to compute the separator index in a list of messages.
///
/// Given a [lastViewedAt] timestamp (milliseconds since epoch) and a list of
/// messages sorted newest-first (as used in a reverse ListView), returns the
/// index of the *last unread message* (the oldest one that is still unread).
/// The separator should be placed *after* this index in the reverse list
/// (i.e., visually between this message and the next older, read message).
///
/// Returns `null` when no separator is needed (all read or empty).
int? computeUnreadSeparatorIndex(
  List<dynamic> messages,
  int? lastViewedAt,
) {
  if (lastViewedAt == null || lastViewedAt <= 0 || messages.isEmpty) return null;

  final threshold = DateTime.fromMillisecondsSinceEpoch(lastViewedAt);

  // messages[0] is newest. Find the boundary.
  // Walk from newest to oldest; the separator goes after the last message
  // whose createAt > threshold.
  int? lastUnreadIdx;
  for (int i = 0; i < messages.length; i++) {
    final msg = messages[i];
    final DateTime createAt;
    if (msg is Map) {
      final ms = msg['create_at'] as int? ?? 0;
      createAt = DateTime.fromMillisecondsSinceEpoch(ms);
    } else {
      createAt = (msg as dynamic).createAt as DateTime;
    }
    if (createAt.isAfter(threshold)) {
      lastUnreadIdx = i;
    } else {
      break; // messages are sorted newest-first, so once we hit a read one, stop
    }
  }

  return lastUnreadIdx;
}
