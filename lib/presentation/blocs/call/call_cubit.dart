import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:inum/data/api/livekit/livekit_service.dart';
import 'package:inum/data/api/mattermost/mattermost_ws_client.dart';
import 'package:inum/domain/models/call/call_model.dart';
import 'package:inum/presentation/blocs/call/call_state.dart';

class CallCubit extends Cubit<CallState> {
  final LiveKitService _liveKitService;
  final MattermostWsClient _wsClient;
  final String? _currentUserId;
  final String? _currentUsername;

  Timer? _durationTimer;
  StreamSubscription<LiveKitEvent>? _lkSubscription;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  // Placeholder LiveKit URL - will be configured when server is deployed
  static const String _defaultLiveKitUrl = 'wss://livekit.vista.inum.com';

  CallCubit({
    required LiveKitService liveKitService,
    required MattermostWsClient wsClient,
    String? currentUserId,
    String? currentUsername,
  })  : _liveKitService = liveKitService,
        _wsClient = wsClient,
        _currentUserId = currentUserId,
        _currentUsername = currentUsername,
        super(const CallIdle()) {
    _listenToWsSignaling();
  }

  void _listenToWsSignaling() {
    _wsSubscription = _wsClient.events.listen((event) {
      final eventType = event['event'] as String?;
      final data = event['data'] as Map<String, dynamic>? ?? {};

      switch (eventType) {
        case 'custom_call_invite':
          _handleIncomingCall(data);
        case 'custom_call_accept':
          _handleCallAccepted(data);
        case 'custom_call_reject':
          _handleCallRejected(data);
        case 'custom_call_end':
          _handleCallEnded(data);
      }
    });
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    try {
      final callJson = data['call'] is String
          ? jsonDecode(data['call'] as String) as Map<String, dynamic>
          : data['call'] as Map<String, dynamic>? ?? data;

      final callModel = CallModel.fromJson(callJson);
      if (callModel.initiatedBy == _currentUserId) return;

      if (state is CallIdle) {
        emit(CallIncoming(callModel: callModel));
      }
    } catch (e) {
      debugPrint('Error handling incoming call: $e');
    }
  }

  void _handleCallAccepted(Map<String, dynamic> data) {
    final currentState = state;
    if (currentState is CallOutgoing) {
      _connectToRoom(currentState.callModel);
    }
  }

  void _handleCallRejected(Map<String, dynamic> data) {
    if (state is CallOutgoing) {
      emit(const CallEnded(duration: Duration.zero, reason: 'Declined'));
      _resetAfterDelay();
    }
  }

  void _handleCallEnded(Map<String, dynamic> data) {
    endCall(reason: 'Remote ended');
  }

  /// Initiate a call to a channel/user.
  void initiateCall(String channelId, {bool isVideo = false}) {
    if (state is! CallIdle) return;

    final roomId = const Uuid().v4();
    final callModel = CallModel(
      roomName: 'call-$roomId',
      roomId: roomId,
      participants: [
        CallParticipant(
          userId: _currentUserId ?? '',
          username: _currentUsername ?? '',
          isVideoEnabled: isVideo,
        ),
      ],
      callType: isVideo ? CallType.video : CallType.audio,
      initiatedBy: _currentUserId ?? '',
      startedAt: DateTime.now(),
      status: CallStatus.ringing,
      channelId: channelId,
      livekitUrl: _defaultLiveKitUrl,
    );

    emit(CallOutgoing(callModel: callModel));
    _sendCallSignal('custom_call_invite', callModel);
  }

  /// Accept an incoming call.
  void acceptCall() {
    final currentState = state;
    if (currentState is! CallIncoming) return;

    final callModel = currentState.callModel;
    _sendCallSignal('custom_call_accept', callModel);
    _connectToRoom(callModel);
  }

  /// Reject an incoming call.
  void rejectCall() {
    final currentState = state;
    if (currentState is! CallIncoming) return;

    _sendCallSignal('custom_call_reject', currentState.callModel);
    emit(const CallEnded(duration: Duration.zero, reason: 'Declined'));
    _resetAfterDelay();
  }

  /// End the current call.
  void endCall({String? reason}) {
    final currentState = state;
    CallModel? callModel;
    Duration duration = Duration.zero;

    if (currentState is CallActive) {
      callModel = currentState.callModel;
      duration = currentState.elapsed;
    } else if (currentState is CallOutgoing) {
      callModel = currentState.callModel;
    } else if (currentState is CallIncoming) {
      callModel = currentState.callModel;
    }

    _durationTimer?.cancel();
    _lkSubscription?.cancel();
    _liveKitService.disconnect();

    if (callModel != null) {
      _sendCallSignal('custom_call_end', callModel);
    }

    emit(CallEnded(duration: duration, reason: reason));
    _resetAfterDelay();
  }

  Future<void> _connectToRoom(CallModel callModel) async {
    try {
      final url = callModel.livekitUrl ?? _defaultLiveKitUrl;
      final token = callModel.livekitToken ?? '';

      if (token.isEmpty) {
        debugPrint('LiveKit token not available yet - server not deployed');
        _enterActiveState(callModel);
        return;
      }

      await _liveKitService.connect(url, token);
      _enterActiveState(callModel);

      await _liveKitService.toggleAudio();
      if (callModel.callType == CallType.video) {
        await _liveKitService.toggleVideo();
      }
    } catch (e) {
      debugPrint('Failed to connect to LiveKit: $e');
      _enterActiveState(callModel);
    }
  }

  void _enterActiveState(CallModel callModel) {
    final activeModel = callModel.copyWith(status: CallStatus.active);

    emit(CallActive(
      callModel: activeModel,
      participants: activeModel.participants,
      isVideoEnabled: activeModel.callType == CallType.video,
    ));

    _startDurationTimer();
    _listenToLiveKitEvents();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    final startTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentState = state;
      if (currentState is CallActive) {
        emit(currentState.copyWith(
          elapsed: DateTime.now().difference(startTime),
        ));
      }
    });
  }

  void _listenToLiveKitEvents() {
    _lkSubscription?.cancel();
    _lkSubscription = _liveKitService.events.listen((event) {
      final currentState = state;
      if (currentState is! CallActive) return;

      switch (event) {
        case ParticipantJoinedEvent(:final identity):
          final updated = List<CallParticipant>.from(currentState.participants)
            ..add(CallParticipant(userId: identity, username: identity));
          emit(currentState.copyWith(participants: updated));

        case ParticipantLeftEvent(:final identity):
          final updated = currentState.participants
              .where((p) => p.userId != identity)
              .toList();
          emit(currentState.copyWith(participants: updated));
          if (updated.length <= 1) {
            endCall(reason: 'Participant left');
          }

        case ActiveSpeakersChangedLKEvent(:final speakerIds):
          final updated = currentState.participants.map((p) {
            return p.copyWith(isSpeaking: speakerIds.contains(p.userId));
          }).toList();
          emit(currentState.copyWith(participants: updated));

        case ConnectionQualityChangedLKEvent(:final identity, :final quality):
          final updated = currentState.participants.map((p) {
            if (p.userId == identity) {
              return p.copyWith(connectionQuality: quality);
            }
            return p;
          }).toList();
          emit(currentState.copyWith(participants: updated));

        case DisconnectedLKEvent():
          endCall(reason: 'Disconnected');

        default:
          break;
      }
    });
  }

  Future<void> toggleAudio() async {
    final currentState = state;
    if (currentState is! CallActive) return;
    final enabled = await _liveKitService.toggleAudio();
    emit(currentState.copyWith(isAudioEnabled: enabled));
  }

  Future<void> toggleVideo() async {
    final currentState = state;
    if (currentState is! CallActive) return;
    final enabled = await _liveKitService.toggleVideo();
    emit(currentState.copyWith(isVideoEnabled: enabled));
  }

  Future<void> toggleSpeaker() async {
    final currentState = state;
    if (currentState is! CallActive) return;
    await _liveKitService.toggleSpeaker();
    emit(currentState.copyWith(isSpeakerOn: !currentState.isSpeakerOn));
  }

  Future<void> switchCamera() async {
    await _liveKitService.switchCamera();
  }

  Future<void> toggleScreenShare() async {
    final currentState = state;
    if (currentState is! CallActive) return;
    if (currentState.isScreenSharing) {
      await _liveKitService.stopScreenShare();
    } else {
      await _liveKitService.startScreenShare();
    }
    emit(currentState.copyWith(isScreenSharing: !currentState.isScreenSharing));
  }

  /// Toggle call recording on/off.
  void toggleRecording() {
    final currentState = state;
    if (currentState is! CallActive) return;
    emit(currentState.copyWith(isRecording: !currentState.isRecording));
    debugPrint(
      'Recording ${currentState.isRecording ? "stopped" : "started"} '
      '(placeholder - Egress not deployed yet)',
    );
  }

  /// Toggle live captions (closed captioning) on/off.
  void toggleLiveCaptions() {
    final currentState = state;
    if (currentState is! CallActive) return;
    emit(currentState.copyWith(
      liveCaptionsEnabled: !currentState.liveCaptionsEnabled,
    ));
    debugPrint(
      'Live captions ${currentState.liveCaptionsEnabled ? "disabled" : "enabled"} '
      '(placeholder - Agents not deployed yet)',
    );
  }

  /// Toggle live translation on/off.
  void toggleTranslation() {
    final currentState = state;
    if (currentState is! CallActive) return;
    emit(currentState.copyWith(
      translationEnabled: !currentState.translationEnabled,
    ));
  }

  /// Receive a live caption from the LiveKit data channel (placeholder).
  void onLiveCaptionReceived({
    required String speakerName,
    required String text,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
  }) {
    final currentState = state;
    if (currentState is! CallActive) return;
    if (!currentState.liveCaptionsEnabled) return;

    final caption = LiveCaption(
      speakerName: speakerName,
      text: text,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      receivedAt: DateTime.now(),
    );

    // Keep only last 5 captions
    final updated = [...currentState.liveCaptions, caption];
    if (updated.length > 5) {
      updated.removeRange(0, updated.length - 5);
    }

    emit(currentState.copyWith(liveCaptions: updated));
  }

  // ── Phase 7: Hold ──────────────────────────────────────────────────────

  /// Toggle call hold on/off.
  void toggleHold() {
    final currentState = state;
    if (currentState is! CallActive) return;
    final newHoldState = !currentState.isOnHold;
    emit(currentState.copyWith(isOnHold: newHoldState));
    debugPrint(
      'Call ${newHoldState ? "placed on hold" : "resumed"} '
      '(placeholder - SIP bridge not deployed)',
    );
  }

  // ── Phase 7: DTMF ─────────────────────────────────────────────────────

  /// Toggle the in-call DTMF pad visibility.
  void toggleDtmfPad() {
    final currentState = state;
    if (currentState is! CallActive) return;
    emit(currentState.copyWith(showDtmfPad: !currentState.showDtmfPad));
  }

  /// Send a DTMF tone during an active call.
  void sendDtmf(String digit) {
    final currentState = state;
    if (currentState is! CallActive) return;
    // Placeholder: would send DTMF via LiveKit data channel or SIP INFO
    debugPrint('DTMF sent: $digit (placeholder - SIP bridge not deployed)');
  }

  // ── Phase 7: Call Merge ────────────────────────────────────────────────

  /// Start adding a participant to the active call.
  void startAddParticipant() {
    final currentState = state;
    if (currentState is! CallActive) return;
    emit(currentState.copyWith(isMerging: true));
  }

  /// Cancel adding a participant.
  void cancelAddParticipant() {
    final currentState = state;
    if (currentState is! CallActive) return;
    emit(currentState.copyWith(isMerging: false));
  }

  /// Merge an incoming call with the current active call (placeholder).
  void mergeCalls() {
    final currentState = state;
    if (currentState is! CallActive) return;
    emit(currentState.copyWith(isMerging: false));
    debugPrint('Calls merged (placeholder - conference not implemented)');
  }

  void _sendCallSignal(String action, CallModel callModel) {
    try {
      _wsClient.sendCallSignal(action, callModel.toJson());
    } catch (e) {
      debugPrint('Failed to send call signal: $e');
    }
  }

  void _resetAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (state is CallEnded) {
        emit(const CallIdle());
      }
    });
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    _lkSubscription?.cancel();
    _wsSubscription?.cancel();
    _liveKitService.disconnect();
    return super.close();
  }
}
