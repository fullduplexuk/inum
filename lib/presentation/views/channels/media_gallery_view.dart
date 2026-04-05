import "package:flutter/material.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:inum/core/di/dependency_injector.dart";
import "package:inum/core/services/media_filter_service.dart";
import "package:inum/data/api/mattermost/mattermost_api_client.dart";
import "package:inum/domain/models/chat/message_model.dart";
import "package:inum/presentation/design_system/colors.dart";
import "package:intl/intl.dart";
import "package:url_launcher/url_launcher.dart";

/// Tabbed gallery view showing Photos, Files, and Links for a channel.
class MediaGalleryTabs extends StatefulWidget {
  final String channelId;
  final List<MessageModel> messages;

  const MediaGalleryTabs({
    super.key,
    required this.channelId,
    required this.messages,
  });

  @override
  State<MediaGalleryTabs> createState() => _MediaGalleryTabsState();
}

class _MediaGalleryTabsState extends State<MediaGalleryTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _api = getIt<MattermostApiClient>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: inumPrimary,
          unselectedLabelColor: customGreyColor500,
          indicatorColor: inumPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.photo_library, size: 20), text: "Photos"),
            Tab(icon: Icon(Icons.insert_drive_file, size: 20), text: "Files"),
            Tab(icon: Icon(Icons.link, size: 20), text: "Links"),
          ],
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              PhotosGrid(
                messages: widget.messages,
                api: _api,
              ),
              FilesList(
                messages: widget.messages,
                api: _api,
              ),
              LinksList(
                messages: widget.messages,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Photos Grid ---

class PhotosGrid extends StatelessWidget {
  final List<MessageModel> messages;
  final MattermostApiClient api;

  const PhotosGrid({required this.messages, required this.api});

  @override
  Widget build(BuildContext context) {
    final photoMessages = MediaFilterService.filterPhotos(messages);
    if (photoMessages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: customGreyColor400),
            SizedBox(height: 8),
            Text("No shared photos", style: TextStyle(color: customGreyColor500)),
          ],
        ),
      );
    }

    // Collect all image file IDs
    final imageEntries = <ImageEntry>[];
    for (final msg in photoMessages) {
      final files = msg.metadata?["files"] as List<dynamic>? ?? [];
      for (final f in files) {
        final fm = f as Map<String, dynamic>?;
        if (fm == null) continue;
        final ext = (fm["extension"] as String? ?? "").toLowerCase();
        final mimeType = (fm["mime_type"] as String? ?? "").toLowerCase();
        if (MediaFilterService.isImageExtension(ext) || mimeType.startsWith("image/")) {
          final fileId = fm["id"] as String? ?? "";
          if (fileId.isNotEmpty) {
            imageEntries.add(ImageEntry(
              fileId: fileId,
              fileName: fm["name"] as String? ?? "",
              date: msg.createAt,
            ));
          }
        }
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: imageEntries.length,
      itemBuilder: (context, index) {
        final entry = imageEntries[index];
        final thumbUrl = api.getFileThumbnailUrl(entry.fileId);
        final heroTag = "gallery_photo_${entry.fileId}";

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => FullScreenImageViewer(
                  imageEntries: imageEntries,
                  initialIndex: index,
                  api: api,
                ),
                transitionsBuilder: (_, anim, __, child) {
                  return FadeTransition(opacity: anim, child: child);
                },
              ),
            );
          },
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: thumbUrl,
              httpHeaders: {"Authorization": "Bearer ${api.token ?? ""}"},
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: customGreyColor200,
                child: const Center(child: Icon(Icons.photo, color: customGreyColor400)),
              ),
              errorWidget: (_, __, ___) => Container(
                color: customGreyColor200,
                child: const Center(child: Icon(Icons.broken_image, color: customGreyColor400)),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Public image entry for gallery.
class ImageEntry {
  final String fileId;
  final String fileName;
  final DateTime date;
  const ImageEntry({required this.fileId, required this.fileName, required this.date});
}

// --- Full-Screen Image Viewer ---

class FullScreenImageViewer extends StatefulWidget {
  final List<ImageEntry> imageEntries;
  final int initialIndex;
  final MattermostApiClient api;

  const FullScreenImageViewer({
    super.key,
    required this.imageEntries,
    required this.initialIndex,
    required this.api,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.imageEntries[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          entry.fileName,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final url = widget.api.getFileUrl(entry.fileId);
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageEntries.length,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemBuilder: (context, index) {
          final e = widget.imageEntries[index];
          final fullUrl = widget.api.getFileUrl(e.fileId);
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: "gallery_photo_${e.fileId}",
                child: CachedNetworkImage(
                  imageUrl: fullUrl,
                  httpHeaders: {"Authorization": "Bearer ${widget.api.token ?? ""}"},
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
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

// --- Files List ---

class FilesList extends StatelessWidget {
  final List<MessageModel> messages;
  final MattermostApiClient api;

  const FilesList({super.key, required this.messages, required this.api});

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case "pdf": return Icons.picture_as_pdf;
      case "doc": case "docx": return Icons.description;
      case "xls": case "xlsx": return Icons.table_chart;
      case "ppt": case "pptx": return Icons.slideshow;
      case "zip": case "rar": case "7z": case "tar": case "gz": return Icons.archive;
      case "mp3": case "wav": case "ogg": return Icons.audio_file;
      case "mp4": case "avi": case "mov": case "mkv": return Icons.video_file;
      default: return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    final fileMessages = MediaFilterService.filterFiles(messages);
    if (fileMessages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 48, color: customGreyColor400),
            SizedBox(height: 8),
            Text("No shared files", style: TextStyle(color: customGreyColor500)),
          ],
        ),
      );
    }

    final fileEntries = <FileEntry>[];
    for (final msg in fileMessages) {
      final files = msg.metadata?["files"] as List<dynamic>? ?? [];
      for (final f in files) {
        final fm = f as Map<String, dynamic>?;
        if (fm == null) continue;
        final ext = (fm["extension"] as String? ?? "").toLowerCase();
        final mimeType = (fm["mime_type"] as String? ?? "").toLowerCase();
        if (!MediaFilterService.isImageExtension(ext) && !mimeType.startsWith("image/")) {
          fileEntries.add(FileEntry(
            fileId: fm["id"] as String? ?? "",
            name: fm["name"] as String? ?? "Unknown",
            ext: ext,
            size: fm["size"] as int? ?? 0,
            date: msg.createAt,
            userId: msg.userId,
          ));
        }
      }
    }

    // Group by date
    final grouped = <String, List<FileEntry>>{};
    for (final e in fileEntries) {
      final key = DateFormat("MMM d, yyyy").format(e.date);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: customGreyColor600,
              ),
            ),
          ),
          ...entry.value.map((fe) => ListTile(
                leading: Icon(_fileIcon(fe.ext), color: inumPrimary, size: 32),
                title: Text(fe.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  "${_formatSize(fe.size)} - ${DateFormat("h:mm a").format(fe.date)}",
                  style: const TextStyle(fontSize: 12, color: customGreyColor500),
                ),
                onTap: () {
                  final url = api.getFileUrl(fe.fileId);
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              )),
        ];
      }).toList(),
    );
  }
}

class FileEntry {
  final String fileId;
  final String name;
  final String ext;
  final int size;
  final DateTime date;
  final String userId;
  const FileEntry({
    required this.fileId,
    required this.name,
    required this.ext,
    required this.size,
    required this.date,
    required this.userId,
  });
}

// --- Links List ---

class LinksList extends StatelessWidget {
  final List<MessageModel> messages;

  const LinksList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final links = MediaFilterService.filterLinks(messages);
    if (links.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 48, color: customGreyColor400),
            SizedBox(height: 8),
            Text("No shared links", style: TextStyle(color: customGreyColor500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: links.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final link = links[index];
        // Extract domain for subtitle
        final uri = Uri.tryParse(link.url);
        final domain = uri?.host ?? "";

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: inumSecondary.withAlpha(30),
            child: const Icon(Icons.link, color: inumSecondary, size: 20),
          ),
          title: Text(
            link.url,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: inumPrimary),
          ),
          subtitle: Text(
            "$domain - ${DateFormat("MMM d, h:mm a").format(link.date)}",
            style: const TextStyle(fontSize: 12, color: customGreyColor500),
          ),
          onTap: () {
            launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication);
          },
        );
      },
    );
  }
}
