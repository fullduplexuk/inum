import 'package:equatable/equatable.dart';

class MeetingModel extends Equatable {
  final String id;
  final String title;
  final DateTime scheduledAt;
  final int durationMinutes;
  final List<String> participants;
  final String notes;
  final String channelId;
  final String createdBy;

  const MeetingModel({
    required this.id, required this.title, required this.scheduledAt,
    required this.durationMinutes, required this.participants,
    this.notes = '', this.channelId = '', this.createdBy = '',
  });

  DateTime get endAt => scheduledAt.add(Duration(minutes: durationMinutes));
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());
  bool get isOngoing => DateTime.now().isAfter(scheduledAt) && DateTime.now().isBefore(endAt);

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      scheduledAt: DateTime.tryParse(json['scheduled_at'] as String? ?? '') ?? DateTime.now(),
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      participants: (json['participants'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      notes: json['notes'] as String? ?? '',
      channelId: json['channel_id'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'scheduled_at': scheduledAt.toIso8601String(),
    'duration_minutes': durationMinutes, 'participants': participants,
    'notes': notes, 'channel_id': channelId, 'created_by': createdBy,
  };

  MeetingModel copyWith({String? id, String? title, DateTime? scheduledAt, int? durationMinutes,
    List<String>? participants, String? notes, String? channelId, String? createdBy}) {
    return MeetingModel(id: id ?? this.id, title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt, durationMinutes: durationMinutes ?? this.durationMinutes,
      participants: participants ?? this.participants, notes: notes ?? this.notes,
      channelId: channelId ?? this.channelId, createdBy: createdBy ?? this.createdBy);
  }

  @override
  List<Object?> get props => [id, title, scheduledAt, durationMinutes, participants, notes, channelId, createdBy];
}
