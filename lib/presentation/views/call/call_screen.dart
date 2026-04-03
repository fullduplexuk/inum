import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/domain/models/call/call_model.dart';
import 'package:inum/presentation/blocs/call/call_cubit.dart';
import 'package:inum/presentation/blocs/call/call_state.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/design_system/widgets/user_avatar.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallCubit, CallState>(
      listener: (context, state) {
        if (state is CallIdle) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      builder: (context, state) {
        return switch (state) {
          CallOutgoing(:final callModel) =>
            _OutgoingCallView(callModel: callModel),
          CallActive() => _ActiveCallView(state: state),
          CallEnded(:final duration, :final reason) =>
            _EndedCallView(duration: duration, reason: reason),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

// ── Outgoing (ringing) ──────────────────────────────────────────────────────

class _OutgoingCallView extends StatefulWidget {
  final CallModel callModel;
  const _OutgoingCallView({required this.callModel});

  @override
  State<_OutgoingCallView> createState() => _OutgoingCallViewState();
}

class _OutgoingCallViewState extends State<_OutgoingCallView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callModel.callType == CallType.video;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Animated pulse rings
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      _buildPulseRing(
                        (_pulseController.value + i * 0.33) % 1.0,
                      ),
                    child!,
                  ],
                );
              },
              child: UserAvatar(
                name: widget.callModel.roomName,
                radius: 50,
                backgroundColor: inumPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.callModel.roomName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVideo ? 'Video calling...' : 'Calling...',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 16,
              ),
            ),
            const Spacer(flex: 3),
            // End call button
            _CallActionButton(
              icon: Icons.call_end,
              color: Colors.red,
              size: 70,
              onPressed: () => context.read<CallCubit>().endCall(),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseRing(double value) {
    return Container(
      width: 100 + (value * 80),
      height: 100 + (value * 80),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: inumSecondary.withAlpha((255 * (1 - value)).toInt()),
          width: 2,
        ),
      ),
    );
  }
}

// ── Active call ─────────────────────────────────────────────────────────────

class _ActiveCallView extends StatelessWidget {
  final CallActive state;
  const _ActiveCallView({required this.state});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  Widget _connectionIcon(ConnectionQuality q) {
    final (icon, color) = switch (q) {
      ConnectionQuality.excellent => (Icons.signal_cellular_4_bar, Colors.green),
      ConnectionQuality.good => (Icons.signal_cellular_alt, Colors.lightGreen),
      ConnectionQuality.poor => (Icons.signal_cellular_alt_1_bar, Colors.orange),
      ConnectionQuality.lost => (Icons.signal_cellular_off, Colors.red),
    };
    return Icon(icon, color: color, size: 16);
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = state.isVideoEnabled;
    final participants = state.participants;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content area
            Column(
              children: [
                // Top bar: timer + name + quality + recording indicator
                _TopBar(
                  duration: _formatDuration(state.elapsed),
                  participants: participants,
                  connectionIcon: participants.isNotEmpty
                      ? _connectionIcon(participants.first.connectionQuality)
                      : null,
                  isRecording: state.isRecording,
                ),
                // Recording banner
                if (state.isRecording)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: Colors.red.withAlpha(40),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fiber_manual_record,
                            color: Colors.red, size: 12),
                        SizedBox(width: 6),
                        Text(
                          'This call is being recorded',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Participant area
                Expanded(
                  child: isVideo
                      ? _VideoGrid(participants: participants)
                      : _AudioGrid(participants: participants),
                ),
              ],
            ),

            // Phase 7: On Hold overlay
            if (state.isOnHold)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(180),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_circle_filled,
                            color: Colors.amber, size: 72),
                        const SizedBox(height: 16),
                        const Text(
                          'On Hold',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Call paused',
                          style: TextStyle(
                            color: Colors.white.withAlpha(150),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _CallActionButton(
                          icon: Icons.play_arrow,
                          color: Colors.green,
                          label: 'Resume',
                          size: 64,
                          onPressed: () =>
                              context.read<CallCubit>().toggleHold(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Phase 7: DTMF pad overlay
            if (state.showDtmfPad)
              Positioned.fill(
                child: _DtmfOverlay(
                  onDigit: (digit) =>
                      context.read<CallCubit>().sendDtmf(digit),
                  onClose: () =>
                      context.read<CallCubit>().toggleDtmfPad(),
                ),
              ),

            // Live captions overlay
            if (state.liveCaptionsEnabled && state.liveCaptions.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 120,
                child: _LiveCaptionsOverlay(
                  captions: state.liveCaptions,
                  translationEnabled: state.translationEnabled,
                ),
              ),
            // Bottom toolbar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomToolbar(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase 7: DTMF Overlay ───────────────────────────────────────────────────

class _DtmfOverlay extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onClose;

  const _DtmfOverlay({
    required this.onDigit,
    required this.onClose,
  });

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '*', '0', '#',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E).withAlpha(240),
      child: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: onClose,
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'DTMF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            // DTMF grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 12,
                ),
                itemCount: _keys.length,
                itemBuilder: (context, index) {
                  final key = _keys[index];
                  return _DtmfButton(
                    digit: key,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDigit(key);
                    },
                  );
                },
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _DtmfButton extends StatefulWidget {
  final String digit;
  final VoidCallback onTap;

  const _DtmfButton({required this.digit, required this.onTap});

  @override
  State<_DtmfButton> createState() => _DtmfButtonState();
}

class _DtmfButtonState extends State<_DtmfButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.1),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withAlpha(15 + (_controller.value * 30).toInt()),
              ),
              child: Center(
                child: Text(
                  widget.digit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Recording indicator (pulsing) ───────────────────────────────────────────

class _RecordingIndicator extends StatefulWidget {
  const _RecordingIndicator();

  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha((180 + 75 * _controller.value).toInt()),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fiber_manual_record,
                  color: Colors.white, size: 10),
              SizedBox(width: 4),
              Text(
                'REC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Live captions overlay ───────────────────────────────────────────────────

class _LiveCaptionsOverlay extends StatelessWidget {
  final List<LiveCaption> captions;
  final bool translationEnabled;

  const _LiveCaptionsOverlay({
    required this.captions,
    required this.translationEnabled,
  });

  @override
  Widget build(BuildContext context) {
    // Only show captions from the last 5 seconds
    final now = DateTime.now();
    final recentCaptions = captions
        .where((c) => now.difference(c.receivedAt).inSeconds < 5)
        .toList();

    if (recentCaptions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recentCaptions.map((caption) {
          final displayText = translationEnabled &&
                  caption.translatedText != null &&
                  caption.translatedText!.isNotEmpty
              ? '${caption.speakerName} '
                '(${caption.sourceLanguage ?? "?"} -> '
                '${caption.targetLanguage ?? "?"}): '
                '${caption.translatedText}'
              : '${caption.speakerName}: ${caption.text}';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              displayText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String duration;
  final List<CallParticipant> participants;
  final Widget? connectionIcon;
  final bool isRecording;

  const _TopBar({
    required this.duration,
    required this.participants,
    this.connectionIcon,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (connectionIcon != null) ...[
            connectionIcon!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      participants.length == 1
                          ? participants.first.username
                          : '${participants.length} participants',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Phase 7: Participant count badge for multi-party calls
                    if (participants.length > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: inumSecondary.withAlpha(80),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${participants.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isRecording) const _RecordingIndicator(),
        ],
      ),
    );
  }
}

class _AudioGrid extends StatelessWidget {
  final List<CallParticipant> participants;
  const _AudioGrid({required this.participants});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: participants.map((p) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speaking indicator ring
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: p.isSpeaking
                      ? Border.all(color: inumSecondary, width: 3)
                      : null,
                ),
                child: UserAvatar(
                  name: p.username,
                  radius: 40,
                  backgroundColor: inumPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p.username,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              if (!p.isAudioEnabled)
                const Icon(Icons.mic_off, color: Colors.red, size: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _VideoGrid extends StatelessWidget {
  final List<CallParticipant> participants;
  const _VideoGrid({required this.participants});

  @override
  Widget build(BuildContext context) {
    final count = participants.length;

    if (count <= 1) {
      // Full screen single participant (or self)
      return Stack(
        children: [
          // Remote video placeholder
          Container(
            color: const Color(0xFF2A2A3E),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    name: count == 1 ? participants.first.username : '?',
                    radius: 50,
                    backgroundColor: inumPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Waiting for video...',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Local PiP
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Center(
                child: Icon(Icons.videocam, color: Colors.white54, size: 32),
              ),
            ),
          ),
        ],
      );
    }

    // Grid layout for multiple participants
    final crossAxisCount = count <= 4 ? 2 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final p = participants[index];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: BorderRadius.circular(12),
            border: p.isSpeaking
                ? Border.all(color: inumSecondary, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: UserAvatar(
                  name: p.username,
                  radius: 30,
                  backgroundColor: inumPrimary,
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.username,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      if (!p.isAudioEnabled) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.mic_off,
                            color: Colors.red, size: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final CallActive state;
  const _BottomToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CallCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha(200),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallActionButton(
                icon: state.isAudioEnabled ? Icons.mic : Icons.mic_off,
                color: state.isAudioEnabled ? Colors.white24 : Colors.red,
                label: state.isAudioEnabled ? 'Mute' : 'Unmute',
                onPressed: cubit.toggleAudio,
              ),
              _CallActionButton(
                icon: state.isVideoEnabled
                    ? Icons.videocam
                    : Icons.videocam_off,
                color: state.isVideoEnabled ? Colors.white24 : Colors.red,
                label: 'Camera',
                onPressed: cubit.toggleVideo,
              ),
              _CallActionButton(
                icon: state.isSpeakerOn
                    ? Icons.volume_up
                    : Icons.volume_down,
                color: state.isSpeakerOn ? inumSecondary : Colors.white24,
                label: 'Speaker',
                onPressed: cubit.toggleSpeaker,
              ),
              if (state.isVideoEnabled)
                _CallActionButton(
                  icon: Icons.cameraswitch,
                  color: Colors.white24,
                  label: 'Flip',
                  onPressed: cubit.switchCamera,
                ),
              _CallActionButton(
                icon: state.isScreenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                color:
                    state.isScreenSharing ? inumSecondary : Colors.white24,
                label: 'Share',
                onPressed: cubit.toggleScreenShare,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Secondary row: Hold, DTMF, Record, CC, Add, End
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Phase 7: Hold button
              _CallActionButton(
                icon: state.isOnHold
                    ? Icons.play_arrow
                    : Icons.pause,
                color: state.isOnHold ? Colors.amber : Colors.white24,
                label: state.isOnHold ? 'Resume' : 'Hold',
                onPressed: cubit.toggleHold,
              ),
              // Phase 7: DTMF button
              _CallActionButton(
                icon: Icons.dialpad,
                color: state.showDtmfPad ? inumSecondary : Colors.white24,
                label: 'Keypad',
                onPressed: cubit.toggleDtmfPad,
              ),
              _CallActionButton(
                icon: Icons.fiber_manual_record,
                color: state.isRecording ? Colors.red : Colors.white24,
                label: state.isRecording ? 'Stop Rec' : 'Record',
                onPressed: cubit.toggleRecording,
              ),
              _CallActionButton(
                icon: Icons.closed_caption,
                color: state.liveCaptionsEnabled
                    ? inumSecondary
                    : Colors.white24,
                label: 'CC',
                onPressed: cubit.toggleLiveCaptions,
              ),
              if (state.liveCaptionsEnabled)
                _CallActionButton(
                  icon: Icons.translate,
                  color: state.translationEnabled
                      ? inumSecondary
                      : Colors.white24,
                  label: 'Translate',
                  onPressed: cubit.toggleTranslation,
                ),
              // Phase 7: Add participant / Merge
              _CallActionButton(
                icon: Icons.person_add,
                color: state.isMerging ? inumSecondary : Colors.white24,
                label: 'Add',
                onPressed: cubit.startAddParticipant,
              ),
              _CallActionButton(
                icon: Icons.call_end,
                color: Colors.red,
                label: 'End',
                onPressed: () => cubit.endCall(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ended ───────────────────────────────────────────────────────────────────

class _EndedCallView extends StatelessWidget {
  final Duration duration;
  final String? reason;
  const _EndedCallView({required this.duration, this.reason});

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_end, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Call Ended',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (reason != null) ...[
              const SizedBox(height: 8),
              Text(
                reason!,
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 14,
                ),
              ),
            ],
            if (duration != Duration.zero) ...[
              const SizedBox(height: 8),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared button widget ────────────────────────────────────────────────────

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onPressed;
  final double size;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.label,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
