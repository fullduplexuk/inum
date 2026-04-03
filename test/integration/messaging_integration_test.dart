// Integration test: Messaging
// Usage: cd ~/Developer/inum && dart run test/integration/messaging_integration_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const baseUrl = 'https://gossip.h1-staging.0p.network';
const loginId = 'c71w5b7h700107510001';
const password = '88aBBvPe!Y';
const testChannelId = 'u3b1865z838cuem45up5nr5axy';

int _passed = 0;
int _failed = 0;
int _total = 0;

void pass(String name) { _passed++; _total++; print('  PASS: $name'); }
void fail(String name, Object error) { _failed++; _total++; print('  FAIL: $name\n        Error: $error'); }

Future<Map<String, String>> login() async {
  final resp = await http.post(
    Uri.parse('$baseUrl/api/v4/users/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'login_id': loginId, 'password': password}),
  );
  final token = resp.headers['token']!;
  final userId = (jsonDecode(resp.body) as Map<String, dynamic>)['id'] as String;
  return {'token': token, 'userId': userId};
}

Future<http.Response> api(String method, String path, String token, {Object? body}) async {
  final uri = Uri.parse('$baseUrl/api/v4$path');
  final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  switch (method) {
    case 'GET': return http.get(uri, headers: headers);
    case 'POST': return http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    case 'PUT': return http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    case 'DELETE': return http.delete(uri, headers: headers);
    default: throw Exception('Unsupported');
  }
}

Future<void> main() async {
  print('=== Messaging Integration Tests ===\n');

  final creds = await login();
  final token = creds['token']!;
  final userId = creds['userId']!;

  // Test 1: Send message
  String? postId;
  final testMsg = 'Integration test ${DateTime.now().millisecondsSinceEpoch}';
  try {
    final resp = await api('POST', '/posts', token, body: {
      'channel_id': testChannelId,
      'message': testMsg,
    });
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final post = jsonDecode(resp.body) as Map<String, dynamic>;
      postId = post['id'] as String;
      pass('Send message succeeds (id=$postId)');
    } else {
      fail('Send message', 'Got ${resp.statusCode}: ${resp.body}');
    }
  } catch (e) {
    fail('Send message', e);
  }

  // Test 2: Fetch and find the message
  if (postId != null) {
    try {
      final resp = await api('GET', '/channels/$testChannelId/posts?page=0&per_page=10', token);
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final posts = data['posts'] as Map<String, dynamic>;
      if (posts.containsKey(postId)) {
        pass('Sent message found in channel posts');
      } else {
        fail('Sent message found', 'Not in posts');
      }
    } catch (e) {
      fail('Fetch posts', e);
    }
  }

  // Test 3: Edit message
  if (postId != null) {
    final editedMsg = '$testMsg [EDITED]';
    try {
      final resp = await api('PUT', '/posts/$postId', token, body: {
        'id': postId,
        'message': editedMsg,
      });
      if (resp.statusCode == 200) {
        final post = jsonDecode(resp.body) as Map<String, dynamic>;
        if (post['message'] == editedMsg) {
          pass('Edit message succeeds');
        } else {
          fail('Edit message content', 'Message not updated');
        }
      } else {
        fail('Edit message', 'Got ${resp.statusCode}');
      }
    } catch (e) {
      fail('Edit message', e);
    }
  }

  // Test 4: Add reaction
  if (postId != null) {
    try {
      final resp = await api('POST', '/reactions', token, body: {
        'user_id': userId,
        'post_id': postId,
        'emoji_name': 'thumbsup',
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        pass('Add reaction succeeds');
      } else {
        fail('Add reaction', 'Got ${resp.statusCode}');
      }
    } catch (e) {
      fail('Add reaction', e);
    }
  }

  // Test 5: Remove reaction
  if (postId != null) {
    try {
      final resp = await api('DELETE', '/users/$userId/posts/$postId/reactions/thumbsup', token);
      if (resp.statusCode == 200) {
        pass('Remove reaction succeeds');
      } else {
        fail('Remove reaction', 'Got ${resp.statusCode}');
      }
    } catch (e) {
      fail('Remove reaction', e);
    }
  }

  // Test 6: Pagination
  try {
    final resp = await api('GET', '/channels/$testChannelId/posts?page=0&per_page=5', token);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final order = data['order'] as List<dynamic>;
    if (order.length <= 5) {
      pass('Pagination respects per_page limit (got ${order.length})');
    } else {
      fail('Pagination', 'Got ${order.length} posts, expected <= 5');
    }
  } catch (e) {
    fail('Pagination', e);
  }

  // Test 7: Get single post
  if (postId != null) {
    try {
      final resp = await api('GET', '/posts/$postId', token);
      if (resp.statusCode == 200) {
        final post = jsonDecode(resp.body) as Map<String, dynamic>;
        if (post['id'] == postId) {
          pass('Get single post succeeds');
        } else {
          fail('Get single post', 'ID mismatch');
        }
      } else {
        fail('Get single post', 'Got ${resp.statusCode}');
      }
    } catch (e) {
      fail('Get single post', e);
    }
  }

  // Test 8: Delete message (cleanup)
  if (postId != null) {
    try {
      final resp = await api('DELETE', '/posts/$postId', token);
      if (resp.statusCode == 200) {
        pass('Delete message succeeds');
      } else {
        fail('Delete message', 'Got ${resp.statusCode}');
      }
    } catch (e) {
      fail('Delete message', e);
    }
  }

  // Test 9: Pin and unpin
  String? pinPostId;
  try {
    final resp = await api('POST', '/posts', token, body: {
      'channel_id': testChannelId,
      'message': 'Pin test ${DateTime.now().millisecondsSinceEpoch}',
    });
    pinPostId = (jsonDecode(resp.body) as Map<String, dynamic>)['id'] as String?;
  } catch (_) {}

  if (pinPostId != null) {
    try {
      final pinResp = await api('POST', '/posts/$pinPostId/pin', token);
      if (pinResp.statusCode == 200) {
        pass('Pin post succeeds');
      } else {
        fail('Pin post', 'Got ${pinResp.statusCode}');
      }

      final unpinResp = await api('POST', '/posts/$pinPostId/unpin', token);
      if (unpinResp.statusCode == 200) {
        pass('Unpin post succeeds');
      } else {
        fail('Unpin post', 'Got ${unpinResp.statusCode}');
      }

      // Cleanup
      await api('DELETE', '/posts/$pinPostId', token);
    } catch (e) {
      fail('Pin/Unpin', e);
      try { await api('DELETE', '/posts/$pinPostId', token); } catch (_) {}
    }
  }

  print('\nResults: $_passed passed, $_failed failed out of $_total tests');
  exit(_failed > 0 ? 1 : 0);
}
