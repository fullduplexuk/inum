import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/core/init/router/custom_page_builder_widget.dart';
import 'package:inum/domain/models/call/recording_model.dart';
import 'package:inum/domain/models/call/transcript_model.dart';
import 'package:inum/presentation/views/bottom_tab/bottom_tab_view.dart';
import 'package:inum/presentation/views/call/call_screen.dart';
import 'package:inum/presentation/views/chat/chat_view.dart';
import 'package:inum/presentation/views/landing/landing_view.dart';
import 'package:inum/presentation/views/recordings/call_summary_view.dart';
import 'package:inum/presentation/views/recordings/recording_player.dart';
import 'package:inum/presentation/views/recordings/recordings_list_view.dart';
import 'package:inum/presentation/views/recordings/transcript_viewer.dart';
import 'package:inum/presentation/views/settings/language_settings_view.dart';
import 'package:inum/presentation/views/settings/settings_view.dart';
import 'package:inum/presentation/views/sign_in/sign_in_view.dart';
import 'package:inum/presentation/views/voicemail/voicemail_view.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouterEnum.initialLocation.routeName,
    routes: [
      GoRoute(
        path: RouterEnum.initialLocation.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const LandingView()),
      ),
      GoRoute(
        path: RouterEnum.signInView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const SignInView()),
      ),
      GoRoute(
        path: RouterEnum.dashboardView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const BottomTabView()),
      ),
      GoRoute(
        path: RouterEnum.chatView.routeName,
        pageBuilder: (context, state) {
          final channelId = state.uri.queryParameters['channelId'] ?? '';
          final channelName = state.uri.queryParameters['channelName'] ?? '';
          return customPageBuilderWidget(
            context,
            state,
            ChatView(channelId: channelId, channelName: channelName),
          );
        },
      ),
      GoRoute(
        path: RouterEnum.profileView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const BottomTabView(initialTab: 3)),
      ),
      GoRoute(
        path: RouterEnum.callView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const CallScreen()),
      ),
      GoRoute(
        path: RouterEnum.callHistoryView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const BottomTabView(initialTab: 1)),
      ),
      GoRoute(
        path: RouterEnum.voicemailView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const VoicemailView()),
      ),
      GoRoute(
        path: RouterEnum.contactsView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const BottomTabView(initialTab: 2)),
      ),
      GoRoute(
        path: RouterEnum.settingsView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const SettingsView()),
      ),
      // ── Phase 6: Recordings & Transcription routes ──
      GoRoute(
        path: RouterEnum.recordingsView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(context, state, const RecordingsListView()),
      ),
      GoRoute(
        path: RouterEnum.recordingDetailView.routeName,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          // The recording and transcript are passed via extra, or loaded by ID
          final extra = state.extra as Map<String, dynamic>?;
          final recording = extra?['recording'] as RecordingModel?;
          final transcript = extra?['transcript'] as TranscriptModel?;

          if (recording != null) {
            return customPageBuilderWidget(
              context,
              state,
              RecordingPlayer(recording: recording, transcript: transcript),
            );
          }
          // Fallback: show placeholder recording
          return customPageBuilderWidget(
            context,
            state,
            RecordingPlayer(
              recording: RecordingModel(
                id: id,
                roomId: '',
                callId: '',
                createdAt: DateTime.now(),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouterEnum.transcriptView.routeName,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final transcript = extra?['transcript'] as TranscriptModel?;

          return customPageBuilderWidget(
            context,
            state,
            Scaffold(
              appBar: AppBar(
                title: const Text('Transcript'),
                centerTitle: false,
              ),
              body: transcript != null
                  ? TranscriptViewer(transcript: transcript)
                  : const Center(
                      child: Text('No transcript available'),
                    ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouterEnum.callSummaryView.routeName,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return customPageBuilderWidget(
            context,
            state,
            CallSummaryView(callId: id),
          );
        },
      ),
      GoRoute(
        path: RouterEnum.languageSettingsView.routeName,
        pageBuilder: (context, state) =>
            customPageBuilderWidget(
                context, state, const LanguageSettingsView()),
      ),
    ],
  );
}
