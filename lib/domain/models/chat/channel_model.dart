import 'package:equatable/equatable.dart';

class ChannelModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final String displayName;
  final String header;
  final String purpose;
  final String teamId;
  final DateTime lastPostAt;
  final int totalMsgCount;
  final int unreadCount;
  final List<String> members;
  final String lastMessage;

  const ChannelModel({
    required this.id,
    this.name = '',
    required this.type,
    required this.displayName,
    this.header = '',
    this.purpose = '',
    this.teamId = '',
    required this.lastPostAt,
    this.totalMsgCount = 0,
    this.unreadCount = 0,
    this.members = const [],
    this.lastMessage = '',
  });

  bool get isDirect => type == 'D';
  bool get isGroup => type == 'G';
  bool get isOpen => type == 'O';
  bool get isPrivate => type == 'P';

  /// For DM channels, extract the other user ID from the channel name (format: userid1__userid2).
  String? otherUserId(String currentUserId) {
    if (!isDirect) return null;
    final parts = name.split('__');
    if (parts.length != 2) return null;
    return parts[0] == currentUserId ? parts[1] : parts[0];
  }

  factory ChannelModel.fromMattermost(Map<String, dynamic> json) {
    final lastPostAtMs = json['last_post_at'] as int? ?? 0;
    return ChannelModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
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
    String? id,
    String? name,
    String? type,
    String? displayName,
    String? header,
    String? purpose,
    String? teamId,
    DateTime? lastPostAt,
    int? totalMsgCount,
    int? unreadCount,
    List<String>? members,
    String? lastMessage,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      header: header ?? this.header,
      purpose: purpose ?? this.purpose,
      teamId: teamId ?? this.teamId,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      totalMsgCount: totalMsgCount ?? this.totalMsgCount,
      unreadCount: unreadCount ?? this.unreadCount,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  @override
  List<Object?> get props => [
        id, name, type, displayName, header, purpose,
        teamId, lastPostAt, totalMsgCount, unreadCount, members, lastMessage,
      ];
}
