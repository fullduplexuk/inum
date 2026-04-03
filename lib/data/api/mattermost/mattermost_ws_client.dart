import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:inum/core/config/env_config.dart';

class MattermostWsClient {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _token;
  int _seq = 1;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;

  static const int _maxReconnectAttempts = 30;
  static const Duration _pingInterval = Duration(seconds: 30);

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  bool get isConnected => _channel != null;

  Future<void> connect(String token) async {
    _token = token;
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final wsUrl = EnvConfig.instance.mattermostWsUrl;
      debugPrint('WS connecting to $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      // Send auth challenge
      final authMsg = jsonEncode({
        'seq': _seq++,
        'action': 'authentication_challenge',
        'data': {'token': _token},
      });
      _channel!.sink.add(authMsg);

      // Start ping/pong
      _startPingTimer();

      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _reconnectAttempts = 0;
      debugPrint('WS connected successfully');
    } catch (e) {
      debugPrint('WS connection error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data as String);
      final event = message['event'] as String?;

      if (event != null) {
        _eventController.add(message);
      }
    } catch (e) {
      debugPrint('WS message parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('WS error: $error');
    _cleanup();
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('WS connection closed');
    _cleanup();
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_channel != null) {
        try {
          _channel!.sink.add(jsonEncode({
            'seq': _seq++,
            'action': 'ping',
          }));
        } catch (e) {
          debugPrint('WS ping error: $e');
        }
      }
    });
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WS max reconnect attempts reached');
      return;
    }

    final delaySeconds = _calculateBackoff();
    debugPrint('WS reconnecting in ${delaySeconds}s (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectAttempts++;
      _doConnect();
    });
  }

  int _calculateBackoff() {
    final delay = 1 << _reconnectAttempts;
    return delay > 30 ? 30 : delay;
  }

  void userTyping(String channelId) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'seq': _seq++,
        'action': 'user_typing',
        'data': {'channel_id': channelId},
      }));
    } catch (e) {
      debugPrint('WS typing error: $e');
    }
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _cleanup();
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
