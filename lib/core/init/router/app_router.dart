import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/core/init/router/custom_page_builder_widget.dart';
import 'package:inum/presentation/views/bottom_tab/bottom_tab_view.dart';
import 'package:inum/presentation/views/call/call_screen.dart';
import 'package:inum/presentation/views/chat/chat_view.dart';
import 'package:inum/presentation/views/landing/landing_view.dart';
import 'package:inum/presentation/views/sign_in/sign_in_view.dart';

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
    ],
  );
}
