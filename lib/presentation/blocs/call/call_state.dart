import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/call/call_model.dart';

/// Represents a live caption entry received during a call.
class LiveCaption extends Equatable {
  final String speakerName;
  final String text;
  final String? translatedText;
  final String? sourceLanguage;
  final String? targetLanguage;
  final DateTime receivedAt;

  const LiveCaption({
    required this.speakerName,
    required this.text,
    this.translatedText,
    this.sourceLanguage,
    this.targetLanguage,
    required this.receivedAt,
  });

  @override
  List<Object?> get props => [
        speakerName,
        text,
        translatedText,
        sourceLanguage,
        targetLanguage,
        receivedAt,
      ];
}

sealed class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

class CallIdle extends CallState {
  const CallIdle();
}

class CallIncoming extends CallState {
  final CallModel callModel;
  const CallIncoming({required this.callModel});

  @override
  List<Object?> get props => [callModel];
}

class CallOutgoing extends CallState {
  final CallModel callModel;
  const CallOutgoing({required this.callModel});

  @override
  List<Object?> get props => [callModel];
}

class CallActive extends CallState {
  final CallModel callModel;
  final List<CallParticipant> participants;
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final bool isSpeakerOn;
  final bool isScreenSharing;
  final Duration elapsed;
  final bool isRecording;
  final bool liveCaptionsEnabled;
  final List<LiveCaption> liveCaptions;
  final bool translationEnabled;
  // Phase 7: Hold, DTMF, Merge
  final bool isOnHold;
  final bool showDtmfPad;
  final bool isMerging;
  // Phase 10: Raise hand & reactions
  final List<String> handRaisedUserIds;
  final List<String> callReactionEmojis;

  const CallActive({
    required this.callModel,
    required this.participants,
    this.isAudioEnabled = true,
    this.isVideoEnabled = false,
    this.isSpeakerOn = false,
    this.isScreenSharing = false,
    this.elapsed = Duration.zero,
    this.isRecording = false,
    this.liveCaptionsEnabled = false,
    this.liveCaptions = const [],
    this.translationEnabled = false,
    this.isOnHold = false,
    this.showDtmfPad = false,
    this.isMerging = false,
    this.handRaisedUserIds = const [],
    this.callReactionEmojis = const [],
  });

  CallActive copyWith({
    CallModel? callModel,
    List<CallParticipant>? participants,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isSpeakerOn,
    bool? isScreenSharing,
    Duration? elapsed,
    bool? isRecording,
    bool? liveCaptionsEnabled,
    List<LiveCaption>? liveCaptions,
    bool? translationEnabled,
    bool? isOnHold,
    bool? showDtmfPad,
    bool? isMerging,
    List<String>? handRaisedUserIds,
    List<String>? callReactionEmojis,
  }) {
    return CallActive(
      callModel: callModel ?? this.callModel,
      participants: participants ?? this.participants,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      elapsed: elapsed ?? this.elapsed,
      isRecording: isRecording ?? this.isRecording,
      liveCaptionsEnabled: liveCaptionsEnabled ?? this.liveCaptionsEnabled,
      liveCaptions: liveCaptions ?? this.liveCaptions,
      translationEnabled: translationEnabled ?? this.translationEnabled,
      isOnHold: isOnHold ?? this.isOnHold,
      showDtmfPad: showDtmfPad ?? this.showDtmfPad,
      isMerging: isMerging ?? this.isMerging,
      handRaisedUserIds: handRaisedUserIds ?? this.handRaisedUserIds,
      callReactionEmojis: callReactionEmojis ?? this.callReactionEmojis,
    );
  }

  @override
  List<Object?> get props => [
        callModel,
        participants,
        isAudioEnabled,
        isVideoEnabled,
        isSpeakerOn,
        isScreenSharing,
        elapsed,
        isRecording,
        liveCaptionsEnabled,
        liveCaptions,
        translationEnabled,
        isOnHold,
        showDtmfPad,
        isMerging,
        handRaisedUserIds,
        callReactionEmojis,
      ];
}

class CallEnded extends CallState {
  final Duration duration;
  final String? reason;

  const CallEnded({required this.duration, this.reason});

  @override
  List<Object?> get props => [duration, reason];
}
