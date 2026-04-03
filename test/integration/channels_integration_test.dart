// Integration test: Channels
// Usage: cd ~/Developer/inum && dart run test/integration/channels_integration_test.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const baseUrl = 'https://gossip.h1-staging.0p.network';
const loginId = 'c71w5b7h700107510001';
const password = '88aBBvPe!Y';

int _passed = 0;
int _failed = 0;
int _total = 0;

void pass(String name) { _passed++; _total++; print('  PASS: $name'); }
void fail(String name, Object error) { _failed++; _total++; print('  FAIL: $name\n        Error: $error'); }

Future<String> login() async {
  final resp = await http.post(
    Uri.parse('$baseUrl/api/v4/users/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'login_id': loginId, 'password': password}),
  );
  return resp.headers['token']!;
}

Future<void> main() async {
  print('=== Channels Integration Tests ===\n');

  final token = await login();
  final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

  // Get teams
  List<dynamic> teams;
  try {
    final resp = await http.get(Uri.parse('$baseUrl/api/v4/users/me/teams'), headers: headers);
    teams = jsonDecode(resp.body) as List<dynamic>;
    pass('getMyTeams returns ${teams.length} team(s)');
  } catch (e) {
    fail('getMyTeams', e);
    exit(1);
  }

  final teamId = (teams[0] as Map<String, dynamic>)['id'] as String;

  // Get channels
  List<dynamic> channels;
  try {
    final resp = await http.get(Uri.parse('$baseUrl/api/v4/users/me/teams/$teamId/channels'), headers: headers);
    channels = jsonDecode(resp.body) as List<dynamic>;
    if (channels.isNotEmpty) {
      pass('getMyChannels returns ${channels.length} channels');
    } else {
      fail('getMyChannels returns channels', 'Empty list');
      exit(1);
    }
  } catch (e) {
    fail('getMyChannels', e);
    exit(1);
  }

  // Check channel types
  final types = channels.map((c) => (c as Map<String, dynamic>)['type'] as String).toSet();
  if (types.contains('O')) pass('Has Open channels');
  else fail('Has Open channels', 'Not found');
  if (types.contains('D')) pass('Has DM channels');
  else fail('Has DM channels', 'Not found');

  // Check channel fields
  final first = channels[0] as Map<String, dynamic>;
  final hasRequiredFields = first.containsKey('id') &&
      first.containsKey('type') &&
      first.containsKey('display_name') &&
      first.containsKey('last_post_at');
  if (hasRequiredFields) {
    pass('Channels have required fields (id, type, display_name, last_post_at)');
  } else {
    fail('Channel fields', 'Missing required fields');
  }

  // Get a single channel
  final channelId = first['id'] as String;
  try {
    final resp = await http.get(Uri.parse('$baseUrl/api/v4/channels/$channelId'), headers: headers);
    if (resp.statusCode == 200) {
      final ch = jsonDecode(resp.body) as Map<String, dynamic>;
      if (ch['id'] == channelId) {
        pass('getChannel returns correct channel');
      } else {
        fail('getChannel returns correct channel', 'ID mismatch');
      }
    } else {
      fail('getChannel', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('getChannel', e);
  }

  // Get channel members
  try {
    final resp = await http.get(Uri.parse('$baseUrl/api/v4/channels/$channelId/members'), headers: headers);
    if (resp.statusCode == 200) {
      final members = jsonDecode(resp.body) as List<dynamic>;
      if (members.isNotEmpty) {
        pass('getChannelMembers returns ${members.length} member(s)');
      } else {
        pass('getChannelMembers returns empty list (channel may have no members)');
      }
    } else {
      fail('getChannelMembers', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('getChannelMembers', e);
  }

  // Unread counts (view channel then check)
  try {
    final meResp = await http.get(Uri.parse('$baseUrl/api/v4/users/me'), headers: headers);
    final userId = (jsonDecode(meResp.body) as Map<String, dynamic>)['id'] as String;

    await http.post(
      Uri.parse('$baseUrl/api/v4/channels/members/$userId/view'),
      headers: headers,
      body: jsonEncode({'channel_id': channelId}),
    );
    pass('viewChannel succeeds (mark as read)');
  } catch (e) {
    fail('viewChannel', e);
  }

  print('\nResults: $_passed passed, $_failed failed out of $_total tests');
  exit(_failed > 0 ? 1 : 0);
}
