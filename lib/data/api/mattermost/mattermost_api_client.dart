import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:inum/core/config/env_config.dart';

class MattermostApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? serverMessage;

  MattermostApiException(this.message, {this.statusCode, this.serverMessage});

  @override
  String toString() {
    final suffix = serverMessage != null ? ' - $serverMessage' : '';
    return 'MattermostApiException($statusCode): $message$suffix';
  }
}

class MattermostApiClient {
  final http.Client _client;
  String? _token;
  String? _currentUserId;

  MattermostApiClient({http.Client? client}) : _client = client ?? http.Client();

  String get _baseUrl => EnvConfig.instance.mattermostBaseUrl;
  String? get token => _token;
  String? get currentUserId => _currentUserId;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('$_baseUrl/api/v4$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: _headers);
        case 'POST':
          response = await _client.post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null);
        case 'PUT':
          response = await _client.put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null);
        case 'DELETE':
          response = await _client.delete(uri, headers: _headers);
        default:
          throw MattermostApiException('Unsupported method: $method');
      }
    } catch (e) {
      if (e is MattermostApiException) rethrow;
      throw MattermostApiException('Network error: $e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      if (decoded is List) return <String, dynamic>{'list': decoded};
      return decoded as Map<String, dynamic>;
    }

    String? serverMsg;
    try {
      final errBody = jsonDecode(response.body);
      serverMsg = errBody['message'] as String?;
    } catch (_) {}

    throw MattermostApiException(
      'Request failed: $method $path',
      statusCode: response.statusCode,
      serverMessage: serverMsg,
    );
  }

  Future<List<dynamic>> _requestList(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('$_baseUrl/api/v4$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: _headers);
        case 'POST':
          response = await _client.post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null);
        default:
          throw MattermostApiException('Unsupported method: $method');
      }
    } catch (e) {
      if (e is MattermostApiException) rethrow;
      throw MattermostApiException('Network error: $e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <dynamic>[];
      return jsonDecode(response.body) as List<dynamic>;
    }

    String? serverMsg;
    try {
      final errBody = jsonDecode(response.body);
      serverMsg = errBody['message'] as String?;
    } catch (_) {}

    throw MattermostApiException(
      'Request failed: $method $path',
      statusCode: response.statusCode,
      serverMessage: serverMsg,
    );
  }

  // --- Auth ---

  Future<Map<String, dynamic>> login(String loginId, String password) async {
    final uri = Uri.parse('$_baseUrl/api/v4/users/login');
    late http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'login_id': loginId, 'password': password}),
      );
    } catch (e) {
      throw MattermostApiException('Network error during login: $e');
    }

    if (response.statusCode == 200) {
      _token = response.headers['token'];
      final userData = jsonDecode(response.body) as Map<String, dynamic>;
      _currentUserId = userData['id'] as String?;
      debugPrint('Login successful, userId: $_currentUserId');
      return userData;
    }

    String? serverMsg;
    try {
      final errBody = jsonDecode(response.body);
      serverMsg = errBody['message'] as String?;
    } catch (_) {}

    throw MattermostApiException(
      'Login failed',
      statusCode: response.statusCode,
      serverMessage: serverMsg,
    );
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/users/logout');
    } finally {
      _token = null;
      _currentUserId = null;
    }
  }

  // --- Users ---

  Future<Map<String, dynamic>> getMe() async {
    return _request('GET', '/users/me');
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    return _request('GET', '/users/$userId');
  }

  Future<List<dynamic>> getUsersByIds(List<String> userIds) async {
    return _requestList('POST', '/users/ids', body: userIds);
  }

  Future<List<dynamic>> searchUsers(String term) async {
    return _requestList('POST', '/users/search', body: {'term': term});
  }

  Future<Map<String, dynamic>> getUserStatus(String userId) async {
    return _request('GET', '/users/$userId/status');
  }

  Future<Map<String, dynamic>> updateStatus(String userId, String status) async {
    return _request('PUT', '/users/$userId/status', body: {
      'user_id': userId,
      'status': status,
    });
  }

  // --- Teams ---

  Future<List<dynamic>> getMyTeams() async {
    return _requestList('GET', '/users/me/teams');
  }

  // --- Channels ---

  Future<List<dynamic>> getMyChannels(String teamId) async {
    return _requestList('GET', '/users/me/teams/$teamId/channels');
  }

  Future<Map<String, dynamic>> getChannel(String channelId) async {
    return _request('GET', '/channels/$channelId');
  }

  Future<Map<String, dynamic>> createDirectChannel(List<String> userIds) async {
    final uri = Uri.parse('$_baseUrl/api/v4/channels/direct');
    late http.Response response;
    try {
      response = await _client.post(uri, headers: _headers, body: jsonEncode(userIds));
    } catch (e) {
      throw MattermostApiException('Network error: $e');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw MattermostApiException('Failed to create direct channel', statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> createGroupChannel(List<String> userIds) async {
    final uri = Uri.parse('$_baseUrl/api/v4/channels/group');
    late http.Response response;
    try {
      response = await _client.post(uri, headers: _headers, body: jsonEncode(userIds));
    } catch (e) {
      throw MattermostApiException('Network error: $e');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw MattermostApiException('Failed to create group channel', statusCode: response.statusCode);
  }

  Future<List<dynamic>> getChannelMembers(String channelId) async {
    return _requestList('GET', '/channels/$channelId/members');
  }

  /// Get all channel memberships for a user (includes msg_count, mention_count for unread calculation)
  Future<List<dynamic>> getChannelMembersForUser(String userId) async {
    return _requestList('GET', '/users/$userId/channel_members');
  }

  // --- Posts ---

  Future<Map<String, dynamic>> getPosts(String channelId, {int page = 0, int perPage = 60}) async {
    return _request('GET', '/channels/$channelId/posts', queryParams: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
  }

  Future<Map<String, dynamic>> createPost(
    String channelId,
    String message, {
    String? rootId,
    List<String>? fileIds,
  }) async {
    final body = <String, dynamic>{
      'channel_id': channelId,
      'message': message,
    };
    if (rootId != null) body['root_id'] = rootId;
    if (fileIds != null && fileIds.isNotEmpty) body['file_ids'] = fileIds;
    return _request('POST', '/posts', body: body);
  }

  Future<Map<String, dynamic>> updatePost(String postId, String message) async {
    return _request('PUT', '/posts/$postId', body: {
      'id': postId,
      'message': message,
    });
  }

  Future<void> deletePost(String postId) async {
    await _request('DELETE', '/posts/$postId');
  }

  Future<void> viewChannel(String channelId) async {
    if (_currentUserId == null) return;
    await _request('POST', '/channels/members/$_currentUserId/view', body: {
      'channel_id': channelId,
    });
  }

  // --- Reactions ---

  Future<Map<String, dynamic>> addReaction(String userId, String postId, String emojiName) async {
    return _request('POST', '/reactions', body: {
      'user_id': userId,
      'post_id': postId,
      'emoji_name': emojiName,
    });
  }

  Future<void> removeReaction(String userId, String postId, String emojiName) async {
    await _request('DELETE', '/reactions/$userId/$postId/$emojiName');
  }

  // --- Threads ---

  Future<Map<String, dynamic>> getThread(String postId) async {
    return _request('GET', '/posts/$postId/thread');
  }

  Future<Map<String, dynamic>> getPost(String postId) async {
    return _request('GET', '/posts/$postId');
  }

  // --- Files ---

  Future<Map<String, dynamic>> uploadFile(String channelId, String filePath, String fileName) async {
    final uri = Uri.parse('$_baseUrl/api/v4/files');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Authorization': 'Bearer ${_token ?? ""}'})
      ..fields['channel_id'] = channelId
      ..files.add(await http.MultipartFile.fromPath('files', filePath, filename: fileName));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw MattermostApiException('File upload failed', statusCode: response.statusCode);
  }

  Future<Map<String, dynamic>> getFileInfo(String fileId) async {
    return _request('GET', '/files/$fileId/info');
  }

  // --- URLs ---

  String getFileUrl(String fileId) => '$_baseUrl/api/v4/files/$fileId';
  String getFileThumbnailUrl(String fileId) => '$_baseUrl/api/v4/files/$fileId/thumbnail';
  String getFilePreviewUrl(String fileId) => '$_baseUrl/api/v4/files/$fileId/preview';
  String getProfileImageUrl(String userId) => '$_baseUrl/api/v4/users/$userId/image';

  // --- Pin/Unpin Posts ---

  Future<Map<String, dynamic>> pinPost(String postId) async {
    return _request('POST', '/posts/$postId/pin');
  }

  Future<Map<String, dynamic>> unpinPost(String postId) async {
    return _request('POST', '/posts/$postId/unpin');
  }

  Future<List<dynamic>> getPinnedPosts(String channelId) async {
    final result = await _request('GET', '/channels/$channelId/pinned');
    final posts = result['posts'] as Map<String, dynamic>? ?? {};
    return posts.values.toList();
  }

  // --- Channel Creation ---

  Future<Map<String, dynamic>> createChannel(Map<String, dynamic> channelData) async {
    return _request('POST', '/channels', body: channelData);
  }

  void dispose() {
    _client.close();
  }
}
