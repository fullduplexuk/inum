import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:inum/domain/models/call/call_model.dart';

/// Wraps the livekit_client SDK. This is the only class
/// that imports livekit_client directly.
class LiveKitService {
  lk.Room? _room;
  lk.LocalParticipant? _localParticipant;
  lk.EventsListener<lk.RoomEvent>? _roomListener;

  final _eventController = StreamController<LiveKitEvent>.broadcast();
  Stream<LiveKitEvent> get events => _eventController.stream;

  lk.Room? get room => _room;
  lk.LocalParticipant? get localParticipant => _localParticipant;
  bool get isConnected =>
      _room?.connectionState == lk.ConnectionState.connected;

  List<lk.RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? [];

  /// Connect to a LiveKit room.
  Future<lk.Room> connect(String url, String token) async {
    _room = lk.Room(
      roomOptions: const lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: lk.AudioPublishOptions(
          audioBitrate: lk.AudioPreset.music,
        ),
        defaultVideoPublishOptions: lk.VideoPublishOptions(
          videoEncoding: lk.VideoEncoding(
            maxBitrate: 1700 * 1000,
            maxFramerate: 30,
          ),
          simulcast: true,
        ),
      ),
    );

    _roomListener = _room!.createListener();
    _setupListeners();

    await _room!.connect(url, token);

    _localParticipant = _room!.localParticipant;
    return _room!;
  }

  void _setupListeners() {
    final listener = _roomListener;
    if (listener == null) return;

    listener
      ..on<lk.ParticipantConnectedEvent>((event) {
        _eventController.add(LiveKitEvent.participantJoined(
          event.participant.identity,
        ));
      })
      ..on<lk.ParticipantDisconnectedEvent>((event) {
        _eventController.add(LiveKitEvent.participantLeft(
          event.participant.identity,
        ));
      })
      ..on<lk.TrackSubscribedEvent>((event) {
        _eventController.add(LiveKitEvent.trackSubscribed(
          event.participant.identity,
        ));
      })
      ..on<lk.TrackUnsubscribedEvent>((event) {
        _eventController.add(LiveKitEvent.trackUnsubscribed(
          event.participant.identity,
        ));
      })
      ..on<lk.ActiveSpeakersChangedEvent>((event) {
        final speakerIds =
            event.speakers.map((p) => p.identity).toList();
        _eventController.add(LiveKitEvent.activeSpeakersChanged(speakerIds));
      })
      ..on<lk.RoomDisconnectedEvent>((event) {
        _eventController.add(const LiveKitEvent.disconnected());
      })
      ..on<lk.ParticipantConnectionQualityUpdatedEvent>((event) {
        _eventController.add(LiveKitEvent.connectionQualityChanged(
          event.participant.identity,
          _mapQuality(event.connectionQuality),
        ));
      });
  }

  ConnectionQuality _mapQuality(lk.ConnectionQuality q) {
    switch (q) {
      case lk.ConnectionQuality.excellent:
        return ConnectionQuality.excellent;
      case lk.ConnectionQuality.good:
        return ConnectionQuality.good;
      case lk.ConnectionQuality.poor:
        return ConnectionQuality.poor;
      case lk.ConnectionQuality.lost:
        return ConnectionQuality.lost;
      default:
        return ConnectionQuality.poor;
    }
  }

  /// Disconnect from the current room.
  Future<void> disconnect() async {
    try {
      _roomListener?.dispose();
      _roomListener = null;
      await _room?.disconnect();
      await _room?.dispose();
    } catch (e) {
      debugPrint('LiveKit disconnect error: $e');
    } finally {
      _room = null;
      _localParticipant = null;
    }
  }

  /// Toggle local audio on/off. Returns new enabled state.
  Future<bool> toggleAudio() async {
    final p = _localParticipant;
    if (p == null) return false;

    final pubs = p.audioTrackPublications;
    if (pubs.isEmpty) {
      await p.setMicrophoneEnabled(true);
      return true;
    }

    final isMuted = pubs.first.muted;
    await p.setMicrophoneEnabled(isMuted);
    return isMuted;
  }

  /// Toggle local video on/off. Returns new enabled state.
  Future<bool> toggleVideo() async {
    final p = _localParticipant;
    if (p == null) return false;

    final camPubs = p.videoTrackPublications
        .where((t) => t.source == lk.TrackSource.camera);
    if (camPubs.isEmpty) {
      await p.setCameraEnabled(true);
      return true;
    }

    final isMuted = camPubs.first.muted;
    await p.setCameraEnabled(isMuted);
    return isMuted;
  }

  /// Toggle speaker output.
  Future<void> toggleSpeaker() async {
    if (_room == null) return;
    final currentOutput = lk.Hardware.instance.selectedAudioOutput;
    final outputs =
        await lk.Hardware.instance.enumerateDevices(type: 'audiooutput');
    if (outputs.length > 1) {
      final idx =
          outputs.indexWhere((d) => d.deviceId == currentOutput?.deviceId);
      final next = (idx + 1) % outputs.length;
      await lk.Hardware.instance.selectAudioOutput(outputs[next]);
    }
  }

  /// Switch between front and back camera.
  Future<void> switchCamera() async {
    final p = _localParticipant;
    if (p == null) return;

    final camPubs = p.videoTrackPublications
        .where((t) => t.source == lk.TrackSource.camera);
    if (camPubs.isEmpty) return;

    final track = camPubs.first.track;
    if (track is lk.LocalVideoTrack) {
      try {
        await track.restartTrack();
      } catch (e) {
        debugPrint('Switch camera error: $e');
      }
    }
  }

  /// Start screen sharing.
  Future<void> startScreenShare() async {
    await _localParticipant?.setScreenShareEnabled(true);
  }

  /// Stop screen sharing.
  Future<void> stopScreenShare() async {
    await _localParticipant?.setScreenShareEnabled(false);
  }

  void dispose() {
    _roomListener?.dispose();
    _room?.dispose();
    _eventController.close();
  }
}

/// Events emitted by [LiveKitService].
sealed class LiveKitEvent {
  const LiveKitEvent();

  const factory LiveKitEvent.participantJoined(String identity) =
      ParticipantJoinedEvent;
  const factory LiveKitEvent.participantLeft(String identity) =
      ParticipantLeftEvent;
  const factory LiveKitEvent.trackSubscribed(String identity) =
      TrackSubscribedLKEvent;
  const factory LiveKitEvent.trackUnsubscribed(String identity) =
      TrackUnsubscribedLKEvent;
  const factory LiveKitEvent.activeSpeakersChanged(List<String> speakerIds) =
      ActiveSpeakersChangedLKEvent;
  const factory LiveKitEvent.disconnected() = DisconnectedLKEvent;
  const factory LiveKitEvent.connectionQualityChanged(
    String identity,
    ConnectionQuality quality,
  ) = ConnectionQualityChangedLKEvent;
}

class ParticipantJoinedEvent extends LiveKitEvent {
  final String identity;
  const ParticipantJoinedEvent(this.identity);
}

class ParticipantLeftEvent extends LiveKitEvent {
  final String identity;
  const ParticipantLeftEvent(this.identity);
}

class TrackSubscribedLKEvent extends LiveKitEvent {
  final String identity;
  const TrackSubscribedLKEvent(this.identity);
}

class TrackUnsubscribedLKEvent extends LiveKitEvent {
  final String identity;
  const TrackUnsubscribedLKEvent(this.identity);
}

class ActiveSpeakersChangedLKEvent extends LiveKitEvent {
  final List<String> speakerIds;
  const ActiveSpeakersChangedLKEvent(this.speakerIds);
}

class DisconnectedLKEvent extends LiveKitEvent {
  const DisconnectedLKEvent();
}

class ConnectionQualityChangedLKEvent extends LiveKitEvent {
  final String identity;
  final ConnectionQuality quality;
  const ConnectionQualityChangedLKEvent(this.identity, this.quality);
}
