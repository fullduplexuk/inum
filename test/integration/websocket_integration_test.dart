// Integration test: WebSocket
// Usage: cd ~/Developer/inum && dart run test/integration/websocket_integration_test.dart

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

void pass(String name) { _passed++; _total++; print('  PASS: $name'); }
void fail(String name, Object error) { _failed++; _total++; print('  FAIL: $name\n        Error: $error'); }

Future<void> main() async {
  print('=== WebSocket Integration Tests ===\n');

  // Login
  final loginResp = await http.post(
    Uri.parse('$baseUrl/api/v4/users/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'login_id': loginId, 'password': password}),
  );
  final token = loginResp.headers['token']!;
  pass('Login for WS tests');

  // Connect
  WebSocketChannel? channel;
  try {
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    await channel.ready;
    pass('WebSocket connect');

    channel.sink.add(jsonEncode({
      'seq': 1,
      'action': 'authentication_challenge',
      'data': {'token': token},
    }));
    pass('Auth challenge sent');
  } catch (e) {
    fail('WebSocket connect', e);
    exit(1);
  }

  await Future.delayed(const Duration(seconds: 1));

  // Collect all events into a list we can query
  final allEvents = <Map<String, dynamic>>[];
  final eventNotifier = StreamController<void>.broadcast();

  final sub = channel!.stream.listen((data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      if (msg['event'] != null) {
        allEvents.add(msg);
        eventNotifier.add(null);
      }
    } catch (_) {}
  });

  /// Wait for an event of a given type, up to timeout.
  Future<Map<String, dynamic>?> waitForEvent(String eventType, {Duration timeout = const Duration(seconds: 5)}) async {
    // Check already-collected events first
    final existing = allEvents.where((e) => e['event'] == eventType).toList();
    if (existing.isNotEmpty) return existing.last;

    final deadline = DateTime.now().add(timeout);
    await for (final _ in eventNotifier.stream) {
      final found = allEvents.where((e) => e['event'] == eventType).toList();
      if (found.isNotEmpty) return found.last;
      if (DateTime.now().isAfter(deadline)) break;
    }
    return null;
  }

  // Test 2: Receive posted event
  final testMsg = 'WS event test ${DateTime.now().millisecondsSinceEpoch}';
  String? testPostId;

  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/posts'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'channel_id': testChannelId, 'message': testMsg}),
    );
    testPostId = (jsonDecode(resp.body) as Map<String, dynamic>)['id'] as String?;
    pass('REST post created for WS test');
  } catch (e) {
    fail('REST post for WS test', e);
  }

  final postedEvent = await waitForEvent('posted');
  if (postedEvent != null) {
    pass('Received posted event via WS');
    final data = postedEvent['data'] as Map<String, dynamic>? ?? {};
    final postStr = data['post'] as String?;
    if (postStr != null) {
      final postJson = jsonDecode(postStr) as Map<String, dynamic>;
      if (postJson['message'] == testMsg) {
        pass('WS posted event contains correct message');
      } else {
        fail('WS posted event message', 'Mismatch');
      }
    }
  } else {
    fail('Receive posted event', 'Timed out');
  }

  // Clear events for next test
  allEvents.clear();

  // Test 3: Edit triggers post_edited
  if (testPostId != null) {
    try {
      await http.put(
        Uri.parse('$baseUrl/api/v4/posts/$testPostId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'id': testPostId, 'message': '$testMsg [EDITED]'}),
      );
      pass('REST edit for WS test');
    } catch (e) {
      fail('REST edit', e);
    }

    final editedEvent = await waitForEvent('post_edited');
    if (editedEvent != null) {
      pass('Received post_edited event via WS');
    } else {
      fail('Receive post_edited event', 'Timed out');
    }
  }

  // Clear for next test
  allEvents.clear();

  // Test 4: Delete triggers post_deleted
  if (testPostId != null) {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/v4/posts/$testPostId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      pass('REST delete for WS test');
    } catch (e) {
      fail('REST delete', e);
    }

    final deletedEvent = await waitForEvent('post_deleted');
    if (deletedEvent != null) {
      pass('Received post_deleted event via WS');
    } else {
      fail('Receive post_deleted event', 'Timed out');
    }
  }

  // Test 5: Disconnect
  await sub.cancel();
  await eventNotifier.close();
  try {
    await channel.sink.close();
    pass('WebSocket disconnect clean');
  } catch (e) {
    fail('WebSocket disconnect', e);
  }

  print('\nResults: $_passed passed, $_failed failed out of $_total tests');
  exit(_failed > 0 ? 1 : 0);
}
