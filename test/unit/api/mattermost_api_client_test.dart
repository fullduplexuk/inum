import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:inum/core/config/env_config.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';

class MockClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockClient mockClient;
  late MattermostApiClient apiClient;

  setUpAll(() async {
    registerFallbackValue(FakeUri());
    // Initialize env with test values so EnvConfig does not throw.
    dotenv.testLoad(fileInput: '''
MATTERMOST_BASE_URL=https://test.example.com
MATTERMOST_WS_URL=wss://test.example.com/api/v4/websocket
''');
    await EnvConfig.instance.initialize();
  });

  setUp(() {
    mockClient = MockClient();
    apiClient = MattermostApiClient(client: mockClient);
  });

  group('MattermostApiClient', () {
    group('login', () {
      test('returns user data and stores token on success', () async {
        final responseBody = jsonEncode({'id': 'u1', 'username': 'testuser'});
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(
              responseBody,
              200,
              headers: {'token': 'test-token-123'},
            ));

        final result = await apiClient.login('user', 'pass');
        expect(result['id'], 'u1');
        expect(result['username'], 'testuser');
        expect(apiClient.token, 'test-token-123');
        expect(apiClient.currentUserId, 'u1');
      });

      test('throws on 401 with error message', () async {
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'message': 'Invalid credentials'}),
              401,
            ));

        expect(
          () => apiClient.login('user', 'wrong'),
          throwsA(isA<MattermostApiException>()),
        );
      });

      test('throws MattermostApiException on network error', () async {
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenThrow(Exception('Connection refused'));

        expect(
          () => apiClient.login('user', 'pass'),
          throwsA(isA<MattermostApiException>()),
        );
      });
    });

    group('token management', () {
      test('setToken updates the token', () {
        apiClient.setToken('new-token');
        expect(apiClient.token, 'new-token');
      });

      test('token is null initially', () {
        expect(apiClient.token, isNull);
      });
    });

    group('getMe', () {
      test('sends GET with auth header', () async {
        apiClient.setToken('my-token');
        when(() => mockClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'id': 'u1'}),
              200,
            ));

        final result = await apiClient.getMe();
        expect(result['id'], 'u1');

        final captured = verify(() => mockClient.get(
              any(),
              headers: captureAny(named: 'headers'),
            )).captured;
        final headers = captured.last as Map<String, String>;
        expect(headers['Authorization'], 'Bearer my-token');
      });
    });

    group('createPost', () {
      test('sends correct body with channel_id and message', () async {
        apiClient.setToken('tok');
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'id': 'p1', 'channel_id': 'ch1', 'message': 'hi'}),
              201,
            ));

        final result = await apiClient.createPost('ch1', 'hi');
        expect(result['id'], 'p1');

        final captured = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;
        final body =
            jsonDecode(captured.last as String) as Map<String, dynamic>;
        expect(body['channel_id'], 'ch1');
        expect(body['message'], 'hi');
      });

      test('includes rootId when provided', () async {
        apiClient.setToken('tok');
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer(
            (_) async => http.Response(jsonEncode({'id': 'p1'}), 201));

        await apiClient.createPost('ch1', 'reply', rootId: 'root-1');

        final captured = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;
        final body =
            jsonDecode(captured.last as String) as Map<String, dynamic>;
        expect(body['root_id'], 'root-1');
      });

      test('includes fileIds when provided', () async {
        apiClient.setToken('tok');
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer(
            (_) async => http.Response(jsonEncode({'id': 'p1'}), 201));

        await apiClient.createPost('ch1', 'with files',
            fileIds: ['f1', 'f2']);

        final captured = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;
        final body =
            jsonDecode(captured.last as String) as Map<String, dynamic>;
        expect(body['file_ids'], ['f1', 'f2']);
      });
    });

    group('error handling', () {
      test('throws with server message on error response', () async {
        apiClient.setToken('tok');
        when(() => mockClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response(
              jsonEncode({'message': 'Not found'}),
              404,
            ));

        try {
          await apiClient.getMe();
          fail('Should throw');
        } on MattermostApiException catch (e) {
          expect(e.statusCode, 404);
          expect(e.serverMessage, 'Not found');
        }
      });

      test('handles empty body on success', () async {
        apiClient.setToken('tok');
        when(() => mockClient.delete(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response('', 200));

        await apiClient.deletePost('p1');
      });
    });

    group('URL builders', () {
      test('getFileUrl builds correct URL', () {
        final url = apiClient.getFileUrl('file-123');
        expect(url, contains('/api/v4/files/file-123'));
      });

      test('getFileThumbnailUrl builds correct URL', () {
        final url = apiClient.getFileThumbnailUrl('file-123');
        expect(url, contains('/api/v4/files/file-123/thumbnail'));
      });

      test('getProfileImageUrl builds correct URL', () {
        final url = apiClient.getProfileImageUrl('user-123');
        expect(url, contains('/api/v4/users/user-123/image'));
      });
    });

    group('logout', () {
      test('clears token and userId after logout', () async {
        apiClient.setToken('tok');
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('', 200));

        await apiClient.logout();
        expect(apiClient.token, isNull);
        expect(apiClient.currentUserId, isNull);
      });

      test('clears token even if API call fails', () async {
        apiClient.setToken('tok');
        when(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenThrow(Exception('network error'));

        // logout uses try/finally, so exception propagates but token is cleared
        try {
          await apiClient.logout();
        } catch (_) {
          // Expected - the network error propagates
        }
        expect(apiClient.token, isNull);
        expect(apiClient.currentUserId, isNull);
      });
    });
  });

  group('MattermostApiException', () {
    test('toString formats correctly', () {
      final e = MattermostApiException('Test error',
          statusCode: 500, serverMessage: 'Internal');
      expect(e.toString(), contains('500'));
      expect(e.toString(), contains('Test error'));
      expect(e.toString(), contains('Internal'));
    });

    test('toString without server message', () {
      final e = MattermostApiException('Test error', statusCode: 404);
      expect(e.toString(), contains('404'));
      expect(e.toString(), isNot(contains('null')));
    });
  });
}
