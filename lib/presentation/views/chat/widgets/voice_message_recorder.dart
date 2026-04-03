import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';

/// Hold-to-record voice message widget.
class VoiceMessageRecorder extends StatefulWidget {
  final void Function(String filePath, Duration duration) onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceMessageRecorder({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isCancelled = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  double _dragOffset = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isCancelled = false;
      _elapsed = Duration.zero;
      _dragOffset = 0;
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    _pulseController.stop();
    if (!_isCancelled && _elapsed.inSeconds >= 1) {
      widget.onRecordingComplete(
        '/tmp/voice_message.m4a',
        _elapsed,
      );
    }
    setState(() => _isRecording = false);
  }

  void _cancelRecording() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isCancelled = true;
      _isRecording = false;
    });
    widget.onCancel?.call();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) return _buildRecordingUI();
    return _buildMicButton();
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: inumPrimary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, color: white, size: 20),
      ),
    );
  }

  Widget _buildRecordingUI() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() => _dragOffset += details.delta.dx);
        if (_dragOffset < -80) _cancelRecording();
      },
      onLongPressEnd: (_) => _stopRecording(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: errorColor.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: errorColor.withAlpha(
                    (128 + 127 * _pulseController.value).toInt(),
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_elapsed),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: errorColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            ...List.generate(
              12,
              (i) => Container(
                width: 3,
                height: 8.0 + (i % 3 == 0 ? 12 : (i % 2 == 0 ? 8 : 4)),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: errorColor.withAlpha(150),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_back, size: 16, color: customGreyColor500),
            const SizedBox(width: 4),
            const Text(
              'Slide to cancel',
              style: TextStyle(fontSize: 12, color: customGreyColor500),
            ),
          ],
        ),
      ),
    );
  }
}
