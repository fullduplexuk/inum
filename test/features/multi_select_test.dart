import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/chat/message_model.dart";
import "package:inum/presentation/views/chat/widgets/multi_select_bar.dart";

void main() {
  MessageModel _msg({required String id, String message = "Hello"}) {
    final now = DateTime(2025, 1, 1);
    return MessageModel(
      id: id,
      channelId: "ch1",
      userId: "u1",
      message: message,
      createAt: now,
      updateAt: now,
    );
  }

  group("MultiSelectState", () {
    test("selecting messages adds to selection list", () {
      var state = const MultiSelectState(isActive: true);
      expect(state.count, 0);

      state = state.copyWith(
        selectedIds: {...state.selectedIds, "msg-1"},
      );
      expect(state.count, 1);
      expect(state.isSelected("msg-1"), true);

      state = state.copyWith(
        selectedIds: {...state.selectedIds, "msg-2"},
      );
      expect(state.count, 2);
      expect(state.isSelected("msg-2"), true);
    });

    test("deselecting removes from list", () {
      var state = const MultiSelectState(
        isActive: true,
        selectedIds: {"msg-1", "msg-2", "msg-3"},
      );
      expect(state.count, 3);

      final updated = Set<String>.from(state.selectedIds)..remove("msg-2");
      state = state.copyWith(selectedIds: updated);
      expect(state.count, 2);
      expect(state.isSelected("msg-2"), false);
      expect(state.isSelected("msg-1"), true);
      expect(state.isSelected("msg-3"), true);
    });

    test("select all selects all messages", () {
      final messages = [
        _msg(id: "m1"),
        _msg(id: "m2"),
        _msg(id: "m3"),
        _msg(id: "m4"),
      ];

      final allIds = messages.map((m) => m.id).toSet();
      final state = MultiSelectState(isActive: true, selectedIds: allIds);
      expect(state.count, 4);
      for (final m in messages) {
        expect(state.isSelected(m.id), true);
      }
    });

    test("copy combines message texts in order", () {
      final messages = [
        _msg(id: "m1", message: "First"),
        _msg(id: "m2", message: "Second"),
        _msg(id: "m3", message: "Third"),
      ];

      final selectedIds = {"m1", "m3"};
      final combined = combineSelectedMessages(messages, selectedIds);
      expect(combined, "First\nThird");
    });

    test("copy with single message returns just that text", () {
      final messages = [
        _msg(id: "m1", message: "Only one"),
        _msg(id: "m2", message: "Not selected"),
      ];

      final combined = combineSelectedMessages(messages, {"m1"});
      expect(combined, "Only one");
    });

    test("empty selection returns empty string", () {
      final messages = [_msg(id: "m1", message: "Hello")];
      final combined = combineSelectedMessages(messages, {});
      expect(combined, "");
    });

    test("isActive defaults to false", () {
      const state = MultiSelectState();
      expect(state.isActive, false);
      expect(state.count, 0);
    });
  });
}
