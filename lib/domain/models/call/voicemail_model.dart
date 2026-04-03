import 'package:equatable/equatable.dart';

class VoicemailModel extends Equatable {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String? audioUrl;
  final String? transcript;
  final int durationSecs;
  final bool isRead;
  final DateTime createdAt;

  const VoicemailModel({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    this.audioUrl,
    this.transcript,
    this.durationSecs = 0,
    this.isRead = false,
    required this.createdAt,
  });

  VoicemailModel copyWith({
    String? id,
    String? fromUserId,
    String? fromUsername,
    String? audioUrl,
    String? transcript,
    int? durationSecs,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return VoicemailModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      audioUrl: audioUrl ?? this.audioUrl,
      transcript: transcript ?? this.transcript,
      durationSecs: durationSecs ?? this.durationSecs,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'from_user_id': fromUserId,
        'from_username': fromUsername,
        'audio_url': audioUrl,
        'transcript': transcript,
        'duration_secs': durationSecs,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory VoicemailModel.fromMap(Map<String, dynamic> map) {
    return VoicemailModel(
      id: map['id'] as String,
      fromUserId: map['from_user_id'] as String? ?? '',
      fromUsername: map['from_username'] as String? ?? '',
      audioUrl: map['audio_url'] as String?,
      transcript: map['transcript'] as String?,
      durationSecs: map['duration_secs'] as int? ?? 0,
      isRead: (map['is_read'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id, fromUserId, fromUsername, audioUrl,
        transcript, durationSecs, isRead, createdAt,
      ];
}
