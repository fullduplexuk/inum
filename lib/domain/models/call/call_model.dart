import 'package:equatable/equatable.dart';

enum CallType { audio, video }

enum CallStatus { ringing, active, ended, missed }

enum ConnectionQuality { excellent, good, poor, lost }

class CallParticipant extends Equatable {
  final String userId;
  final String username;
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final bool isSpeaking;
  final ConnectionQuality connectionQuality;

  const CallParticipant({
    required this.userId,
    required this.username,
    this.isAudioEnabled = true,
    this.isVideoEnabled = false,
    this.isSpeaking = false,
    this.connectionQuality = ConnectionQuality.good,
  });

  CallParticipant copyWith({
    String? userId,
    String? username,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isSpeaking,
    ConnectionQuality? connectionQuality,
  }) {
    return CallParticipant(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      connectionQuality: connectionQuality ?? this.connectionQuality,
    );
  }

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      isAudioEnabled: json['is_audio_enabled'] as bool? ?? true,
      isVideoEnabled: json['is_video_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'is_audio_enabled': isAudioEnabled,
        'is_video_enabled': isVideoEnabled,
      };

  @override
  List<Object?> get props => [
        userId,
        username,
        isAudioEnabled,
        isVideoEnabled,
        isSpeaking,
        connectionQuality,
      ];
}

class CallModel extends Equatable {
  final String roomName;
  final String roomId;
  final List<CallParticipant> participants;
  final CallType callType;
  final String initiatedBy;
  final DateTime startedAt;
  final CallStatus status;
  final String channelId;
  final String? livekitUrl;
  final String? livekitToken;

  const CallModel({
    required this.roomName,
    required this.roomId,
    required this.participants,
    required this.callType,
    required this.initiatedBy,
    required this.startedAt,
    required this.status,
    required this.channelId,
    this.livekitUrl,
    this.livekitToken,
  });

  CallModel copyWith({
    String? roomName,
    String? roomId,
    List<CallParticipant>? participants,
    CallType? callType,
    String? initiatedBy,
    DateTime? startedAt,
    CallStatus? status,
    String? channelId,
    String? livekitUrl,
    String? livekitToken,
  }) {
    return CallModel(
      roomName: roomName ?? this.roomName,
      roomId: roomId ?? this.roomId,
      participants: participants ?? this.participants,
      callType: callType ?? this.callType,
      initiatedBy: initiatedBy ?? this.initiatedBy,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
      channelId: channelId ?? this.channelId,
      livekitUrl: livekitUrl ?? this.livekitUrl,
      livekitToken: livekitToken ?? this.livekitToken,
    );
  }

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      roomName: json['room_name'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) =>
                  CallParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      callType:
          json['call_type'] == 'video' ? CallType.video : CallType.audio,
      initiatedBy: json['initiated_by'] as String? ?? '',
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      status: CallStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'ringing'),
        orElse: () => CallStatus.ringing,
      ),
      channelId: json['channel_id'] as String? ?? '',
      livekitUrl: json['livekit_url'] as String?,
      livekitToken: json['livekit_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'room_name': roomName,
        'room_id': roomId,
        'participants': participants.map((p) => p.toJson()).toList(),
        'call_type': callType == CallType.video ? 'video' : 'audio',
        'initiated_by': initiatedBy,
        'started_at': startedAt.toIso8601String(),
        'status': status.name,
        'channel_id': channelId,
        if (livekitUrl != null) 'livekit_url': livekitUrl,
        if (livekitToken != null) 'livekit_token': livekitToken,
      };

  @override
  List<Object?> get props => [
        roomName,
        roomId,
        participants,
        callType,
        initiatedBy,
        startedAt,
        status,
        channelId,
        livekitUrl,
        livekitToken,
      ];
}
