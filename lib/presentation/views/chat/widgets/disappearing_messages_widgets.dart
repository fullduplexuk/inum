import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/services/disappearing_messages_service.dart';
import 'package:inum/presentation/blocs/disappearing_messages/disappearing_messages_cubit.dart';
import 'package:inum/presentation/design_system/colors.dart';

/// A small rotating timer icon shown on messages in disappearing channels.
class DisappearingTimerIcon extends StatefulWidget {
  final String? expiryText;
  final bool expiringSoon;

  const DisappearingTimerIcon({
    super.key,
    this.expiryText,
    this.expiringSoon = false,
  });

  @override
  State<DisappearingTimerIcon> createState() => _DisappearingTimerIconState();
}

class _DisappearingTimerIconState extends State<DisappearingTimerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.expiryText ?? 'Disappearing message',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * pi,
            child: Icon(
              Icons.timer_outlined,
              size: 12,
              color: widget.expiringSoon
                  ? errorColor.withAlpha(200)
                  : customGreyColor500,
            ),
          );
        },
      ),
    );
  }
}

/// Animated banner shown at the top of chat when disappearing messages are on.
class DisappearingMessagesBanner extends StatefulWidget {
  final String channelId;

  const DisappearingMessagesBanner({
    super.key,
    required this.channelId,
  });

  @override
  State<DisappearingMessagesBanner> createState() =>
      _DisappearingMessagesBannerState();
}

class _DisappearingMessagesBannerState extends State<DisappearingMessagesBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisappearingMessagesCubit, DisappearingMessagesState>(
      builder: (context, state) {
        final key = state.channelDurations[widget.channelId];
        if (key == null) return const SizedBox.shrink();
        final duration = DisappearingDurationExt.fromStorageKey(key);
        if (duration == DisappearingDuration.off) return const SizedBox.shrink();

        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  inumSecondary.withAlpha(30),
                  inumSecondary.withAlpha(15),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: inumSecondary.withAlpha(50)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: inumSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Disappearing messages: ${duration.label}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: inumSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Wrapper that adds fade-out + slide animation for expiring messages.
class DisappearingMessageWrapper extends StatefulWidget {
  final Widget child;
  final bool expiringSoon;
  final VoidCallback? onExpired;

  const DisappearingMessageWrapper({
    super.key,
    required this.child,
    this.expiringSoon = false,
    this.onExpired,
  });

  @override
  State<DisappearingMessageWrapper> createState() =>
      _DisappearingMessageWrapperState();
}

class _DisappearingMessageWrapperState extends State<DisappearingMessageWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(DisappearingMessageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expiringSoon && !oldWidget.expiringSoon) {
      _fadeController.animateTo(0.3, curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: widget.child,
    );
  }
}

/// Duration picker dialog for disappearing messages setting.
class DisappearingDurationPicker extends StatelessWidget {
  final DisappearingDuration currentDuration;
  final ValueChanged<DisappearingDuration> onChanged;

  const DisappearingDurationPicker({
    super.key,
    required this.currentDuration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: DisappearingDuration.values.map((d) {
        return RadioListTile<DisappearingDuration>(
          title: Text(d.label),
          value: d,
          groupValue: currentDuration,
          activeColor: inumPrimary,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        );
      }).toList(),
    );
  }
}

/// Small timer icon for the channel list.
class ChannelTimerIcon extends StatelessWidget {
  const ChannelTimerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 4),
      child: Icon(
        Icons.timer_outlined,
        size: 14,
        color: inumSecondary,
      ),
    );
  }
}
