/// Factory methods for creating test model instances with realistic data.
import "package:inum/domain/models/auth/auth_user_model.dart";
import "package:inum/domain/models/chat/channel_model.dart";
import "package:inum/domain/models/chat/message_model.dart";
import "package:inum/domain/models/chat/reaction_model.dart";
import "package:inum/domain/models/call/call_model.dart";
import "package:inum/domain/models/call/call_record.dart";
import "package:inum/domain/models/call/transcript_model.dart";
import "package:inum/domain/models/call/recording_model.dart";
import "package:inum/domain/models/call/forwarding_rule.dart";
import "package:inum/domain/models/call/voicemail_model.dart";
import "package:inum/domain/models/sms/sms_model.dart";
import "package:inum/domain/models/meeting/meeting_model.dart";

class TestData {
  static AuthUserModel authUser({
    String id = "user-123",
    String username = "testuser",
    String email = "test@example.com",
    String firstName = "Test",
    String lastName = "User",
  }) =>
      AuthUserModel(
        id: id,
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );

  static Map<String, dynamic> authUserJson({
    String id = "user-123",
    String username = "testuser",
    String email = "test@example.com",
    String firstName = "Test",
    String lastName = "User",
  }) =>
      {
        "id": id,
        "username": username,
        "email": email,
        "first_name": firstName,
        "last_name": lastName,
        "nickname": "",
        "position": "",
        "locale": "en",
        "status": "online",
      };

  static ChannelModel channel({
    String id = "ch-1",
    String type = "O",
    String displayName = "General",
    int unreadCount = 0,
  }) =>
      ChannelModel(
        id: id,
        type: type,
        displayName: displayName,
        lastPostAt: DateTime(2025, 1, 1),
        unreadCount: unreadCount,
      );

  static Map<String, dynamic> channelJson({
    String id = "ch-1",
    String type = "O",
    String displayName = "General",
    int lastPostAt = 1704067200000,
  }) =>
      {
        "id": id,
        "type": type,
        "display_name": displayName,
        "header": "",
        "purpose": "",
        "team_id": "team-1",
        "last_post_at": lastPostAt,
        "total_msg_count": 100,
      };

  static MessageModel message({
    String id = "msg-1",
    String channelId = "ch-1",
    String userId = "user-123",
    String message = "Hello world",
    String rootId = "",
    String type = "",
    int replyCount = 0,
    DateTime? createAt,
    DateTime? updateAt,
    DateTime? deleteAt,
    List<ReactionModel> reactions = const [],
  }) {
    final now = DateTime(2025, 1, 1, 12, 0);
    return MessageModel(
      id: id,
      channelId: channelId,
      userId: userId,
      message: message,
      createAt: createAt ?? now,
      updateAt: updateAt ?? now,
      deleteAt: deleteAt,
      rootId: rootId,
      type: type,
      replyCount: replyCount,
      reactions: reactions,
    );
  }

  static Map<String, dynamic> messageJson({
    String id = "msg-1",
    String channelId = "ch-1",
    String userId = "user-123",
    String message = "Hello world",
    int createAt = 1704110400000,
    int updateAt = 1704110400000,
    int deleteAt = 0,
    String rootId = "",
    String type = "",
    int replyCount = 0,
  }) =>
      {
        "id": id,
        "channel_id": channelId,
        "user_id": userId,
        "message": message,
        "create_at": createAt,
        "update_at": updateAt,
        "delete_at": deleteAt,
        "root_id": rootId,
        "type": type,
        "file_ids": <String>[],
        "reply_count": replyCount,
      };

  static ReactionModel reaction({
    String userId = "user-123",
    String postId = "msg-1",
    String emojiName = "thumbsup",
  }) =>
      ReactionModel(
        userId: userId,
        postId: postId,
        emojiName: emojiName,
        createAt: DateTime(2025, 1, 1),
      );

  static CallModel call({
    String roomName = "call-room-1",
    String roomId = "room-1",
    CallType callType = CallType.audio,
    CallStatus status = CallStatus.ringing,
    String channelId = "ch-1",
    String initiatedBy = "user-123",
  }) =>
      CallModel(
        roomName: roomName,
        roomId: roomId,
        participants: [
          const CallParticipant(userId: "user-123", username: "testuser"),
        ],
        callType: callType,
        initiatedBy: initiatedBy,
        startedAt: DateTime(2025, 1, 1),
        status: status,
        channelId: channelId,
      );

  static CallRecord callRecord({
    String id = "rec-1",
    CallRecordStatus status = CallRecordStatus.completed,
    CallDirection direction = CallDirection.outgoing,
    int durationSecs = 120,
  }) =>
      CallRecord(
        id: id,
        roomId: "room-1",
        callType: "audio",
        initiatedBy: "user-123",
        initiatedByUsername: "testuser",
        targetUserId: "user-456",
        targetUsername: "otheruser",
        startedAt: DateTime(2025, 1, 1),
        endedAt: DateTime(2025, 1, 1, 0, 2),
        durationSecs: durationSecs,
        status: status,
        direction: direction,
      );

  static TranscriptModel transcript() => TranscriptModel(
        roomId: "room-1",
        durationSeconds: 120,
        speakers: ["Alice", "Bob"],
        segments: [
          TranscriptSegment(
            speakerId: "user-1",
            speakerName: "Alice",
            startTime: const Duration(seconds: 0),
            endTime: const Duration(seconds: 5),
            text: "Hello, how are you?",
          ),
          TranscriptSegment(
            speakerId: "user-2",
            speakerName: "Bob",
            startTime: const Duration(seconds: 5),
            endTime: const Duration(seconds: 10),
            text: "I am fine, thanks!",
          ),
        ],
      );

  static RecordingModel recording({String id = "recording-1"}) =>
      RecordingModel(
        id: id,
        roomId: "room-1",
        callId: "call-1",
        compositeUrl: "https://example.com/recording.mp4",
        durationSecs: 120,
        createdAt: DateTime(2025, 1, 1),
        participants: ["user-1", "user-2"],
      );

  static ForwardingRule forwardingRule({
    ForwardingCondition condition = ForwardingCondition.always,
    bool enabled = true,
    String destination = "+441234567890",
  }) =>
      ForwardingRule(
        condition: condition,
        enabled: enabled,
        destination: destination,
      );

  static VoicemailModel voicemail({String id = "vm-1"}) => VoicemailModel(
        id: id,
        fromUserId: "user-456",
        fromUsername: "caller",
        audioUrl: "https://example.com/vm.mp3",
        transcript: "Hi, please call me back.",
        durationSecs: 15,
        createdAt: DateTime(2025, 1, 1),
      );

  static SmsModel sms({String id = "sms-1"}) => SmsModel(
        id: id,
        fromNumber: "+441234567890",
        toNumber: "+449876543210",
        message: "Test SMS message",
        sentAt: DateTime(2025, 1, 1),
      );

  static MeetingModel meeting({String id = "meeting-1"}) => MeetingModel(
        id: id,
        title: "Sprint Planning",
        scheduledAt: DateTime(2025, 6, 1, 10, 0),
        durationMinutes: 60,
        participants: ["user-1", "user-2"],
        notes: "Discuss Q3 roadmap",
        channelId: "ch-1",
        createdBy: "user-1",
      );
}
