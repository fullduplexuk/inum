import 'package:equatable/equatable.dart';

enum CallRecordStatus {
  completed,
  missed,
  rejected,
  failed,
  forwarded,
  voicemail,
}

enum CallDirection {
  incoming,
  outgoing,
}

class CallRecord extends Equatable {
  final String id;
  final String roomId;
  final String callType;
  final String initiatedBy;
  final String initiatedByUsername;
  final String targetUserId;
  final String targetUsername;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSecs;
  final CallRecordStatus status;
  final CallDirection direction;
  final String? recordingUrl;
  final String? transcriptUrl;

  const CallRecord({
    required this.id,
    required this.roomId,
    required this.callType,
    required this.initiatedBy,
    required this.initiatedByUsername,
    required this.targetUserId,
    required this.targetUsername,
    required this.startedAt,
    this.endedAt,
    this.durationSecs = 0,
    required this.status,
    required this.direction,
    this.recordingUrl,
    this.transcriptUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'room_id': roomId,
        'call_type': callType,
        'initiated_by': initiatedBy,
        'initiated_by_username': initiatedByUsername,
        'target_user_id': targetUserId,
        'target_username': targetUsername,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_secs': durationSecs,
        'status': status.name,
        'direction': direction.name,
        'recording_url': recordingUrl,
        'transcript_url': transcriptUrl,
      };

  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id'] as String,
      roomId: map['room_id'] as String? ?? '',
      callType: map['call_type'] as String? ?? 'audio',
      initiatedBy: map['initiated_by'] as String? ?? '',
      initiatedByUsername: map['initiated_by_username'] as String? ?? '',
      targetUserId: map['target_user_id'] as String? ?? '',
      targetUsername: map['target_username'] as String? ?? '',
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.tryParse(map['ended_at'] as String)
          : null,
      durationSecs: map['duration_secs'] as int? ?? 0,
      status: CallRecordStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'completed'),
        orElse: () => CallRecordStatus.completed,
      ),
      direction: CallDirection.values.firstWhere(
        (d) => d.name == (map['direction'] as String? ?? 'outgoing'),
        orElse: () => CallDirection.outgoing,
      ),
      recordingUrl: map['recording_url'] as String?,
      transcriptUrl: map['transcript_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id, roomId, callType, initiatedBy, initiatedByUsername,
        targetUserId, targetUsername, startedAt, endedAt,
        durationSecs, status, direction, recordingUrl, transcriptUrl,
      ];
}
