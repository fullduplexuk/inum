import 'package:flutter/material.dart';
import 'package:inum/domain/models/call/recording_model.dart';
import 'package:inum/domain/models/call/transcript_model.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/views/recordings/transcript_viewer.dart';

class RecordingPlayer extends StatefulWidget {
  final RecordingModel recording;
  final TranscriptModel? transcript;

  const RecordingPlayer({
    super.key,
    required this.recording,
    this.transcript,
  });

  @override
  State<RecordingPlayer> createState() => _RecordingPlayerState();
}

class _RecordingPlayerState extends State<RecordingPlayer> {
  bool _isPlaying = false;
  bool _isFullScreen = false;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  static const _speeds = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.recording.durationSecs);
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    // Placeholder: actual video player will be wired to MinIO URLs later
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
  }

  void _cycleSpeed() {
    final currentIndex = _speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % _speeds.length;
    setState(() => _playbackSpeed = _speeds[nextIndex]);
  }

  void _seekTo(Duration position) {
    setState(() {
      _currentPosition = position;
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text(
                'Recording',
                style: TextStyle(fontSize: 18),
              ),
              centerTitle: false,
              actions: [
                if (widget.transcript != null)
                  IconButton(
                    icon: const Icon(Icons.description_outlined),
                    tooltip: 'View transcript',
                    onPressed: () {
                      // Scroll to transcript section
                    },
                  ),
              ],
            ),
      body: Column(
        children: [
          // Video player area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Placeholder for video content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: 48,
                        color: Colors.white.withAlpha(100),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.recording.compositeUrl ?? 'No video URL',
                        style: TextStyle(
                          color: Colors.white.withAlpha(100),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  // Participants overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.recording.participants.join(', '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  // Play/pause overlay
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Full screen toggle
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        _isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFullScreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Controls bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Scrub bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: inumSecondary,
                    inactiveTrackColor: customGreyColor300,
                    thumbColor: inumSecondary,
                  ),
                  child: Slider(
                    value: _totalDuration.inMilliseconds > 0
                        ? _currentPosition.inMilliseconds /
                            _totalDuration.inMilliseconds
                        : 0,
                    onChanged: (value) {
                      _seekTo(Duration(
                        milliseconds:
                            (value * _totalDuration.inMilliseconds).toInt(),
                      ));
                    },
                  ),
                ),
                // Time + speed
                Row(
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                        fontSize: 12,
                        color: customGreyColor600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _cycleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: customGreyColor200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDuration(_totalDuration),
                      style: const TextStyle(
                        fontSize: 12,
                        color: customGreyColor600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Synced transcript below
          if (widget.transcript != null)
            Expanded(
              child: TranscriptViewer(
                transcript: widget.transcript!,
                currentPlaybackPosition: _currentPosition,
                onSeekTo: _seekTo,
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.subtitles_off_outlined,
                        size: 48, color: customGreyColor400),
                    SizedBox(height: 12),
                    Text(
                      'No transcript available',
                      style: TextStyle(color: customGreyColor600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
