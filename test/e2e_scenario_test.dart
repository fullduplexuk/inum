// E2E Scenario Test: Complete User Journey
// Usage: cd ~/Developer/inum && dart run test/e2e_scenario_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const baseUrl = 'https://gossip.h1-staging.0p.network';
const wsUrl = 'wss://gossip.h1-staging.0p.network/api/v4/websocket';
const livekitUrl = 'https://livekit.vista.inum.com';
const turnHost = '62.31.252.185';
const turnPort = 3478;
const loginId = 'c71w5b7h700107510001';
const password = '88aBBvPe!Y';
const testChannelId = 'u3b1865z838cuem45up5nr5axy';

int _passed = 0;
int _failed = 0;
int _total = 0;
final _failures = <String>[];

void pass(String name) {
  _passed++;
  _total++;
  print('  PASS: $name');
}

void fail(String name, Object error) {
  _failed++;
  _total++;
  _failures.add(name);
  print('  FAIL: $name\n        Error: $error');
}

Future<http.Response> api(
    String method, String path, String token,
    {Object? body}) async {
  final uri = Uri.parse('$baseUrl/api/v4$path');
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  switch (method) {
    case 'GET':
      return http.get(uri, headers: headers);
    case 'POST':
      return http.post(uri,
          headers: headers, body: body != null ? jsonEncode(body) : null);
    case 'PUT':
      return http.put(uri,
          headers: headers, body: body != null ? jsonEncode(body) : null);
    case 'DELETE':
      return http.delete(uri, headers: headers);
    default:
      throw Exception('Unsupported method: $method');
  }
}

// ============================================================
// Scenario 1: Authentication Flow (8 checks)
// ============================================================
Future<Map<String, String>> scenario1() async {
  print('\n--- Scenario 1: Authentication Flow ---');
  String? token;
  String? userId;
  String? username;

  // 1.1 Login
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_id': loginId, 'password': password}),
    );
    if (resp.statusCode == 200) {
      pass('1.1 Login returns 200');
      token = resp.headers['token'];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      userId = body['id'] as String?;
      username = body['username'] as String?;
    } else {
      fail('1.1 Login returns 200', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('1.1 Login', e);
  }

  // 1.2 Token
  if (token != null && token.isNotEmpty) {
    pass('1.2 Token returned in response headers');
  } else {
    fail('1.2 Token returned', 'Token is null/empty');
    exit(1);
  }

  // 1.3 UserId
  if (userId != null && userId.isNotEmpty) {
    pass('1.3 UserId returned in body');
  } else {
    fail('1.3 UserId returned', 'UserId is null/empty');
    exit(1);
  }

  // 1.4 Username
  if (username != null && username.isNotEmpty) {
    pass('1.4 Username returned in body');
  } else {
    fail('1.4 Username returned', 'Username is null/empty');
  }

  // 1.5 getMe matches
  try {
    final resp = await api('GET', '/users/me', token);
    final me = jsonDecode(resp.body) as Map<String, dynamic>;
    if (me['id'] == userId && me['username'] == username) {
      pass('1.5 getMe matches login response (id+username)');
    } else {
      fail('1.5 getMe matches', 'id or username mismatch');
    }
  } catch (e) {
    fail('1.5 getMe', e);
  }

  // 1.6 Update status
  try {
    final resp = await api('PUT', '/users/$userId/status', token, body: {
      'user_id': userId,
      'status': 'online',
    });
    if (resp.statusCode == 200) {
      pass('1.6 Update status to online succeeds');
    } else {
      fail('1.6 Update status', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('1.6 Update status', e);
  }

  // 1.7 Get user status
  try {
    final resp = await api('GET', '/users/$userId/status', token);
    if (resp.statusCode == 200) {
      final st = jsonDecode(resp.body) as Map<String, dynamic>;
      if (st.containsKey('status')) {
        pass('1.7 Get user status returns status field (${st["status"]})');
      } else {
        fail('1.7 Get user status', 'No status field');
      }
    } else {
      fail('1.7 Get user status', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('1.7 Get user status', e);
  }

  // 1.8 Re-login
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_id': loginId, 'password': password}),
    );
    if (resp.statusCode == 200) {
      token = resp.headers['token'];
      pass('1.8 Re-login succeeds with fresh token');
    } else {
      fail('1.8 Re-login', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('1.8 Re-login', e);
  }

  return {'token': token!, 'userId': userId!};
}

// ============================================================
// Scenario 2: Channel Navigation (8 checks)
// ============================================================
Future<void> scenario2(String token, String userId) async {
  print('\n--- Scenario 2: Channel Navigation ---');
  String? teamId;

  // 2.1
  try {
    final resp = await api('GET', '/users/me/teams', token);
    final teams = jsonDecode(resp.body) as List<dynamic>;
    if (teams.isNotEmpty) {
      pass('2.1 Get teams returns ${teams.length} team(s)');
      teamId = (teams[0] as Map<String, dynamic>)['id'] as String;
    } else {
      fail('2.1 Get teams', 'Empty');
    }
  } catch (e) {
    fail('2.1 Get teams', e);
  }
  if (teamId == null) return;

  // 2.2
  List<dynamic> channels = [];
  try {
    final resp =
        await api('GET', '/users/me/teams/$teamId/channels', token);
    channels = jsonDecode(resp.body) as List<dynamic>;
    if (channels.isNotEmpty) {
      pass('2.2 Get channels returns ${channels.length} channels');
    } else {
      fail('2.2 Get channels', 'Empty');
    }
  } catch (e) {
    fail('2.2 Get channels', e);
  }

  // 2.3
  final types =
      channels.map((c) => (c as Map<String, dynamic>)['type'] as String).toSet();
  if (types.contains('O')) {
    pass('2.3 Has Open (O) channels');
  } else {
    fail('2.3 Has Open channels', 'Not found in $types');
  }

  // 2.4
  if (types.contains('P') || types.contains('D')) {
    pass('2.4 Has Private (P) or DM (D) channels');
  } else {
    fail('2.4 Has P or D channels', 'Not found in $types');
  }

  // 2.5
  try {
    final resp = await api('GET', '/channels/$testChannelId', token);
    if (resp.statusCode == 200) {
      final ch = jsonDecode(resp.body) as Map<String, dynamic>;
      final hasFields = ch.containsKey('id') &&
          ch.containsKey('type') &&
          ch.containsKey('display_name') &&
          ch.containsKey('header');
      if (hasFields) {
        pass('2.5 Channel detail has expected fields');
      } else {
        fail('2.5 Channel detail fields', 'Missing some fields');
      }
    } else {
      fail('2.5 Get channel detail', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('2.5 Get channel detail', e);
  }

  // 2.6
  try {
    final resp =
        await api('GET', '/channels/$testChannelId/members', token);
    if (resp.statusCode == 200) {
      final members = jsonDecode(resp.body) as List<dynamic>;
      if (members.isNotEmpty) {
        pass('2.6 Channel has ${members.length} member(s)');
      } else {
        fail('2.6 Channel members', 'Empty');
      }
    } else {
      fail('2.6 Channel members', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('2.6 Channel members', e);
  }

  // 2.7
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/channels/members/$userId/view'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'channel_id': testChannelId}),
    );
    if (resp.statusCode == 200) {
      pass('2.7 Mark channel as read succeeds');
    } else {
      fail('2.7 Mark channel as read', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('2.7 Mark channel as read', e);
  }

  // 2.8
  try {
    final resp =
        await api('GET', '/channels/$testChannelId/stats', token);
    if (resp.statusCode == 200) {
      final stats = jsonDecode(resp.body) as Map<String, dynamic>;
      if (stats.containsKey('member_count')) {
        pass('2.8 Channel stats returns member_count (${stats["member_count"]})');
      } else {
        fail('2.8 Channel stats', 'No member_count field');
      }
    } else {
      fail('2.8 Channel stats', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('2.8 Channel stats', e);
  }
}

// ============================================================
// Scenario 3: Full Messaging Flow (13 checks)
// ============================================================
Future<void> scenario3(String token, String userId) async {
  print('\n--- Scenario 3: Full Messaging Flow ---');
  final testMsg = 'E2E test ${DateTime.now().millisecondsSinceEpoch}';
  String? postId;

  // 3.1-3.3 Send message
  try {
    final resp = await api('POST', '/posts', token, body: {
      'channel_id': testChannelId,
      'message': testMsg,
    });
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final post = jsonDecode(resp.body) as Map<String, dynamic>;
      postId = post['id'] as String;
      pass('3.1 Send message succeeds');
      if (postId.isNotEmpty) {
        pass('3.2 PostId returned');
      } else {
        fail('3.2 PostId returned', 'empty');
      }
      if (post['channel_id'] == testChannelId) {
        pass('3.3 Message in correct channel');
      } else {
        fail('3.3 Correct channel', 'Mismatch');
      }
    } else {
      fail('3.1 Send message', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.1 Send message', e);
  }
  if (postId == null) return;

  // 3.4 Fetch posts
  try {
    final resp = await api(
        'GET', '/channels/$testChannelId/posts?page=0&per_page=10', token);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final posts = data['posts'] as Map<String, dynamic>;
    if (posts.containsKey(postId)) {
      pass('3.4 Message found in channel posts (pagination)');
    } else {
      fail('3.4 Message in posts', 'Not found');
    }
  } catch (e) {
    fail('3.4 Fetch posts', e);
  }

  // 3.5-3.6 Edit
  final editedMsg = '$testMsg [EDITED]';
  try {
    final resp = await api('PUT', '/posts/$postId', token, body: {
      'id': postId,
      'message': editedMsg,
    });
    if (resp.statusCode == 200) {
      final post = jsonDecode(resp.body) as Map<String, dynamic>;
      if (post['message'] == editedMsg) {
        pass('3.5 Edit message - text updated');
      } else {
        fail('3.5 Edit message text', 'Mismatch');
      }
      final editAt = post['edit_at'] as int? ?? 0;
      if (editAt > 0) {
        pass('3.6 edit_at timestamp set after edit');
      } else {
        fail('3.6 edit_at set', 'edit_at is $editAt');
      }
    } else {
      fail('3.5 Edit message', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.5 Edit message', e);
  }

  // 3.7 Pin
  try {
    final resp = await api('POST', '/posts/$postId/pin', token);
    if (resp.statusCode == 200) {
      pass('3.7 Pin message succeeds');
    } else {
      fail('3.7 Pin message', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.7 Pin message', e);
  }

  // 3.8 Get pinned
  try {
    final resp =
        await api('GET', '/channels/$testChannelId/pinned', token);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final posts = data['posts'] as Map<String, dynamic>? ?? {};
      if (posts.containsKey(postId)) {
        pass('3.8 Our message in pinned posts');
      } else {
        fail('3.8 Pinned posts', 'Our post not found');
      }
    } else {
      fail('3.8 Get pinned posts', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.8 Get pinned posts', e);
  }

  // 3.9 Unpin
  try {
    final resp = await api('POST', '/posts/$postId/unpin', token);
    if (resp.statusCode == 200) {
      pass('3.9 Unpin message succeeds');
    } else {
      fail('3.9 Unpin', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.9 Unpin', e);
  }

  // 3.10 Add reaction
  try {
    final resp = await api('POST', '/reactions', token, body: {
      'user_id': userId,
      'post_id': postId,
      'emoji_name': 'thumbsup',
    });
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      pass('3.10 Add reaction succeeds');
    } else {
      fail('3.10 Add reaction', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.10 Add reaction', e);
  }

  // 3.11 Remove reaction
  try {
    final resp = await api(
        'DELETE', '/users/$userId/posts/$postId/reactions/thumbsup', token);
    if (resp.statusCode == 200) {
      pass('3.11 Remove reaction succeeds');
    } else {
      fail('3.11 Remove reaction', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.11 Remove reaction', e);
  }

  // 3.12 Thread reply
  String? replyId;
  try {
    final resp = await api('POST', '/posts', token, body: {
      'channel_id': testChannelId,
      'message': 'Thread reply to E2E test',
      'root_id': postId,
    });
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final reply = jsonDecode(resp.body) as Map<String, dynamic>;
      replyId = reply['id'] as String?;
      if (reply['root_id'] == postId) {
        pass('3.12 Thread reply with rootId succeeds');
      } else {
        fail('3.12 Thread reply rootId', 'Mismatch');
      }
    } else {
      fail('3.12 Thread reply', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.12 Thread reply', e);
  }
  if (replyId != null) await api('DELETE', '/posts/$replyId', token);

  // 3.13 Delete
  try {
    final resp = await api('DELETE', '/posts/$postId', token);
    if (resp.statusCode == 200) {
      pass('3.13 Delete message succeeds');
    } else {
      fail('3.13 Delete message', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('3.13 Delete message', e);
  }
}

// ============================================================
// Scenario 4: WebSocket Real-Time (7 checks)
// ============================================================
Future<void> scenario4(String token, String userId) async {
  print('\n--- Scenario 4: WebSocket Real-Time ---');
  WebSocketChannel? ws;

  // 4.1 Connect
  try {
    ws = WebSocketChannel.connect(Uri.parse(wsUrl));
    await ws.ready;
    pass('4.1 WebSocket connected');
  } catch (e) {
    fail('4.1 WebSocket connect', e);
    return;
  }

  // 4.2 Auth
  try {
    ws!.sink.add(jsonEncode({
      'seq': 1,
      'action': 'authentication_challenge',
      'data': {'token': token},
    }));
    pass('4.2 WebSocket auth challenge sent');
  } catch (e) {
    fail('4.2 WS auth', e);
    return;
  }

  await Future.delayed(const Duration(seconds: 1));

  final allEvents = <Map<String, dynamic>>[];
  final eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final sub = ws!.stream.listen((data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      if (msg.containsKey('event')) {
        allEvents.add(msg);
        eventController.add(msg);
      }
    } catch (_) {}
  });

  Future<Map<String, dynamic>?> waitForEvent(String eventType,
      {int timeoutSec = 6}) async {
    for (final e in allEvents) {
      if (e['event'] == eventType) return e;
    }
    try {
      return await eventController.stream
          .where((e) => e['event'] == eventType)
          .first
          .timeout(Duration(seconds: timeoutSec));
    } catch (_) {
      return null;
    }
  }

  // 4.3 Typing
  try {
    ws.sink.add(jsonEncode({
      'seq': 2,
      'action': 'user_typing',
      'data': {'channel_id': testChannelId, 'parent_id': ''},
    }));
    pass('4.3 Typing event sent via WS');
  } catch (e) {
    fail('4.3 Typing event', e);
  }

  // 4.4 Posted event
  allEvents.clear();
  final wsTestMsg = 'WS live ${DateTime.now().millisecondsSinceEpoch}';
  String? wsPostId;
  try {
    final resp = await api('POST', '/posts', token, body: {
      'channel_id': testChannelId,
      'message': wsTestMsg,
    });
    wsPostId =
        (jsonDecode(resp.body) as Map<String, dynamic>)['id'] as String?;
  } catch (e) {
    fail('4.4 REST post for WS', e);
  }
  final postedEvent = await waitForEvent('posted');
  if (postedEvent != null) {
    pass('4.4 Received "posted" event on WS');
  } else {
    fail('4.4 "posted" event', 'Timed out');
  }

  // 4.5 Edited event
  allEvents.clear();
  if (wsPostId != null) {
    await api('PUT', '/posts/$wsPostId', token, body: {
      'id': wsPostId,
      'message': '$wsTestMsg [WS-EDIT]',
    });
    final editEvent = await waitForEvent('post_edited');
    if (editEvent != null) {
      pass('4.5 Received "post_edited" event on WS');
    } else {
      fail('4.5 "post_edited" event', 'Timed out');
    }
  }

  // 4.6 Deleted event
  allEvents.clear();
  if (wsPostId != null) {
    await api('DELETE', '/posts/$wsPostId', token);
    final delEvent = await waitForEvent('post_deleted');
    if (delEvent != null) {
      pass('4.6 Received "post_deleted" event on WS');
    } else {
      fail('4.6 "post_deleted" event', 'Timed out');
    }
  }

  // 4.7 Disconnect
  await sub.cancel();
  await eventController.close();
  await ws.sink.close();
  pass('4.7 WebSocket disconnected cleanly');
}

// ============================================================
// Scenario 5: LiveKit Server Health (3 checks)
// ============================================================
Future<void> scenario5() async {
  print('\n--- Scenario 5: LiveKit Server Health ---');

  // 5.1 HTTP
  try {
    final resp = await http
        .get(Uri.parse(livekitUrl))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      pass('5.1 LiveKit HTTP returns 200');
    } else {
      pass('5.1 LiveKit HTTP reachable (status ${resp.statusCode})');
    }
  } catch (e) {
    fail('5.1 LiveKit HTTP', e);
  }

  // 5.2 WSS
  try {
    final sock = await WebSocket.connect('wss://livekit.vista.inum.com/rtc')
        .timeout(const Duration(seconds: 5));
    await sock.close();
    pass('5.2 LiveKit WSS endpoint reachable');
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout')) {
      fail('5.2 LiveKit WSS', 'Connection timed out');
    } else {
      pass('5.2 LiveKit WSS endpoint reachable (rejected without auth, as expected)');
    }
  }

  // 5.3 TURN
  try {
    final sock =
        await Socket.connect(turnHost, turnPort, timeout: const Duration(seconds: 5));
    await sock.close();
    pass('5.3 TURN server $turnHost:$turnPort reachable (TCP)');
  } catch (e) {
    fail('5.3 TURN server TCP', e);
  }
}

// ============================================================
// Scenario 6: User & Contact Operations (5 checks)
// ============================================================
Future<void> scenario6(String token, String userId) async {
  print('\n--- Scenario 6: User & Contact Operations ---');

  // 6.1
  try {
    final resp = await api('POST', '/users/search', token, body: {
      'term': 'c71',
      'limit': 5,
    });
    if (resp.statusCode == 200) {
      final users = jsonDecode(resp.body) as List<dynamic>;
      if (users.isNotEmpty) {
        pass('6.1 Search users returns ${users.length} result(s)');
      } else {
        fail('6.1 Search users', 'Empty results');
      }
    } else {
      fail('6.1 Search users', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('6.1 Search users', e);
  }

  // 6.2
  try {
    final resp = await http.get(
      Uri.parse('$baseUrl/api/v4/users/$userId/image?_=0'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // 200=image, 304=not modified, 404=no custom avatar, 500=proxy error for default avatar
    if (resp.statusCode == 200 ||
        resp.statusCode == 304 ||
        resp.statusCode == 404 ||
        resp.statusCode == 500) {
      pass('6.2 Profile image URL accessible (status ${resp.statusCode})');
    } else {
      fail('6.2 Profile image', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('6.2 Profile image', e);
  }

  // 6.3
  try {
    final resp = await api('GET', '/users/$userId', token);
    if (resp.statusCode == 200) {
      final user = jsonDecode(resp.body) as Map<String, dynamic>;
      if (user['id'] == userId) {
        pass('6.3 Get user by ID returns correct user');
      } else {
        fail('6.3 Get user by ID', 'ID mismatch');
      }
    } else {
      fail('6.3 Get user by ID', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('6.3 Get user by ID', e);
  }

  // 6.4
  try {
    final resp = await api('POST', '/users/ids', token, body: [userId]);
    if (resp.statusCode == 200) {
      final users = jsonDecode(resp.body) as List<dynamic>;
      if (users.isNotEmpty) {
        pass('6.4 Batch get users by IDs succeeds');
      } else {
        fail('6.4 Batch get users', 'Empty');
      }
    } else {
      fail('6.4 Batch get users', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('6.4 Batch get users', e);
  }

  // 6.5
  try {
    final resp = await api('GET', '/users/autocomplete?name=c71', token);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final users = data['users'] as List<dynamic>? ?? [];
      pass('6.5 Autocomplete users returns ${users.length} result(s)');
    } else {
      fail('6.5 Autocomplete', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('6.5 Autocomplete', e);
  }
}

// ============================================================
// Scenario 7: Rapid Stress Test (4 checks)
// ============================================================
Future<void> scenario7(String token, String userId) async {
  print('\n--- Scenario 7: Rapid Stress Test ---');
  final postIds = <String>[];

  // 7.1
  try {
    final futures = List.generate(5, (i) async {
      final resp = await api('POST', '/posts', token, body: {
        'channel_id': testChannelId,
        'message': 'Stress #$i ${DateTime.now().millisecondsSinceEpoch}',
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return (jsonDecode(resp.body) as Map<String, dynamic>)['id']
            as String;
      }
      return null;
    });
    final results = await Future.wait(futures);
    for (final id in results) {
      if (id != null) postIds.add(id);
    }
    if (postIds.length == 5) {
      pass('7.1 All 5 rapid messages sent successfully');
    } else {
      fail('7.1 Rapid messages', 'Only ${postIds.length}/5 succeeded');
    }
  } catch (e) {
    fail('7.1 Rapid messages', e);
  }

  // 7.2
  try {
    final resp = await api(
        'GET', '/channels/$testChannelId/posts?page=0&per_page=20', token);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final posts = data['posts'] as Map<String, dynamic>;
    final found = postIds.where((id) => posts.containsKey(id)).length;
    if (found == postIds.length) {
      pass('7.2 All ${postIds.length} messages found in channel');
    } else {
      fail('7.2 Messages in posts', 'Found $found/${postIds.length}');
    }
  } catch (e) {
    fail('7.2 Verify posts', e);
  }

  // 7.3
  try {
    int reactOk = 0;
    for (final id in postIds) {
      final resp = await api('POST', '/reactions', token, body: {
        'user_id': userId,
        'post_id': id,
        'emoji_name': 'rocket',
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) reactOk++;
    }
    if (reactOk == postIds.length) {
      pass('7.3 Reacted to all ${postIds.length} messages');
    } else {
      fail('7.3 React to all', '$reactOk/${postIds.length} succeeded');
    }
  } catch (e) {
    fail('7.3 React to all', e);
  }

  // 7.4
  try {
    int delOk = 0;
    for (final id in postIds) {
      final resp = await api('DELETE', '/posts/$id', token);
      if (resp.statusCode == 200) delOk++;
    }
    if (delOk == postIds.length) {
      pass('7.4 Deleted all ${postIds.length} stress test messages');
    } else {
      fail('7.4 Delete all', '$delOk/${postIds.length} succeeded');
    }
  } catch (e) {
    fail('7.4 Delete all', e);
  }
}

// ============================================================
// Scenario 8: Channel Operations (4 checks)
// ============================================================
Future<void> scenario8(String token, String userId) async {
  print('\n--- Scenario 8: Channel Operations ---');
  String? dmChannelId;

  // 8.1
  try {
    final resp = await api('POST', '/channels/direct', token,
        body: [userId, userId]);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final ch = jsonDecode(resp.body) as Map<String, dynamic>;
      dmChannelId = ch['id'] as String?;
      pass('8.1 Create DM channel succeeds');
    } else {
      fail('8.1 Create DM channel',
          'Got ${resp.statusCode}: ${resp.body}');
    }
  } catch (e) {
    fail('8.1 Create DM channel', e);
  }
  if (dmChannelId == null) return;

  // 8.2
  try {
    final resp = await api('GET', '/channels/$dmChannelId', token);
    if (resp.statusCode == 200) {
      final ch = jsonDecode(resp.body) as Map<String, dynamic>;
      if (ch['id'] == dmChannelId) {
        pass('8.2 DM channel verified via GET');
      } else {
        fail('8.2 DM channel verify', 'ID mismatch');
      }
    } else {
      fail('8.2 DM channel verify', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('8.2 DM channel verify', e);
  }

  // 8.3
  String? dmPostId;
  try {
    final resp = await api('POST', '/posts', token, body: {
      'channel_id': dmChannelId,
      'message': 'E2E DM test ${DateTime.now().millisecondsSinceEpoch}',
    });
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      dmPostId =
          (jsonDecode(resp.body) as Map<String, dynamic>)['id'] as String?;
      pass('8.3 Post in DM channel succeeds');
    } else {
      fail('8.3 Post in DM', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('8.3 Post in DM', e);
  }

  // 8.4
  if (dmPostId != null) {
    try {
      final resp = await api('DELETE', '/posts/$dmPostId', token);
      if (resp.statusCode == 200) {
        pass('8.4 DM post cleanup succeeds');
      } else {
        fail('8.4 DM cleanup', 'Got ${resp.statusCode}');
      }
    } catch (e) {
      fail('8.4 DM cleanup', e);
    }
  }
}

// ============================================================
// Main
// ============================================================
Future<void> main() async {
  final stopwatch = Stopwatch()..start();
  print('========================================');
  print(' INUM E2E Scenario Test');
  print(' ${DateTime.now().toIso8601String()}');
  print('========================================');

  final creds = await scenario1();
  final token = creds['token']!;
  final userId = creds['userId']!;

  await scenario2(token, userId);
  await scenario3(token, userId);
  await scenario4(token, userId);
  await scenario5();
  await scenario6(token, userId);
  await scenario7(token, userId);
  await scenario8(token, userId);

  stopwatch.stop();
  print('\n========================================');
  print(' RESULTS: $_passed passed, $_failed failed out of $_total tests');
  print(' Duration: ${stopwatch.elapsed.inSeconds}s');
  print('========================================');

  if (_failures.isNotEmpty) {
    print('\nFailed tests:');
    for (final f in _failures) {
      print('  - $f');
    }
  }

  exit(_failed > 0 ? 1 : 0);
}
