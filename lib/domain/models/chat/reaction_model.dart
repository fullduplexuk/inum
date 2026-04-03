import 'package:equatable/equatable.dart';

class ReactionModel extends Equatable {
  final String userId;
  final String postId;
  final String emojiName;
  final DateTime createAt;

  const ReactionModel({
    required this.userId,
    required this.postId,
    required this.emojiName,
    required this.createAt,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      userId: json['user_id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      emojiName: json['emoji_name'] as String? ?? '',
      createAt: DateTime.fromMillisecondsSinceEpoch(json['create_at'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'post_id': postId,
    'emoji_name': emojiName,
  };

  @override
  List<Object?> get props => [userId, postId, emojiName, createAt];
}
