import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';

/// A preset custom status option.
class StatusPreset {
  final String emoji;
  final String emojiName;
  final String text;
  final Duration? duration;
  final String durationLabel;

  const StatusPreset({
    required this.emoji,
    required this.emojiName,
    required this.text,
    this.duration,
    this.durationLabel = "Don't clear",
  });
}

/// Represents the current custom status of a user.
class CustomStatus {
  final String emoji;
  final String text;
  final DateTime? expiresAt;

  const CustomStatus({
    required this.emoji,
    required this.text,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String? get remainingTimeText {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inDays > 0) return 'Clears in ${remaining.inDays}d';
    if (remaining.inHours > 0) return 'Clears in ${remaining.inHours}h';
    if (remaining.inMinutes > 0) return 'Clears in ${remaining.inMinutes}m';
    return 'Clearing soon';
  }

  factory CustomStatus.fromJson(Map<String, dynamic> json) {
    final expiresAtStr = json['expires_at'] as String?;
    DateTime? expiresAt;
    if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
      expiresAt = DateTime.tryParse(expiresAtStr);
    }
    return CustomStatus(
      emoji: json['emoji'] as String? ?? '',
      text: json['text'] as String? ?? '',
      expiresAt: expiresAt,
    );
  }
}

/// Common status presets.
const List<StatusPreset> kStatusPresets = [
  StatusPreset(
    emoji: '\u{1F3E2}',
    emojiName: 'office',
    text: 'In a meeting',
    duration: Duration(hours: 1),
    durationLabel: '1 hour',
  ),
  StatusPreset(
    emoji: '\u{1F697}',
    emojiName: 'red_car',
    text: 'Commuting',
    duration: Duration(minutes: 30),
    durationLabel: '30 minutes',
  ),
  StatusPreset(
    emoji: '\u{1F3E0}',
    emojiName: 'house',
    text: 'Working from home',
    duration: Duration(hours: 8),
    durationLabel: 'Today',
  ),
  StatusPreset(
    emoji: '\u{1F912}',
    emojiName: 'face_with_thermometer',
    text: 'Out sick',
    duration: Duration(hours: 8),
    durationLabel: 'Today',
  ),
  StatusPreset(
    emoji: '\u{1F334}',
    emojiName: 'palm_tree',
    text: 'On vacation',
    duration: null,
    durationLabel: "Don't clear",
  ),
];

/// Duration options for custom status expiry.
enum StatusExpiryOption {
  dontClear,
  thirtyMinutes,
  oneHour,
  fourHours,
  today,
}

extension StatusExpiryOptionExt on StatusExpiryOption {
  String get label {
    switch (this) {
      case StatusExpiryOption.dontClear:
        return "Don't clear";
      case StatusExpiryOption.thirtyMinutes:
        return '30 minutes';
      case StatusExpiryOption.oneHour:
        return '1 hour';
      case StatusExpiryOption.fourHours:
        return '4 hours';
      case StatusExpiryOption.today:
        return 'Today';
    }
  }

  DateTime? expiresAt() {
    final now = DateTime.now();
    switch (this) {
      case StatusExpiryOption.dontClear:
        return null;
      case StatusExpiryOption.thirtyMinutes:
        return now.add(const Duration(minutes: 30));
      case StatusExpiryOption.oneHour:
        return now.add(const Duration(hours: 1));
      case StatusExpiryOption.fourHours:
        return now.add(const Duration(hours: 4));
      case StatusExpiryOption.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }
}

/// Available status emojis for the picker.
const List<Map<String, String>> kStatusEmojis = [
  {'emoji': '\u{1F3E2}', 'name': 'office'},
  {'emoji': '\u{1F4F1}', 'name': 'iphone'},
  {'emoji': '\u{1F3E0}', 'name': 'house'},
  {'emoji': '\u{2708}\u{FE0F}', 'name': 'airplane'},
  {'emoji': '\u{1F3AE}', 'name': 'video_game'},
  {'emoji': '\u{1F355}', 'name': 'pizza'},
  {'emoji': '\u{1F4BB}', 'name': 'computer'},
  {'emoji': '\u{1F3C3}', 'name': 'runner'},
  {'emoji': '\u{1F4DA}', 'name': 'books'},
  {'emoji': '\u{2615}', 'name': 'coffee'},
  {'emoji': '\u{1F912}', 'name': 'face_with_thermometer'},
  {'emoji': '\u{1F334}', 'name': 'palm_tree'},
];

/// Service for managing custom user status with expiry.
class CustomStatusService {
  final MattermostApiClient _api;
  Timer? _expiryCheckTimer;
  CustomStatus? _currentStatus;
  VoidCallback? onStatusCleared;

  CustomStatusService({required MattermostApiClient api}) : _api = api;

  CustomStatus? get currentStatus => _currentStatus;

  /// Set a custom status via the Mattermost API.
  Future<void> setCustomStatus({
    required String emoji,
    required String text,
    DateTime? expiresAt,
  }) async {
    final userId = _api.currentUserId;
    if (userId == null) return;

    final body = <String, dynamic>{
      'emoji': emoji,
      'text': text,
    };
    if (expiresAt != null) {
      body['expires_at'] = expiresAt.toUtc().toIso8601String();
    }

    try {
      await _api.setCustomStatus(userId, body);
      _currentStatus = CustomStatus(
        emoji: _emojiNameToUnicode(emoji),
        text: text,
        expiresAt: expiresAt,
      );
      _startExpiryCheck();
    } catch (e) {
      debugPrint('CustomStatus: failed to set: $e');
      rethrow;
    }
  }

  /// Clear the custom status.
  Future<void> clearCustomStatus() async {
    final userId = _api.currentUserId;
    if (userId == null) return;

    try {
      await _api.clearCustomStatus(userId);
      _currentStatus = null;
      _stopExpiryCheck();
    } catch (e) {
      debugPrint('CustomStatus: failed to clear: $e');
      rethrow;
    }
  }

  /// Fetch the current custom status from the server.
  Future<CustomStatus?> fetchCurrentStatus() async {
    final userId = _api.currentUserId;
    if (userId == null) return null;

    try {
      final user = await _api.getMe();
      final props = user['props'] as Map<String, dynamic>? ?? {};
      final customStatusRaw = props['customStatus'];
      if (customStatusRaw == null) {
        _currentStatus = null;
        return null;
      }
      // Mattermost stores custom_status as a JSON object in user props
      try {
        Map<String, dynamic> statusJson;
        if (customStatusRaw is Map) {
          statusJson = Map<String, dynamic>.from(customStatusRaw);
        } else if (customStatusRaw is String && customStatusRaw.isNotEmpty) {
          statusJson = Map<String, dynamic>.from(
            jsonDecode(customStatusRaw) as Map,
          );
        } else {
          _currentStatus = null;
          return null;
        }
        _currentStatus = CustomStatus.fromJson(statusJson);
      } catch (_) {
        _currentStatus = null;
      }
      return _currentStatus;
    } catch (e) {
      debugPrint('CustomStatus: failed to fetch: $e');
      return null;
    }
  }

  void _startExpiryCheck() {
    _stopExpiryCheck();
    if (_currentStatus?.expiresAt == null) return;
    _expiryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_currentStatus?.isExpired == true) {
        clearCustomStatus();
        onStatusCleared?.call();
      }
    });
  }

  void _stopExpiryCheck() {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = null;
  }

  String _emojiNameToUnicode(String name) {
    for (final e in kStatusEmojis) {
      if (e['name'] == name) return e['emoji']!;
    }
    return name;
  }

  void dispose() {
    _stopExpiryCheck();
  }
}
