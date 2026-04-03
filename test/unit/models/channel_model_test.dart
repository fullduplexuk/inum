import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/chat/channel_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("ChannelModel", () {
    test("fromMattermost parses all fields", () {
      final json = TestData.channelJson(id: "c1", type: "O", displayName: "Town Square");
      final ch = ChannelModel.fromMattermost(json);
      expect(ch.id, "c1");
      expect(ch.type, "O");
      expect(ch.displayName, "Town Square");
      expect(ch.teamId, "team-1");
      expect(ch.totalMsgCount, 100);
      expect(ch.unreadCount, 0);
    });

    test("fromMattermost handles missing fields", () {
      final ch = ChannelModel.fromMattermost(<String, dynamic>{});
      expect(ch.id, "");
      expect(ch.type, "O");
      expect(ch.displayName, "");
    });

    test("type helpers return correct values", () {
      expect(TestData.channel(type: "D").isDirect, true);
      expect(TestData.channel(type: "D").isGroup, false);
      expect(TestData.channel(type: "G").isGroup, true);
      expect(TestData.channel(type: "O").isOpen, true);
      expect(TestData.channel(type: "P").isPrivate, true);
      expect(TestData.channel(type: "O").isDirect, false);
    });

    test("copyWith overrides specific fields", () {
      final ch = TestData.channel();
      final updated = ch.copyWith(displayName: "Updated", unreadCount: 5);
      expect(updated.displayName, "Updated");
      expect(updated.unreadCount, 5);
      expect(updated.id, ch.id);
    });

    test("equality works via Equatable", () {
      final a = TestData.channel();
      final b = TestData.channel();
      expect(a, equals(b));

      final c = TestData.channel(id: "different");
      expect(a, isNot(equals(c)));
    });

    test("lastPostAt is parsed from milliseconds", () {
      final ch = ChannelModel.fromMattermost({"last_post_at": 1704067200000});
      expect(ch.lastPostAt.year, 2024);
    });
  });
}
