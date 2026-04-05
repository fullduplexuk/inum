import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';

/// Duration options for disappearing messages.
enum DisappearingDuration {
  off,
  twentyFourHours,
  sevenDays,
  thirtyDays,
}

extension DisappearingDurationExt on DisappearingDuration {
  String get label {
    switch (this) {
      case DisappearingDuration.off:
        return 'Off';
      case DisappearingDuration.twentyFourHours:
        return '24 hours';
      case DisappearingDuration.sevenDays:
        return '7 days';
      case DisappearingDuration.thirtyDays:
        return '30 days';
    }
  }

  Duration? get duration {
    switch (this) {
      case DisappearingDuration.off:
        return null;
      case DisappearingDuration.twentyFourHours:
        return const Duration(hours: 24);
      case DisappearingDuration.sevenDays:
        return const Duration(days: 7);
      case DisappearingDuration.thirtyDays:
        return const Duration(days: 30);
    }
  }

  String get storageKey {
    switch (this) {
      case DisappearingDuration.off:
        return 'off';
      case DisappearingDuration.twentyFourHours:
        return '24h';
      case DisappearingDuration.sevenDays:
        return '7d';
      case DisappearingDuration.thirtyDays:
        return '30d';
    }
  }

  static DisappearingDuration fromStorageKey(String key) {
    switch (key) {
      case '24h':
        return DisappearingDuration.twentyFourHours;
      case '7d':
        return DisappearingDuration.sevenDays;
      case '30d':
        return DisappearingDuration.thirtyDays;
      default:
        return DisappearingDuration.off;
    }
  }
}

/// Service that manages disappearing messages: stores per-channel settings
/// and periodically deletes expired messages via the Mattermost API.
class DisappearingMessagesService {
  final MattermostApiClient _api;
  Timer? _periodicTimer;

  /// channelId -> DisappearingDuration
  final Map<String, DisappearingDuration> _channelSettings = {};

  DisappearingMessagesService({required MattermostApiClient api}) : _api = api;

  /// All current settings (for persistence).
  Map<String, DisappearingDuration> get channelSettings =>
      Map.unmodifiable(_channelSettings);

  /// Get the setting for a specific channel.
  DisappearingDuration getChannelDuration(String channelId) {
    return _channelSettings[channelId] ?? DisappearingDuration.off;
  }

  /// Returns true if disappearing messages are enabled for the given channel.
  bool isEnabled(String channelId) {
    final d = _channelSettings[channelId];
    return d != null && d != DisappearingDuration.off;
  }

  /// Set the disappearing messages duration for a channel.
  void setChannelDuration(String channelId, DisappearingDuration duration) {
    if (duration == DisappearingDuration.off) {
      _channelSettings.remove(channelId);
    } else {
      _channelSettings[channelId] = duration;
    }
  }

  /// Load settings from a JSON string (call on app start).
  void loadFromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      for (final entry in map.entries) {
        _channelSettings[entry.key] =
            DisappearingDurationExt.fromStorageKey(entry.value as String);
      }
    } catch (e) {
      debugPrint('DisappearingMessages: failed to load settings: $e');
    }
  }

  /// Serialize current settings to JSON string for persistence.
  String toJson() {
    final map = <String, String>{};
    for (final entry in _channelSettings.entries) {
      map[entry.key] = entry.value.storageKey;
    }
    return jsonEncode(map);
  }

  /// Start the periodic cleanup timer (every 5 minutes).
  void startPeriodicCleanup() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      cleanupExpiredMessages();
    });
    // Also run immediately on start.
    cleanupExpiredMessages();
  }

  /// Stop the periodic cleanup timer.
  void stopPeriodicCleanup() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Check all channels and delete expired messages.
  Future<void> cleanupExpiredMessages() async {
    for (final entry in _channelSettings.entries) {
      final channelId = entry.key;
      final duration = entry.value.duration;
      if (duration == null) continue;

      try {
        await _deleteExpiredInChannel(channelId, duration);
      } catch (e) {
        debugPrint('DisappearingMessages: cleanup failed for $channelId: $e');
      }
    }
  }

  /// Delete messages in a specific channel that are older than [maxAge].
  /// Also called when loading messages in chat view.
  Future<List<String>> deleteExpiredInChannel(
      String channelId, Duration maxAge) async {
    return _deleteExpiredInChannel(channelId, maxAge);
  }

  Future<List<String>> _deleteExpiredInChannel(
      String channelId, Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final deletedIds = <String>[];

    try {
      final postsResult = await _api.getPosts(channelId, perPage: 200);
      final posts = postsResult['posts'] as Map<String, dynamic>? ?? {};
      final order = (postsResult['order'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      for (final postId in order) {
        final post = posts[postId] as Map<String, dynamic>?;
        if (post == null) continue;
        final createAtMs = post['create_at'] as int? ?? 0;
        final createAt = DateTime.fromMillisecondsSinceEpoch(createAtMs);
        if (createAt.isBefore(cutoff)) {
          try {
            await _api.deletePost(postId);
            deletedIds.add(postId);
          } catch (e) {
            debugPrint('DisappearingMessages: failed to delete post $postId: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('DisappearingMessages: failed to fetch posts for $channelId: $e');
    }

    return deletedIds;
  }

  /// Check if a message should be marked as expiring soon (last 10% of life).
  bool isExpiringSoon(String channelId, DateTime messageCreateAt) {
    final duration = _channelSettings[channelId]?.duration;
    if (duration == null) return false;
    final expiresAt = messageCreateAt.add(duration);
    final totalMs = duration.inMilliseconds;
    final remainingMs = expiresAt.difference(DateTime.now()).inMilliseconds;
    return remainingMs > 0 && remainingMs < totalMs * 0.1;
  }

  /// Calculate the remaining time for a message.
  Duration? remainingTime(String channelId, DateTime messageCreateAt) {
    final duration = _channelSettings[channelId]?.duration;
    if (duration == null) return null;
    final expiresAt = messageCreateAt.add(duration);
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format remaining time as a human-readable string.
  String? formatRemainingTime(String channelId, DateTime messageCreateAt) {
    final remaining = remainingTime(channelId, messageCreateAt);
    if (remaining == null) return null;
    if (remaining == Duration.zero) return 'Expired';
    if (remaining.inDays > 0) {
      return 'Expires in ${remaining.inDays}d';
    } else if (remaining.inHours > 0) {
      return 'Expires in ${remaining.inHours}h';
    } else if (remaining.inMinutes > 0) {
      return 'Expires in ${remaining.inMinutes}m';
    }
    return 'Expiring now';
  }

  void dispose() {
    stopPeriodicCleanup();
  }
}
