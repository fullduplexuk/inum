import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/chat/message_model.dart";
import "package:inum/domain/models/chat/reaction_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("MessageModel", () {
    test("fromMattermost parses all fields", () {
      final json = TestData.messageJson(
        id: "p1",
        channelId: "c1",
        userId: "u1",
        message: "Hello",
        rootId: "root-1",
        replyCount: 3,
      );
      final msg = MessageModel.fromMattermost(json);
      expect(msg.id, "p1");
      expect(msg.channelId, "c1");
      expect(msg.userId, "u1");
      expect(msg.message, "Hello");
      expect(msg.rootId, "root-1");
      expect(msg.replyCount, 3);
    });

    test("fromMattermost handles missing fields", () {
      final msg = MessageModel.fromMattermost(<String, dynamic>{});
      expect(msg.id, "");
      expect(msg.message, "");
      expect(msg.deleteAt, isNull);
    });

    test("isEdited returns true when updateAt is sufficiently after createAt", () {
      final base = DateTime(2025, 1, 1, 12, 0);
      final msg = TestData.message(
        createAt: base,
        updateAt: base.add(const Duration(seconds: 5)),
      );
      expect(msg.isEdited, true);
    });

    test("isEdited returns false when times are the same", () {
      final msg = TestData.message();
      expect(msg.isEdited, false);
    });

    test("isDeleted returns true when deleteAt is set", () {
      final msg = TestData.message(deleteAt: DateTime(2025, 1, 2));
      expect(msg.isDeleted, true);
    });

    test("isDeleted returns false when deleteAt is null", () {
      final msg = TestData.message();
      expect(msg.isDeleted, false);
    });

    test("isReply returns true when rootId is not empty", () {
      final msg = TestData.message(rootId: "root-1");
      expect(msg.isReply, true);
    });

    test("hasReplies returns true when replyCount > 0", () {
      final msg = TestData.message(replyCount: 2);
      expect(msg.hasReplies, true);
      expect(TestData.message(replyCount: 0).hasReplies, false);
    });

    test("isSystem detects system messages", () {
      final msg = TestData.message(type: "system_join_channel");
      expect(msg.isSystem, true);
      expect(TestData.message(type: "").isSystem, false);
    });

    test("fromMattermost parses reactions from metadata", () {
      final json = {
        "id": "p1",
        "channel_id": "c1",
        "user_id": "u1",
        "message": "Hello",
        "create_at": 1704110400000,
        "update_at": 1704110400000,
        "delete_at": 0,
        "root_id": "",
        "type": "",
        "metadata": {
          "reactions": [
            {"user_id": "u1", "post_id": "p1", "emoji_name": "thumbsup", "create_at": 1704110400000},
            {"user_id": "u2", "post_id": "p1", "emoji_name": "thumbsup", "create_at": 1704110401000},
          ]
        }
      };
      final msg = MessageModel.fromMattermost(json);
      expect(msg.reactions.length, 2);
      expect(msg.reactions[0].emojiName, "thumbsup");
    });

    test("reactionGroups groups by emoji name", () {
      final msg = TestData.message(reactions: [
        TestData.reaction(userId: "u1", emojiName: "thumbsup"),
        TestData.reaction(userId: "u2", emojiName: "thumbsup"),
        TestData.reaction(userId: "u1", emojiName: "heart"),
      ]);
      final groups = msg.reactionGroups;
      expect(groups["thumbsup"]!.length, 2);
      expect(groups["heart"]!.length, 1);
    });

    test("copyWith preserves and overrides", () {
      final msg = TestData.message();
      final updated = msg.copyWith(message: "Updated");
      expect(updated.message, "Updated");
      expect(updated.id, msg.id);
    });

    test("equality via Equatable", () {
      final a = TestData.message();
      final b = TestData.message();
      expect(a, equals(b));
    });

    test("fromMattermost parses file_ids", () {
      final json = TestData.messageJson();
      json["file_ids"] = ["f1", "f2"];
      final msg = MessageModel.fromMattermost(json);
      expect(msg.fileIds, ["f1", "f2"]);
    });
  });
}
