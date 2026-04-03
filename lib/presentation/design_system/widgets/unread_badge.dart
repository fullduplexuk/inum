import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';

class UnreadBadge extends StatelessWidget {
  final int count;
  final double size;

  const UnreadBadge({
    super.key,
    required this.count,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final text = count > 99 ? '99+' : count.toString();
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: inumSecondary,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: white,
          fontSize: size * 0.55,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
