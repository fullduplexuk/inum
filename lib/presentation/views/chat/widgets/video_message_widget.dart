import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:inum/presentation/design_system/colors.dart';

/// Video message widget: thumbnail preview with play overlay.
class VideoMessageWidget extends StatelessWidget {
  final String fileId;
  final String thumbnailUrl;
  final String videoUrl;
  final String? authToken;
  final Duration duration;
  final bool isOwn;

  const VideoMessageWidget({
    super.key,
    required this.fileId,
    required this.thumbnailUrl,
    required this.videoUrl,
    this.authToken,
    this.duration = const Duration(seconds: 15),
    this.isOwn = false,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _playVideo(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: white),
          title: const Text('Video Message', style: TextStyle(color: white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam, color: white, size: 64),
              const SizedBox(height: 16),
              Text(
                'Video playback\n(Player integration pending)',
                textAlign: TextAlign.center,
                style: TextStyle(color: white.withAlpha(180), fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _playVideo(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 200,
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                httpHeaders: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: customGreyColor300,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isOwn ? inumPrimary.withAlpha(60) : customGreyColor200,
                  child: Icon(Icons.videocam, size: 48,
                      color: isOwn ? white.withAlpha(180) : customGreyColor500),
                ),
              ),
              Center(
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.black.withAlpha(120), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: white, size: 32),
                ),
              ),
              Positioned(
                right: 8, bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withAlpha(160), borderRadius: BorderRadius.circular(4)),
                  child: Text(_formatDuration(duration),
                      style: const TextStyle(color: white, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
