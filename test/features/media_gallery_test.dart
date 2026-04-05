import "package:flutter_test/flutter_test.dart";
import "package:inum/core/services/media_filter_service.dart";
import "package:inum/domain/models/chat/message_model.dart";

void main() {
  group("MediaFilterService", () {
    MessageModel _msg({
      String id = "m1",
      String message = "",
      List<String> fileIds = const [],
      Map<String, dynamic>? metadata,
    }) {
      final now = DateTime(2025, 1, 1);
      return MessageModel(
        id: id,
        channelId: "ch1",
        userId: "u1",
        message: message,
        createAt: now,
        updateAt: now,
        fileIds: fileIds,
        metadata: metadata,
      );
    }

    test("filterPhotos returns only image messages", () {
      final messages = [
        _msg(
          id: "img1",
          fileIds: ["f1"],
          metadata: {
            "files": [
              {"id": "f1", "extension": "png", "mime_type": "image/png", "name": "photo.png", "size": 1024},
            ]
          },
        ),
        _msg(
          id: "doc1",
          fileIds: ["f2"],
          metadata: {
            "files": [
              {"id": "f2", "extension": "pdf", "mime_type": "application/pdf", "name": "doc.pdf", "size": 2048},
            ]
          },
        ),
        _msg(id: "txt1", message: "Just text"),
      ];

      final photos = MediaFilterService.filterPhotos(messages);
      expect(photos.length, 1);
      expect(photos.first.id, "img1");
    });

    test("filterFiles returns only non-image file messages", () {
      final messages = [
        _msg(
          id: "img1",
          fileIds: ["f1"],
          metadata: {
            "files": [
              {"id": "f1", "extension": "jpg", "mime_type": "image/jpeg", "name": "pic.jpg", "size": 512},
            ]
          },
        ),
        _msg(
          id: "doc1",
          fileIds: ["f2"],
          metadata: {
            "files": [
              {"id": "f2", "extension": "pdf", "mime_type": "application/pdf", "name": "report.pdf", "size": 4096},
            ]
          },
        ),
        _msg(
          id: "zip1",
          fileIds: ["f3"],
          metadata: {
            "files": [
              {"id": "f3", "extension": "zip", "mime_type": "application/zip", "name": "archive.zip", "size": 8192},
            ]
          },
        ),
      ];

      final files = MediaFilterService.filterFiles(messages);
      expect(files.length, 2);
      expect(files.map((f) => f.id).toSet(), {"doc1", "zip1"});
    });

    test("filterLinks extracts URLs from message text", () {
      final messages = [
        _msg(id: "m1", message: "Check https://example.com/page and http://test.org"),
        _msg(id: "m2", message: "No links here"),
        _msg(id: "m3", message: "Visit https://flutter.dev/docs"),
      ];

      final links = MediaFilterService.filterLinks(messages);
      expect(links.length, 3);
      expect(links[0].url, "https://example.com/page");
      expect(links[1].url, "http://test.org");
      expect(links[2].url, "https://flutter.dev/docs");
    });

    test("filterPhotos handles empty list", () {
      expect(MediaFilterService.filterPhotos([]).isEmpty, true);
    });

    test("filterLinks handles messages without URLs", () {
      final messages = [
        _msg(id: "m1", message: "Hello world"),
        _msg(id: "m2", message: "No URLs at all"),
      ];
      expect(MediaFilterService.filterLinks(messages).isEmpty, true);
    });

    test("isImageExtension checks correctly", () {
      expect(MediaFilterService.isImageExtension("png"), true);
      expect(MediaFilterService.isImageExtension("JPG"), true);
      expect(MediaFilterService.isImageExtension("pdf"), false);
      expect(MediaFilterService.isImageExtension("doc"), false);
    });
  });
}
