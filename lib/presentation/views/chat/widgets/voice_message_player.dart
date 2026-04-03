import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';

/// Audio player widget for voice messages in chat bubbles.
class VoiceMessagePlayer extends StatefulWidget {
  final String fileId;
  final String? fileUrl;
  final bool isOwn;
  final Duration duration;

  const VoiceMessagePlayer({
    super.key,
    required this.fileId,
    this.fileUrl,
    required this.isOwn,
    this.duration = const Duration(seconds: 30),
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  bool _isPlaying = false;
  double _progress = 0.0;
  double _playbackSpeed = 1.0;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) {
          setState(() {
            _progress += 0.1 / (widget.duration.inSeconds * _playbackSpeed);
            if (_progress >= 1.0) {
              _progress = 0.0;
              _isPlaying = false;
              _progressTimer?.cancel();
            }
          });
        }
      });
    } else {
      _progressTimer?.cancel();
    }
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isOwn ? white : inumPrimary;
    final bgColor = widget.isOwn ? white.withAlpha(40) : inumPrimary.withAlpha(20);
    final trackColor = widget.isOwn ? white.withAlpha(60) : customGreyColor300;
    final activeColor = widget.isOwn ? white : inumSecondary;
    final elapsed = Duration(milliseconds: (widget.duration.inMilliseconds * _progress).toInt());

    return Container(
      width: 220,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: fgColor.withAlpha(widget.isOwn ? 50 : 30), shape: BoxShape.circle),
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: fgColor, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(20, (i) {
                      final isActive = (i / 20) <= _progress;
                      final height = 4.0 + ((i * 7 + 3) % 16);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          height: height,
                          decoration: BoxDecoration(color: isActive ? activeColor : trackColor, borderRadius: BorderRadius.circular(1)),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(elapsed), style: TextStyle(fontSize: 10, color: fgColor.withAlpha(180))),
                    GestureDetector(
                      onTap: _cycleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: fgColor.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text('${_playbackSpeed}x', style: TextStyle(fontSize: 10, color: fgColor, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
