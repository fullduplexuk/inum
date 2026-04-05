import "package:inum/domain/models/chat/message_model.dart";

/// Utility class for filtering media content from message lists.
class MediaFilterService {
  /// Common image file extensions.
  static const _imageExtensions = {
    "png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "heic", "heif", "tiff",
  };

  /// URL regex for extracting links from message text.
  static final _urlRegex = RegExp(
    r'https?://[^\s<>"\)]+',
    caseSensitive: false,
  );

  /// Filter messages that have image attachments.
  static List<MessageModel> filterPhotos(List<MessageModel> messages) {
    return messages.where((m) {
      if (m.fileIds.isEmpty) return false;
      final meta = m.metadata;
      if (meta == null) return m.fileIds.isNotEmpty; // fallback: has files
      final files = meta["files"] as List<dynamic>?;
      if (files == null) return false;
      return files.any((f) {
        final fm = f as Map<String, dynamic>?;
        if (fm == null) return false;
        final ext = (fm["extension"] as String? ?? "").toLowerCase();
        final mimeType = (fm["mime_type"] as String? ?? "").toLowerCase();
        return _imageExtensions.contains(ext) ||
            mimeType.startsWith("image/");
      });
    }).toList();
  }

  /// Filter messages that have non-image file attachments.
  static List<MessageModel> filterFiles(List<MessageModel> messages) {
    return messages.where((m) {
      if (m.fileIds.isEmpty) return false;
      final meta = m.metadata;
      if (meta == null) return false;
      final files = meta["files"] as List<dynamic>?;
      if (files == null) return false;
      return files.any((f) {
        final fm = f as Map<String, dynamic>?;
        if (fm == null) return false;
        final ext = (fm["extension"] as String? ?? "").toLowerCase();
        final mimeType = (fm["mime_type"] as String? ?? "").toLowerCase();
        return !_imageExtensions.contains(ext) &&
            !mimeType.startsWith("image/");
      });
    }).toList();
  }

  /// Extract all URLs from message texts.
  static List<ExtractedLink> filterLinks(List<MessageModel> messages) {
    final links = <ExtractedLink>[];
    for (final m in messages) {
      final matches = _urlRegex.allMatches(m.message);
      for (final match in matches) {
        links.add(ExtractedLink(
          url: match.group(0) ?? "",
          messageId: m.id,
          userId: m.userId,
          date: m.createAt,
        ));
      }
    }
    return links;
  }

  /// Check if a file extension represents an image.
  static bool isImageExtension(String ext) {
    return _imageExtensions.contains(ext.toLowerCase());
  }
}

class ExtractedLink {
  final String url;
  final String messageId;
  final String userId;
  final DateTime date;

  const ExtractedLink({
    required this.url,
    required this.messageId,
    required this.userId,
    required this.date,
  });
}
