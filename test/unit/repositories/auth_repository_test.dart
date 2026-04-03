import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inum/core/constants/enums/auth_failure_enum.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/domain/models/auth/auth_user_model.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_data.dart';

void main() {
  group('AuthRepository - login flow via cubit', () {
    // We test auth logic primarily through the cubit tests.
    // Here we validate model transformations and error mapping.

    test('AuthUserModel.fromJson used in login flow', () {
      final json = TestData.authUserJson(
        id: 'u1',
        username: 'testuser',
        email: 'test@example.com',
      );
      final user =
          AuthUserModel.fromJson(json, baseUrl: 'https://mm.example.com');
      expect(user.id, 'u1');
      expect(user.isAuthenticated, true);
      expect(user.profileImageUrl,
          'https://mm.example.com/api/v4/users/u1/image');
    });

    test('AuthFailureEnum values match expected states', () {
      expect(AuthFailureEnum.values.length, 4);
      expect(AuthFailureEnum.values,
          contains(AuthFailureEnum.invalidCredentials));
      expect(AuthFailureEnum.values, contains(AuthFailureEnum.networkError));
      expect(AuthFailureEnum.values, contains(AuthFailureEnum.sessionExpired));
      expect(AuthFailureEnum.values, contains(AuthFailureEnum.serverError));
    });

    test('Empty user is not authenticated', () {
      final user = AuthUserModel.empty();
      expect(user.isAuthenticated, false);
      expect(user.id, '');
    });

    test('toJson produces valid JSON for secure storage', () {
      final user = TestData.authUser();
      final json = user.toJson();
      final jsonString = jsonEncode(json);
      expect(jsonString, isNotEmpty);

      // Verify it can be decoded back
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['id'], user.id);
    });
  });
}
