import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:inum/core/config/env_config.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/data/api/livekit/livekit_service.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/presentation/blocs/call/call_cubit.dart';
import 'package:inum/presentation/design_system/colors.dart';

/// View shown when a user opens a /join/:roomId link.
/// Generates a token and connects to the LiveKit room.
class JoinMeetingView extends StatefulWidget {
  final String roomId;
  const JoinMeetingView({super.key, required this.roomId});

  @override
  State<JoinMeetingView> createState() => _JoinMeetingViewState();
}

class _JoinMeetingViewState extends State<JoinMeetingView> {
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _joinMeeting();
  }

  Future<void> _joinMeeting() async {
    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      String tokenApiUrl;
      try {
        tokenApiUrl = EnvConfig.instance.livekitTokenApiUrl;
      } catch (_) {
        tokenApiUrl = 'https://lk-api.vista.inum.com';
      }

      final response = await http.post(
        Uri.parse('$tokenApiUrl/meeting/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_name': widget.roomId,
          'participant_name': 'Guest',
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String? ?? '';

        if (token.isNotEmpty && mounted) {
          // Navigate to call screen - the CallCubit will handle connection
          context.read<CallCubit>().initiateCall(
                widget.roomId,
                isVideo: true,
              );
          context.go(RouterEnum.callView.routeName);
          return;
        }
      }

      if (mounted) {
        setState(() {
          _joining = false;
          _error = 'Failed to join meeting. The link may have expired.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = 'Connection error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_joining) ...[
              const CircularProgressIndicator(color: inumSecondary),
              const SizedBox(height: 24),
              const Text(
                'Joining meeting...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                widget.roomId,
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 14,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
            ],
            if (_error != null) ...[
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _joinMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: inumPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(RouterEnum.dashboardView.routeName),
                child: const Text(
                  'Go Home',
                  style: TextStyle(color: inumSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
