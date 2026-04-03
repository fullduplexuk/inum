import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/chat/reaction_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("ReactionModel", () {
    test("fromJson parses all fields", () {
      final json = {
        "user_id": "u1",
        "post_id": "p1",
        "emoji_name": "heart",
        "create_at": 1704110400000,
      };
      final r = ReactionModel.fromJson(json);
      expect(r.userId, "u1");
      expect(r.postId, "p1");
      expect(r.emojiName, "heart");
      expect(r.createAt.year, 2024);
    });

    test("fromJson handles missing fields", () {
      final r = ReactionModel.fromJson(<String, dynamic>{});
      expect(r.userId, "");
      expect(r.emojiName, "");
    });

    test("toJson serializes correctly", () {
      final r = TestData.reaction(emojiName: "thumbsup");
      final json = r.toJson();
      expect(json["user_id"], "user-123");
      expect(json["emoji_name"], "thumbsup");
      expect(json["post_id"], "msg-1");
    });

    test("equality via Equatable", () {
      final a = TestData.reaction();
      final b = TestData.reaction();
      expect(a, equals(b));

      final c = TestData.reaction(emojiName: "heart");
      expect(a, isNot(equals(c)));
    });
  });
}
