import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/chat/reaction_model.dart';

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
  final List<ReactionModel> reactions;
  final int replyCount;
  final Map<String, dynamic>? metadata;

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
    this.reactions = const [],
    this.replyCount = 0,
    this.metadata,
  });

  bool get isSystem => type.isNotEmpty && type.startsWith('system');
  bool get isDeleted => deleteAt != null;
  bool get isReply => rootId.isNotEmpty;
  bool get isEdited => updateAt.isAfter(createAt) && updateAt.difference(createAt).inSeconds > 1;
  bool get hasReplies => replyCount > 0;

  factory MessageModel.fromMattermost(Map<String, dynamic> json) {
    final createAtMs = json['create_at'] as int? ?? 0;
    final updateAtMs = json['update_at'] as int? ?? 0;
    final deleteAtMs = json['delete_at'] as int? ?? 0;
    final rawFileIds = json['file_ids'] as List<dynamic>?;
    final rawMetadata = json['metadata'] as Map<String, dynamic>?;

    // Parse reactions from metadata
    List<ReactionModel> reactions = const [];
    if (rawMetadata != null && rawMetadata['reactions'] != null) {
      final rawReactions = rawMetadata['reactions'] as List<dynamic>?;
      reactions = rawReactions
          ?.map((r) => ReactionModel.fromJson(r as Map<String, dynamic>))
          .toList() ?? const [];
    }

    // Reply count
    final replyCount = json['reply_count'] as int? ?? 0;

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
      reactions: reactions,
      replyCount: replyCount,
      metadata: rawMetadata,
    );
  }

  /// Group reactions by emoji name with user IDs
  Map<String, List<String>> get reactionGroups {
    final groups = <String, List<String>>{};
    for (final r in reactions) {
      groups.putIfAbsent(r.emojiName, () => []).add(r.userId);
    }
    return groups;
  }

  MessageModel copyWith({
    String? id, String? channelId, String? userId, String? message,
    DateTime? createAt, DateTime? updateAt, DateTime? deleteAt,
    String? rootId, String? type, List<String>? fileIds,
    List<ReactionModel>? reactions, int? replyCount,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id, channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId, message: message ?? this.message,
      createAt: createAt ?? this.createAt, updateAt: updateAt ?? this.updateAt,
      deleteAt: deleteAt ?? this.deleteAt, rootId: rootId ?? this.rootId,
      type: type ?? this.type, fileIds: fileIds ?? this.fileIds,
      reactions: reactions ?? this.reactions, replyCount: replyCount ?? this.replyCount,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id, channelId, userId, message, createAt,
        updateAt, deleteAt, rootId, type, fileIds,
        reactions, replyCount, metadata,
      ];
}
