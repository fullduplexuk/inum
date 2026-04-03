import 'package:equatable/equatable.dart';
import 'package:inum/domain/models/call/call_model.dart';

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

  const CallActive({
    required this.callModel,
    required this.participants,
    this.isAudioEnabled = true,
    this.isVideoEnabled = false,
    this.isSpeakerOn = false,
    this.isScreenSharing = false,
    this.elapsed = Duration.zero,
  });

  CallActive copyWith({
    CallModel? callModel,
    List<CallParticipant>? participants,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isSpeakerOn,
    bool? isScreenSharing,
    Duration? elapsed,
  }) {
    return CallActive(
      callModel: callModel ?? this.callModel,
      participants: participants ?? this.participants,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      elapsed: elapsed ?? this.elapsed,
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
      ];
}

class CallEnded extends CallState {
  final Duration duration;
  final String? reason;

  const CallEnded({required this.duration, this.reason});

  @override
  List<Object?> get props => [duration, reason];
}
