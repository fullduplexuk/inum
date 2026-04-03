import 'package:flutter/material.dart';

class KeyboardDismissWrapper extends StatelessWidget {
  final Widget child;
  final bool enableDismissOnTap;

  const KeyboardDismissWrapper({
    super.key, required this.child, this.enableDismissOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableDismissOnTap) return child;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
