import 'package:equatable/equatable.dart';

class ChannelModel extends Equatable {
  final String id;
  final String type;
  final String displayName;
  final String header;
  final String purpose;
  final String teamId;
  final DateTime lastPostAt;
  final int totalMsgCount;
  final int unreadCount;
  final List<String> members;

  const ChannelModel({
    required this.id,
    required this.type,
    required this.displayName,
    this.header = '',
    this.purpose = '',
    this.teamId = '',
    required this.lastPostAt,
    this.totalMsgCount = 0,
    this.unreadCount = 0,
    this.members = const [],
  });

  bool get isDirect => type == 'D';
  bool get isGroup => type == 'G';
  bool get isOpen => type == 'O';
  bool get isPrivate => type == 'P';

  factory ChannelModel.fromMattermost(Map<String, dynamic> json) {
    final lastPostAtMs = json['last_post_at'] as int? ?? 0;
    return ChannelModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'O',
      displayName: json['display_name'] as String? ?? '',
      header: json['header'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      lastPostAt: DateTime.fromMillisecondsSinceEpoch(lastPostAtMs),
      totalMsgCount: json['total_msg_count'] as int? ?? 0,
      unreadCount: 0,
      members: const [],
    );
  }

  ChannelModel copyWith({
    String? id, String? type, String? displayName, String? header,
    String? purpose, String? teamId, DateTime? lastPostAt,
    int? totalMsgCount, int? unreadCount, List<String>? members,
  }) {
    return ChannelModel(
      id: id ?? this.id, type: type ?? this.type,
      displayName: displayName ?? this.displayName, header: header ?? this.header,
      purpose: purpose ?? this.purpose, teamId: teamId ?? this.teamId,
      lastPostAt: lastPostAt ?? this.lastPostAt, totalMsgCount: totalMsgCount ?? this.totalMsgCount,
      unreadCount: unreadCount ?? this.unreadCount, members: members ?? this.members,
    );
  }

  @override
  List<Object?> get props => [
        id, type, displayName, header, purpose,
        teamId, lastPostAt, totalMsgCount, unreadCount, members,
      ];
}
