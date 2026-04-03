import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String id;
  final String channelId;
  final String userId;
  final String message;
  final DateTime createAt;
  final DateTime updateAt;
  final DateTime? deleteAt;
  final String rootId;
  final String type;
  final List<String> fileIds;

  const MessageModel({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.message,
    required this.createAt,
    required this.updateAt,
    this.deleteAt,
    this.rootId = '',
    this.type = '',
    this.fileIds = const [],
  });

  bool get isSystem => type.isNotEmpty && type.startsWith('system');
  bool get isDeleted => deleteAt != null;
  bool get isReply => rootId.isNotEmpty;

  factory MessageModel.fromMattermost(Map<String, dynamic> json) {
    final createAtMs = json['create_at'] as int? ?? 0;
    final updateAtMs = json['update_at'] as int? ?? 0;
    final deleteAtMs = json['delete_at'] as int? ?? 0;
    final rawFileIds = json['file_ids'] as List<dynamic>?;

    return MessageModel(
      id: json['id'] as String? ?? '',
      channelId: json['channel_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createAt: DateTime.fromMillisecondsSinceEpoch(createAtMs),
      updateAt: DateTime.fromMillisecondsSinceEpoch(updateAtMs),
      deleteAt: deleteAtMs > 0 ? DateTime.fromMillisecondsSinceEpoch(deleteAtMs) : null,
      rootId: json['root_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      fileIds: rawFileIds?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  MessageModel copyWith({
    String? id, String? channelId, String? userId, String? message,
    DateTime? createAt, DateTime? updateAt, DateTime? deleteAt,
    String? rootId, String? type, List<String>? fileIds,
  }) {
    return MessageModel(
      id: id ?? this.id, channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId, message: message ?? this.message,
      createAt: createAt ?? this.createAt, updateAt: updateAt ?? this.updateAt,
      deleteAt: deleteAt ?? this.deleteAt, rootId: rootId ?? this.rootId,
      type: type ?? this.type, fileIds: fileIds ?? this.fileIds,
    );
  }

  @override
  List<Object?> get props => [
        id, channelId, userId, message, createAt,
        updateAt, deleteAt, rootId, type, fileIds,
      ];
}
