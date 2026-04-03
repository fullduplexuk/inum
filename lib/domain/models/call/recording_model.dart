import 'package:equatable/equatable.dart';

class RecordingModel extends Equatable {
  final String id;
  final String roomId;
  final String callId;
  final String? compositeUrl;
  final List<String> individualTracks;
  final String? transcriptUrl;
  final String? summaryUrl;
  final int durationSecs;
  final DateTime createdAt;
  final List<String> participants;

  const RecordingModel({
    required this.id,
    required this.roomId,
    required this.callId,
    this.compositeUrl,
    this.individualTracks = const [],
    this.transcriptUrl,
    this.summaryUrl,
    this.durationSecs = 0,
    required this.createdAt,
    this.participants = const [],
  });

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      callId: json['call_id'] as String? ?? '',
      compositeUrl: json['composite_url'] as String?,
      individualTracks: (json['individual_tracks'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
      transcriptUrl: json['transcript_url'] as String?,
      summaryUrl: json['summary_url'] as String?,
      durationSecs: json['duration_secs'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => p as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_id': roomId,
        'call_id': callId,
        'composite_url': compositeUrl,
        'individual_tracks': individualTracks,
        'transcript_url': transcriptUrl,
        'summary_url': summaryUrl,
        'duration_secs': durationSecs,
        'created_at': createdAt.toIso8601String(),
        'participants': participants,
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'room_id': roomId,
        'call_id': callId,
        'composite_url': compositeUrl,
        'individual_tracks': individualTracks.join(','),
        'transcript_url': transcriptUrl,
        'summary_url': summaryUrl,
        'duration_secs': durationSecs,
        'created_at': createdAt.toIso8601String(),
        'participants': participants.join(','),
      };

  factory RecordingModel.fromMap(Map<String, dynamic> map) {
    return RecordingModel(
      id: map['id'] as String,
      roomId: map['room_id'] as String? ?? '',
      callId: map['call_id'] as String? ?? '',
      compositeUrl: map['composite_url'] as String?,
      individualTracks: (map['individual_tracks'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      transcriptUrl: map['transcript_url'] as String?,
      summaryUrl: map['summary_url'] as String?,
      durationSecs: map['duration_secs'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      participants: (map['participants'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        id, roomId, callId, compositeUrl, individualTracks,
        transcriptUrl, summaryUrl, durationSecs, createdAt, participants,
      ];
}
