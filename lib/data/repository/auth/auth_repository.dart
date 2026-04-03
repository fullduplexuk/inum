import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:inum/core/config/env_config.dart';
import 'package:inum/core/constants/enums/auth_failure_enum.dart';
import 'package:inum/core/interfaces/i_auth_repository.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/domain/models/auth/auth_user_model.dart';

class AuthRepository implements IAuthRepository {
  final MattermostApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  final StreamController<AuthUserModel> _authStateController =
      StreamController<AuthUserModel>.broadcast();

  static const _tokenKey = 'mm_token';
  static const _userKey = 'mm_user';

  AuthRepository({
    required MattermostApiClient apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Stream<AuthUserModel> get authStateChanges => _authStateController.stream;

  @override
  Future<Either<AuthFailureEnum, AuthUserModel>> login(String loginId, String password) async {
    try {
      final userData = await _apiClient.login(loginId, password);
      final baseUrl = EnvConfig.instance.mattermostBaseUrl;
      final user = AuthUserModel.fromJson(userData, baseUrl: baseUrl);

      final token = _apiClient.token;
      if (token != null) {
        await _secureStorage.write(key: _tokenKey, value: token);
      }
      await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));

      _authStateController.add(user);
      return Right(user);
    } on MattermostApiException catch (e) {
      debugPrint('Login error: $e');
      if (e.statusCode == 401) {
        return const Left(AuthFailureEnum.invalidCredentials);
      }
      return const Left(AuthFailureEnum.serverError);
    } catch (e) {
      debugPrint('Login error: $e');
      return const Left(AuthFailureEnum.networkError);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.logout();
    } catch (e) {
      debugPrint('Logout API error (ignored): $e');
    }
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
    _authStateController.add(AuthUserModel.empty());
  }

  @override
  Future<Option<AuthUserModel>> getSignedInUser() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final userJson = await _secureStorage.read(key: _userKey);

      if (token == null || userJson == null) {
        return const None();
      }

      _apiClient.setToken(token);

      try {
        final userData = await _apiClient.getMe();
        final baseUrl = EnvConfig.instance.mattermostBaseUrl;
        final user = AuthUserModel.fromJson(userData, baseUrl: baseUrl);
        await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
        _authStateController.add(user);
        return Some(user);
      } on MattermostApiException catch (e) {
        if (e.statusCode == 401) {
          await _secureStorage.delete(key: _tokenKey);
          await _secureStorage.delete(key: _userKey);
          return const None();
        }
        // Network error - use cached user
        final cached = jsonDecode(userJson) as Map<String, dynamic>;
        final user = AuthUserModel(
          id: cached['id'] as String? ?? '',
          username: cached['username'] as String? ?? '',
          email: cached['email'] as String? ?? '',
          firstName: cached['first_name'] as String? ?? '',
          lastName: cached['last_name'] as String? ?? '',
          nickname: cached['nickname'] as String? ?? '',
          position: cached['position'] as String? ?? '',
          locale: cached['locale'] as String? ?? 'en',
          status: cached['status'] as String? ?? 'offline',
          profileImageUrl: cached['profile_image_url'] as String? ?? '',
        );
        _authStateController.add(user);
        return Some(user);
      }
    } catch (e) {
      debugPrint('getSignedInUser error: $e');
      return const None();
    }
  }

  @override
  Future<void> updateStatus(String status) async {
    final userId = _apiClient.currentUserId;
    if (userId == null) return;
    try {
      await _apiClient.updateStatus(userId, status);
    } catch (e) {
      debugPrint('updateStatus error: $e');
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
