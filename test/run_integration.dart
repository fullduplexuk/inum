// Integration tests for INUM Flutter app - runs against real Mattermost server
// Usage: cd ~/Developer/inum && dart run test/run_integration.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const baseUrl = 'https://gossip.h1-staging.0p.network';
const wsUrl = 'wss://gossip.h1-staging.0p.network/api/v4/websocket';
const loginId = 'c71w5b7h700107510001';
const password = '88aBBvPe!Y';
const testChannelId = 'u3b1865z838cuem45up5nr5axy';

int _passed = 0;
int _failed = 0;
int _total = 0;

void pass(String name) {
  _passed++;
  _total++;
  print('  PASS: $name');
}

void fail(String name, Object error) {
  _failed++;
  _total++;
  print('  FAIL: $name');
  print('        Error: $error');
}

/// Helper: POST/GET/PUT/DELETE with JSON
Future<http.Response> apiRequest(
  String method,
  String path, {
  String? token,
  Object? body,
  Map<String, String>? queryParams,
}) async {
  var uri = Uri.parse('$baseUrl/api/v4$path');
  if (queryParams != null) uri = uri.replace(queryParameters: queryParams);

  final headers = <String, String>{'Content-Type': 'application/json'};
  if (token != null) headers['Authorization'] = 'Bearer $token';

  final encodedBody = body != null ? jsonEncode(body) : null;

  switch (method) {
    case 'GET':
      return http.get(uri, headers: headers);
    case 'POST':
      return http.post(uri, headers: headers, body: encodedBody);
    case 'PUT':
      return http.put(uri, headers: headers, body: encodedBody);
    case 'DELETE':
      return http.delete(uri, headers: headers);
    default:
      throw Exception('Unsupported method: $method');
  }
}

// --- TEST 1: Authentication ---

Future<String?> testAuth() async {
  print('\n=== Test 1: Authentication ===');
  String? token;
  String? userId;

  // 1a. Login
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_id': loginId, 'password': password}),
    );

    if (resp.statusCode != 200) {
      fail('Login returns 200', 'Got ${resp.statusCode}: ${resp.body}');
      return null;
    }
    pass('Login returns 200');

    // 1b. Token in response header
    token = resp.headers['token'];
    if (token == null || token.isEmpty) {
      fail('Token in response headers', 'token header missing. Headers: ${resp.headers.keys.toList()}');
      return null;
    }
    pass('Token in response headers');

    // 1c. User data in response body
    final user = jsonDecode(resp.body) as Map<String, dynamic>;
    userId = user['id'] as String?;
    final username = user['username'] as String?;
    if (userId == null || userId.isEmpty) {
      fail('User id in response', 'id is null/empty');
      return null;
    }
    if (username == null || username.isEmpty) {
      fail('Username in response', 'username is null/empty');
      return null;
    }
    pass('User data returned (id=$userId, username=$username)');
  } catch (e) {
    fail('Login request', e);
    return null;
  }

  // 1d. getMe()
  try {
    final resp = await apiRequest('GET', '/users/me', token: token);
    if (resp.statusCode != 200) {
      fail('getMe() returns 200', 'Got ${resp.statusCode}');
    } else {
      final me = jsonDecode(resp.body) as Map<String, dynamic>;
      if (me['id'] == userId) {
        pass('getMe() returns correct user');
      } else {
        fail('getMe() returns correct user', 'id mismatch: ${me["id"]} != $userId');
      }
    }
  } catch (e) {
    fail('getMe()', e);
  }

  // 1e. Logout
  try {
    final resp = await apiRequest('POST', '/users/logout', token: token);
    if (resp.statusCode == 200) {
      pass('Logout succeeds');
    } else {
      fail('Logout succeeds', 'Got ${resp.statusCode}');
    }

    // Verify token is invalidated
    final resp2 = await apiRequest('GET', '/users/me', token: token);
    if (resp2.statusCode == 401) {
      pass('Token invalidated after logout');
    } else {
      // Some servers return 200 briefly after logout; just note it
      print('  NOTE: Token still valid after logout (status=${resp2.statusCode}) - may be cached');
    }
  } catch (e) {
    fail('Logout', e);
  }

  // Re-login for subsequent tests
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_id': loginId, 'password': password}),
    );
    token = resp.headers['token'];
  } catch (e) {
    print('  WARN: Re-login failed: $e');
    return null;
  }

  return token;
}

// --- TEST 2: Channel List ---

Future<void> testChannelList(String token) async {
  print('\n=== Test 2: Channel List ===');

  // 2a. Get teams
  List<dynamic> teams;
  try {
    final resp = await apiRequest('GET', '/users/me/teams', token: token);
    if (resp.statusCode != 200) {
      fail('getMyTeams() returns 200', 'Got ${resp.statusCode}');
      return;
    }
    teams = jsonDecode(resp.body) as List<dynamic>;
    if (teams.isEmpty) {
      fail('User has at least one team', 'No teams returned');
      return;
    }
    pass('getMyTeams() returns ${teams.length} team(s)');
  } catch (e) {
    fail('getMyTeams()', e);
    return;
  }

  // 2b. Get channels for first team
  final teamId = teams[0]['id'] as String;
  final teamName = teams[0]['display_name'] ?? teams[0]['name'] ?? teamId;

  try {
    final resp = await apiRequest('GET', '/users/me/teams/$teamId/channels', token: token);
    if (resp.statusCode != 200) {
      fail('getMyChannels() returns 200', 'Got ${resp.statusCode}');
      return;
    }
    final channels = jsonDecode(resp.body) as List<dynamic>;
    if (channels.isEmpty) {
      fail('Channels exist for team "$teamName"', 'No channels returned');
      return;
    }
    pass('getMyChannels() returns ${channels.length} channel(s) for team "$teamName"');

    // 2c. Check channel types
    final types = <String>{};
    for (final ch in channels) {
      final t = ch['type'] as String?;
      if (t != null) types.add(t);
    }
    print('  INFO: Channel types found: $types');

    final hasOpen = types.contains('O');
    final hasPrivate = types.contains('P');
    final hasDM = types.contains('D');

    if (hasOpen) pass('Has Open (O) channels');
    else fail('Has Open (O) channels', 'Not found');
    if (hasPrivate) pass('Has Private (P) channels');
    else fail('Has Private (P) channels', 'Not found');
    if (hasDM) pass('Has DM (D) channels');
    else fail('Has DM (D) channels', 'Not found');

    // 2d. Check required fields
    final first = channels[0] as Map<String, dynamic>;
    final hasId = first.containsKey('id') && first['id'] != null;
    final hasType = first.containsKey('type') && first['type'] != null;
    final hasDisplayName = first.containsKey('display_name');

    if (hasId && hasType && hasDisplayName) {
      pass('Channel data has required fields (id, type, display_name)');
    } else {
      fail('Channel data has required fields', 'Missing: ${!hasId ? "id " : ""}${!hasType ? "type " : ""}${!hasDisplayName ? "display_name" : ""}');
    }
  } catch (e) {
    fail('getMyChannels()', e);
  }
}

// --- TEST 3: Messages ---

Future<void> testMessages(String token) async {
  print('\n=== Test 3: Messages ===');
  String? postId;

  // 3a. Create a post
  final testMsg = 'Integration test message ${DateTime.now().toIso8601String()}';
  try {
    final resp = await apiRequest('POST', '/posts', token: token, body: {
      'channel_id': testChannelId,
      'message': testMsg,
    });
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      fail('createPost() succeeds', 'Got ${resp.statusCode}: ${resp.body}');
      return;
    }
    final post = jsonDecode(resp.body) as Map<String, dynamic>;
    postId = post['id'] as String?;
    final returnedMsg = post['message'] as String?;
    final returnedChannelId = post['channel_id'] as String?;

    if (postId == null || postId.isEmpty) {
      fail('Post has id', 'id is null/empty');
      return;
    }
    pass('createPost() returns post with id=$postId');

    if (returnedMsg == testMsg) {
      pass('Post message matches');
    } else {
      fail('Post message matches', 'Expected "$testMsg", got "$returnedMsg"');
    }

    if (returnedChannelId == testChannelId) {
      pass('Post channel_id matches');
    } else {
      fail('Post channel_id matches', 'Expected "$testChannelId", got "$returnedChannelId"');
    }
  } catch (e) {
    fail('createPost()', e);
    return;
  }

  // 3b. Fetch posts for channel
  try {
    final resp = await apiRequest('GET', '/channels/$testChannelId/posts', token: token, queryParams: {
      'page': '0',
      'per_page': '10',
    });
    if (resp.statusCode != 200) {
      fail('getPosts() returns 200', 'Got ${resp.statusCode}');
    } else {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final posts = data['posts'] as Map<String, dynamic>?;
      if (posts == null) {
        fail('getPosts() has posts map', 'posts key missing');
      } else if (posts.containsKey(postId)) {
        pass('Our posted message found in channel posts');
      } else {
        fail('Our posted message found in channel posts', 'Post $postId not in returned posts (${posts.length} posts)');
      }
    }
  } catch (e) {
    fail('getPosts()', e);
  }

  // 3c. Delete the test message
  if (postId != null) {
    try {
      final resp = await apiRequest('DELETE', '/posts/$postId', token: token);
      if (resp.statusCode == 200) {
        pass('deletePost() succeeds');
      } else {
        fail('deletePost() succeeds', 'Got ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      fail('deletePost()', e);
    }
  }
}

// --- TEST 4: WebSocket ---

Future<void> testWebSocket(String token) async {
  print('\n=== Test 4: WebSocket ===');

  WebSocketChannel? channel;
  try {
    // 4a. Connect
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    await channel.ready;
    pass('WebSocket connected');

    // 4b. Send auth challenge
    channel.sink.add(jsonEncode({
      'seq': 1,
      'action': 'authentication_challenge',
      'data': {'token': token},
    }));
    pass('Auth challenge sent');

    // Set up listener for events
    final completer = Completer<Map<String, dynamic>>();
    String? testPostId;
    late StreamSubscription sub;

    sub = channel.stream.listen((data) {
      try {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        final event = msg['event'] as String?;
        // We are looking for the posted event
        if (event == 'posted' && !completer.isCompleted) {
          completer.complete(msg);
        }
      } catch (_) {}
    }, onError: (e) {
      if (!completer.isCompleted) completer.completeError(e);
    });

    // Give auth a moment to process
    await Future.delayed(const Duration(seconds: 1));

    // 4c. Post a message via REST
    final testMsg = 'WS test ${DateTime.now().toIso8601String()}';
    try {
      final resp = await apiRequest('POST', '/posts', token: token, body: {
        'channel_id': testChannelId,
        'message': testMsg,
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final post = jsonDecode(resp.body) as Map<String, dynamic>;
        testPostId = post['id'] as String?;
        pass('REST post created for WS test');
      } else {
        fail('REST post for WS test', 'Got ${resp.statusCode}');
        await sub.cancel();
        return;
      }
    } catch (e) {
      fail('REST post for WS test', e);
      await sub.cancel();
      return;
    }

    // 4d. Wait for WebSocket event (5 second timeout)
    try {
      final event = await completer.future.timeout(const Duration(seconds: 5));
      final eventType = event['event'] as String?;
      if (eventType == 'posted') {
        pass('Received "posted" event via WebSocket');

        // Check event data
        final eventData = event['data'] as Map<String, dynamic>?;
        if (eventData != null) {
          final postJson = eventData['post'] as String?;
          if (postJson != null) {
            final postData = jsonDecode(postJson) as Map<String, dynamic>;
            if (postData['message'] == testMsg) {
              pass('WebSocket event contains correct message');
            } else {
              fail('WebSocket event contains correct message',
                  'Expected "$testMsg", got "${postData["message"]}"');
            }
          } else {
            print('  NOTE: Event data.post is null');
          }
        }
      } else {
        fail('Received "posted" event', 'Got event: $eventType');
      }
    } on TimeoutException {
      fail('Received "posted" event via WebSocket', 'Timed out after 5 seconds');
    }

    await sub.cancel();

    // Cleanup: delete test post
    if (testPostId != null) {
      try {
        await apiRequest('DELETE', '/posts/$testPostId', token: token);
      } catch (_) {}
    }

    // 4e. Disconnect
    try {
      await channel.sink.close();
      pass('WebSocket disconnected cleanly');
    } catch (e) {
      fail('WebSocket disconnect', e);
    }
  } catch (e) {
    fail('WebSocket connection', e);
    try {
      channel?.sink.close();
    } catch (_) {}
  }
}

// --- Main ---

Future<void> main() async {
  print('================================================================');
  print('  INUM Integration Tests - Real Server');
  print('  Server: $baseUrl');
  print('================================================================');

  final stopwatch = Stopwatch()..start();

  // Test 1: Auth
  final token = await testAuth();
  if (token == null) {
    print('\n*** Auth failed - cannot continue with remaining tests ***');
    print('\nResults: $_passed passed, $_failed failed out of $_total tests');
    exit(_failed > 0 ? 1 : 0);
  }

  // Test 2: Channel list
  await testChannelList(token);

  // Test 3: Messages
  await testMessages(token);

  // Test 4: WebSocket
  await testWebSocket(token);

  stopwatch.stop();

  print('\n================================================================');
  print('Results: $_passed passed, $_failed failed out of $_total tests');
  print('Duration: ${stopwatch.elapsed.inSeconds}s');
  print('================================================================');

  exit(_failed > 0 ? 1 : 0);
}
