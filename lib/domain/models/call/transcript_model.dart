import 'package:equatable/equatable.dart';

class TranscriptSegment extends Equatable {
  final String speakerId;
  final String speakerName;
  final Duration startTime;
  final Duration endTime;
  final String text;

  const TranscriptSegment({
    required this.speakerId,
    required this.speakerName,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      speakerId: json['speaker_id'] as String? ?? '',
      speakerName: json['speaker_name'] as String? ?? '',
      startTime: Duration(milliseconds: json['start_ms'] as int? ?? 0),
      endTime: Duration(milliseconds: json['end_ms'] as int? ?? 0),
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'speaker_id': speakerId,
        'speaker_name': speakerName,
        'start_ms': startTime.inMilliseconds,
        'end_ms': endTime.inMilliseconds,
        'text': text,
      };

  @override
  List<Object?> get props => [speakerId, speakerName, startTime, endTime, text];
}

class TranscriptModel extends Equatable {
  final String roomId;
  final int durationSeconds;
  final List<String> speakers;
  final List<TranscriptSegment> segments;

  const TranscriptModel({
    required this.roomId,
    required this.durationSeconds,
    required this.speakers,
    required this.segments,
  });

  factory TranscriptModel.fromJson(Map<String, dynamic> json) {
    return TranscriptModel(
      roomId: json['room_id'] as String? ?? '',
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      speakers: (json['speakers'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      segments: (json['segments'] as List<dynamic>?)
              ?.map((s) =>
                  TranscriptSegment.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'duration_seconds': durationSeconds,
        'speakers': speakers,
        'segments': segments.map((s) => s.toJson()).toList(),
      };

  @override
  List<Object?> get props => [roomId, durationSeconds, speakers, segments];
}
