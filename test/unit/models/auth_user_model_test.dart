import "package:flutter_test/flutter_test.dart";
import "package:inum/domain/models/auth/auth_user_model.dart";
import "../../helpers/test_data.dart";

void main() {
  group("AuthUserModel", () {
    test("fromJson parses all fields", () {
      final json = TestData.authUserJson();
      final user = AuthUserModel.fromJson(json);
      expect(user.id, "user-123");
      expect(user.username, "testuser");
      expect(user.email, "test@example.com");
      expect(user.firstName, "Test");
      expect(user.lastName, "User");
      expect(user.locale, "en");
      expect(user.status, "online");
    });

    test("fromJson with baseUrl builds profileImageUrl", () {
      final json = TestData.authUserJson();
      final user = AuthUserModel.fromJson(json, baseUrl: "https://mm.example.com");
      expect(user.profileImageUrl, "https://mm.example.com/api/v4/users/user-123/image");
    });

    test("fromJson handles null/missing fields gracefully", () {
      final user = AuthUserModel.fromJson(<String, dynamic>{});
      expect(user.id, "");
      expect(user.username, "");
      expect(user.email, "");
      expect(user.locale, "en");
      expect(user.status, "offline");
    });

    test("toJson round-trips correctly", () {
      final original = TestData.authUser();
      final json = original.toJson();
      expect(json["id"], "user-123");
      expect(json["username"], "testuser");
      expect(json["first_name"], "Test");
      expect(json["last_name"], "User");
    });

    test("empty() creates unauthenticated user", () {
      final user = AuthUserModel.empty();
      expect(user.id, "");
      expect(user.username, "");
      expect(user.isAuthenticated, false);
    });

    test("isAuthenticated returns true when id is not empty", () {
      final user = TestData.authUser();
      expect(user.isAuthenticated, true);
    });

    test("displayName prefers firstName lastName", () {
      final user = TestData.authUser(firstName: "John", lastName: "Doe");
      expect(user.displayName, "John Doe");
    });

    test("displayName falls back to nickname then username", () {
      final user = AuthUserModel(
        id: "u1", username: "jdoe", email: "j@e.com",
        nickname: "Johnny",
      );
      expect(user.displayName, "Johnny");

      final user2 = AuthUserModel(id: "u2", username: "jdoe", email: "j@e.com");
      expect(user2.displayName, "jdoe");
    });

    test("copyWith overrides specified fields", () {
      final user = TestData.authUser();
      final updated = user.copyWith(status: "away", firstName: "Updated");
      expect(updated.status, "away");
      expect(updated.firstName, "Updated");
      expect(updated.id, user.id); // unchanged
    });

    test("equality works via Equatable", () {
      final a = TestData.authUser();
      final b = TestData.authUser();
      expect(a, equals(b));

      final c = TestData.authUser(id: "different");
      expect(a, isNot(equals(c)));
    });
  });
}
