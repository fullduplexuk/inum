import 'package:equatable/equatable.dart';

class SavedMessagesState extends Equatable {
  final List<SavedMessageEntry> savedMessages;

  const SavedMessagesState({this.savedMessages = const []});

  SavedMessagesState copyWith({List<SavedMessageEntry>? savedMessages}) {
    return SavedMessagesState(
      savedMessages: savedMessages ?? this.savedMessages,
    );
  }

  @override
  List<Object?> get props => [savedMessages];
}

class SavedMessageEntry extends Equatable {
  final String messageId;
  final String channelId;
  final String channelName;
  final String messageText;
  final String senderName;
  final DateTime savedAt;

  const SavedMessageEntry({
    required this.messageId,
    required this.channelId,
    this.channelName = '',
    required this.messageText,
    this.senderName = '',
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'channelId': channelId,
        'channelName': channelName,
        'messageText': messageText,
        'senderName': senderName,
        'savedAt': savedAt.millisecondsSinceEpoch,
      };

  factory SavedMessageEntry.fromJson(Map<String, dynamic> json) {
    return SavedMessageEntry(
      messageId: json['messageId'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      channelName: json['channelName'] as String? ?? '',
      messageText: json['messageText'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        json['savedAt'] as int? ?? 0,
      ),
    );
  }

  @override
  List<Object?> get props => [messageId, channelId, channelName, messageText, senderName, savedAt];
}
