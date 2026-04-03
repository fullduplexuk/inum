import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inum/domain/models/call/transcript_model.dart';
import 'package:inum/presentation/design_system/colors.dart';

class TranscriptViewer extends StatefulWidget {
  final TranscriptModel transcript;
  final Duration? currentPlaybackPosition;
  final ValueChanged<Duration>? onSeekTo;

  const TranscriptViewer({
    super.key,
    required this.transcript,
    this.currentPlaybackPosition,
    this.onSeekTo,
  });

  @override
  State<TranscriptViewer> createState() => _TranscriptViewerState();
}

class _TranscriptViewerState extends State<TranscriptViewer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _speakerColors = [
    inumPrimary,
    inumSecondary,
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF795548),
  ];

  Color _colorForSpeaker(String speakerName) {
    final index = widget.transcript.speakers.indexOf(speakerName);
    if (index < 0) return inumPrimary;
    return _speakerColors[index % _speakerColors.length];
  }

  List<TranscriptSegment> get _filteredSegments {
    if (_searchQuery.isEmpty) return widget.transcript.segments;
    final query = _searchQuery.toLowerCase();
    return widget.transcript.segments
        .where((s) =>
            s.text.toLowerCase().contains(query) ||
            s.speakerName.toLowerCase().contains(query))
        .toList();
  }

  bool _isCurrentSegment(TranscriptSegment segment) {
    final pos = widget.currentPlaybackPosition;
    if (pos == null) return false;
    return pos >= segment.startTime && pos < segment.endTime;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _exportTranscript() {
    final buffer = StringBuffer();
    buffer.writeln('Transcript - Room: ${widget.transcript.roomId}');
    buffer.writeln(
      'Duration: ${_formatDuration(Duration(seconds: widget.transcript.durationSeconds))}',
    );
    buffer.writeln('Speakers: ${widget.transcript.speakers.join(", ")}');
    buffer.writeln('---');
    for (final seg in widget.transcript.segments) {
      buffer.writeln(
        '[${_formatDuration(seg.startTime)}] ${seg.speakerName}: ${seg.text}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript copied to clipboard')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segments = _filteredSegments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transcript...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: _exportTranscript,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: segments.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No transcript available'
                        : 'No results for "$_searchQuery"',
                    style: const TextStyle(color: customGreyColor600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: segments.length,
                  itemBuilder: (context, index) {
                    final segment = segments[index];
                    final isCurrent = _isCurrentSegment(segment);
                    final speakerColor =
                        _colorForSpeaker(segment.speakerName);

                    return GestureDetector(
                      onTap: () =>
                          widget.onSeekTo?.call(segment.startTime),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? speakerColor.withAlpha(25)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(
                                  color: speakerColor, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: speakerColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  segment.speakerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: speakerColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDuration(segment.startTime),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: customGreyColor500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                segment.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isCurrent
                                      ? null
                                      : customGreyColor800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
