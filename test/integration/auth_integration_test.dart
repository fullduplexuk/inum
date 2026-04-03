// Integration test: Authentication
// Usage: cd ~/Developer/inum && dart run test/integration/auth_integration_test.dart

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

Future<void> main() async {
  print('=== Auth Integration Tests ===\n');

  // Test 1: Basic login
  String? token;
  String? userId;
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_id': loginId, 'password': password}),
    );
    if (resp.statusCode == 200) {
      pass('Login succeeds with valid credentials');
      token = resp.headers['token'];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      userId = body['id'] as String?;
    } else {
      fail('Login succeeds', 'Status ${resp.statusCode}');
    }
  } catch (e) {
    fail('Login succeeds', e);
  }

  // Test 2: Token present
  if (token != null && token.isNotEmpty) {
    pass('Token returned in headers');
  } else {
    fail('Token returned in headers', 'Token is null/empty');
    exit(1);
  }

  // Test 3: Invalid credentials
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_id': loginId, 'password': 'wrongpassword'}),
    );
    if (resp.statusCode == 401) {
      pass('Invalid credentials returns 401');
    } else {
      fail('Invalid credentials returns 401', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('Invalid credentials returns 401', e);
  }

  // Test 4: getMe with valid token
  try {
    final resp = await http.get(
      Uri.parse('$baseUrl/api/v4/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      final me = jsonDecode(resp.body) as Map<String, dynamic>;
      if (me['id'] == userId) {
        pass('getMe returns correct user');
      } else {
        fail('getMe returns correct user', 'ID mismatch');
      }
    } else {
      fail('getMe returns 200', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('getMe with valid token', e);
  }

  // Test 5: getMe with invalid token
  try {
    final resp = await http.get(
      Uri.parse('$baseUrl/api/v4/users/me'),
      headers: {'Authorization': 'Bearer invalid-token-xyz'},
    );
    if (resp.statusCode == 401) {
      pass('getMe with invalid token returns 401');
    } else {
      fail('getMe with invalid token returns 401', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('getMe with invalid token', e);
  }

  // Test 6: User data has expected fields
  try {
    final resp = await http.get(
      Uri.parse('$baseUrl/api/v4/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final me = jsonDecode(resp.body) as Map<String, dynamic>;
    final requiredFields = ['id', 'username', 'email', 'first_name', 'last_name'];
    final missing = requiredFields.where((f) => !me.containsKey(f)).toList();
    if (missing.isEmpty) {
      pass('User data has all required fields');
    } else {
      fail('User data has all required fields', 'Missing: $missing');
    }
  } catch (e) {
    fail('User data fields', e);
  }

  // Test 7: Update status
  try {
    final resp = await http.put(
      Uri.parse('$baseUrl/api/v4/users/$userId/status'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'status': 'online'}),
    );
    if (resp.statusCode == 200) {
      pass('Update status succeeds');
    } else {
      fail('Update status', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('Update status', e);
  }

  // Test 8: Logout
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/users/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) {
      pass('Logout succeeds');
    } else {
      fail('Logout', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('Logout', e);
  }

  // Test 9: Re-login after logout
  try {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v4/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login_id': loginId, 'password': password}),
    );
    if (resp.statusCode == 200) {
      pass('Re-login after logout succeeds');
    } else {
      fail('Re-login after logout', 'Got ${resp.statusCode}');
    }
  } catch (e) {
    fail('Re-login after logout', e);
  }

  print('\nResults: $_passed passed, $_failed failed out of $_total tests');
  exit(_failed > 0 ? 1 : 0);
}
