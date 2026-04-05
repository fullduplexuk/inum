import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/services/meeting_link_service.dart';
import 'package:inum/presentation/design_system/colors.dart';

/// Renders a meeting link found in a chat message as a styled card.
class MeetingCard extends StatefulWidget {
  final String roomId;
  final String joinUrl;
  final VoidCallback? onJoin;

  const MeetingCard({
    super.key,
    required this.roomId,
    required this.joinUrl,
    this.onJoin,
  });

  /// Try to build a MeetingCard from arbitrary message text.
  /// Returns null when the text does not contain a meeting link.
  static MeetingCard? fromMessageText(String text, {VoidCallback? onJoin}) {
    final roomId = MeetingLinkService.extractRoomId(text);
    if (roomId == null) return null;
    final joinUrl = 'https://app.vista.inum.com/#/join/$roomId';
    return MeetingCard(roomId: roomId, joinUrl: joinUrl, onJoin: onJoin);
  }

  @override
  State<MeetingCard> createState() => _MeetingCardState();
}

class _MeetingCardState extends State<MeetingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _join(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Video icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam, color: white, size: 26),
                ),
                const SizedBox(width: 12),
                // Text column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Video Meeting',
                        style: TextStyle(
                          color: white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.roomId,
                        style: TextStyle(
                          color: white.withAlpha(200),
                          fontSize: 13,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Pulsing join button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + _pulseController.value * 0.06;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: ElevatedButton(
                    onPressed: () => _join(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: white,
                      foregroundColor: const Color(0xFF43A047),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _join(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (widget.onJoin != null) {
      widget.onJoin!();
    } else {
      context.push('/join/${widget.roomId}');
    }
  }
}
