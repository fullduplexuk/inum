import "package:flutter_test/flutter_test.dart";
import "package:hydrated_bloc/hydrated_bloc.dart";
import "package:mocktail/mocktail.dart";
import "package:inum/core/services/blocked_users_service.dart";

class MockStorage extends Mock implements Storage {}

void main() {
  late Storage storage;

  setUp(() {
    storage = MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    when(() => storage.close()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  group("BlockedUsersCubit", () {
    test("blockUser adds to blocked list", () {
      final cubit = BlockedUsersCubit();
      expect(cubit.state.blockedIds, isEmpty);

      cubit.blockUser("user-1");
      expect(cubit.state.blockedIds, contains("user-1"));
      expect(cubit.state.blockedIds.length, 1);

      cubit.blockUser("user-2");
      expect(cubit.state.blockedIds.length, 2);

      cubit.close();
    });

    test("unblockUser removes from list", () {
      final cubit = BlockedUsersCubit();
      cubit.blockUser("user-1");
      cubit.blockUser("user-2");
      expect(cubit.state.blockedIds.length, 2);

      cubit.unblockUser("user-1");
      expect(cubit.state.blockedIds.length, 1);
      expect(cubit.state.blockedIds.contains("user-1"), false);
      expect(cubit.state.blockedIds.contains("user-2"), true);

      cubit.close();
    });

    test("isBlocked returns correct state", () {
      final cubit = BlockedUsersCubit();
      expect(cubit.isBlocked("user-1"), false);

      cubit.blockUser("user-1");
      expect(cubit.isBlocked("user-1"), true);
      expect(cubit.isBlocked("user-2"), false);

      cubit.unblockUser("user-1");
      expect(cubit.isBlocked("user-1"), false);

      cubit.close();
    });

    test("reportUser stores report entry", () {
      final cubit = BlockedUsersCubit();
      expect(cubit.state.reports, isEmpty);

      cubit.reportUser("user-1", "Spam");
      expect(cubit.state.reports.length, 1);
      expect(cubit.state.reports.first.userId, "user-1");
      expect(cubit.state.reports.first.reason, "Spam");

      cubit.close();
    });

    test("blocking same user twice does not duplicate", () {
      final cubit = BlockedUsersCubit();
      cubit.blockUser("user-1");
      cubit.blockUser("user-1");
      expect(cubit.state.blockedIds.length, 1);

      cubit.close();
    });

    test("toJson and fromJson round-trip", () {
      final cubit = BlockedUsersCubit();
      cubit.blockUser("user-1");
      cubit.blockUser("user-2");
      cubit.reportUser("user-3", "Harassment");

      final json = cubit.toJson(cubit.state);
      expect(json, isNotNull);

      final restored = cubit.fromJson(json!);
      expect(restored, isNotNull);
      expect(restored!.blockedIds.length, 2);
      expect(restored.blockedIds.contains("user-1"), true);
      expect(restored.reports.length, 1);
      expect(restored.reports.first.reason, "Harassment");

      cubit.close();
    });
  });

  group("BlockedUsersState", () {
    test("copyWith preserves unmodified fields", () {
      const state = BlockedUsersState(
        blockedIds: {"a", "b"},
        reports: [],
      );
      final updated = state.copyWith(blockedIds: {"a", "b", "c"});
      expect(updated.blockedIds.length, 3);
      expect(updated.reports, isEmpty);
    });
  });

  group("ReportEntry", () {
    test("toJson/fromJson round-trip", () {
      final entry = ReportEntry(
        userId: "u1",
        reason: "Spam",
        reportedAt: DateTime(2025, 6, 1),
      );
      final json = entry.toJson();
      final restored = ReportEntry.fromJson(json);
      expect(restored.userId, "u1");
      expect(restored.reason, "Spam");
    });
  });
}
