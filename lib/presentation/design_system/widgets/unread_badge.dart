import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';

class UnreadBadge extends StatefulWidget {
  final int count;
  final double size;
  final bool pulse;

  const UnreadBadge({
    super.key,
    required this.count,
    this.size = 20,
    this.pulse = false,
  });

  @override
  State<UnreadBadge> createState() => _UnreadBadgeState();
}

class _UnreadBadgeState extends State<UnreadBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _startPulse();
    }
  }

  @override
  void didUpdateWidget(UnreadBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger pulse when count increases
    if (widget.count > oldWidget.count && widget.count > 0) {
      _startPulse();
    }
  }

  void _startPulse() {
    _pulseController?.dispose();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController!.addListener(() {
      if (mounted) setState(() {});
    });
    _pulseController!.forward().then((_) {
      if (mounted) _pulseController?.reverse();
    });
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();

    final text = widget.count > 99 ? '99+' : widget.count.toString();
    final scale = 1.0 + (_pulseController?.value ?? 0.0) * 0.3;
    return Transform.scale(
      scale: scale,
      child: Container(
        constraints: BoxConstraints(minWidth: widget.size, minHeight: widget.size),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: inumSecondary,
          borderRadius: BorderRadius.circular(widget.size / 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: widget.size * 0.55,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
