import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inum/core/config/env_config.dart';

/// Metadata about a generated meeting link.
class MeetingLinkInfo {
  final String roomId;
  final String joinUrl;
  final String creator;
  final DateTime createdAt;
  final DateTime expiresAt;

  const MeetingLinkInfo({
    required this.roomId,
    required this.joinUrl,
    required this.creator,
    required this.createdAt,
    required this.expiresAt,
  });
}

class MeetingLinkService {
  static const String _baseAppUrl = 'https://app.vista.inum.com';

  /// Characters used for generating room codes (no ambiguous chars).
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static final _random = Random.secure();

  /// Pattern that matches an INUM meeting link in text.
  static final RegExp meetingLinkPattern = RegExp(
    r'https://app\.vista\.inum\.com/#/join/(INUM-[A-Z0-9]{4}-[A-Z0-9]{4})',
  );

  /// Generate a short readable room ID: INUM-XXXX-YYYY
  static String generateRoomId() {
    String segment(int len) =>
        List.generate(len, (_) => _chars[_random.nextInt(_chars.length)])
            .join();
    return 'INUM-${segment(4)}-${segment(4)}';
  }

  /// Generate a full meeting link and optionally pre-create the room via the token API.
  static Future<MeetingLinkInfo> generateMeetingLink({
    String creator = '',
    Duration expiry = const Duration(hours: 24),
  }) async {
    final roomId = generateRoomId();
    final now = DateTime.now();
    final joinUrl = '$_baseAppUrl/#/join/$roomId';

    // Try to pre-create room on the token API so it is ready when someone joins
    try {
      final tokenApiUrl = EnvConfig.instance.livekitTokenApiUrl;
      await http.post(
        Uri.parse('$tokenApiUrl/room/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_name': roomId,
          'creator': creator,
          'expires_in_seconds': expiry.inSeconds,
        }),
      );
    } catch (e) {
      debugPrint('Meeting room pre-create failed (non-fatal): $e');
    }

    return MeetingLinkInfo(
      roomId: roomId,
      joinUrl: joinUrl,
      creator: creator,
      createdAt: now,
      expiresAt: now.add(expiry),
    );
  }

  /// Extract a room ID from a message string, or null if none found.
  static String? extractRoomId(String text) {
    final match = meetingLinkPattern.firstMatch(text);
    return match?.group(1);
  }

  /// Check whether a message contains a meeting link.
  static bool containsMeetingLink(String text) =>
      meetingLinkPattern.hasMatch(text);
}
