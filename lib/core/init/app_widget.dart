import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:get_it/get_it.dart";
import "package:go_router/go_router.dart";
import "package:inum/core/di/dependency_injector.dart";
import "package:inum/core/init/router/app_router.dart";
import "package:inum/core/constants/enums/router_enum.dart";
import "package:inum/core/services/web/web_title_helper.dart";
import "package:inum/presentation/blocs/auth_session/auth_session_cubit.dart";
import "package:inum/presentation/blocs/call/call_cubit.dart";
import "package:inum/presentation/blocs/call/call_state.dart";
import "package:inum/presentation/blocs/call_history/call_history_cubit.dart";
import "package:inum/presentation/blocs/channel_list/channel_list_cubit.dart";
import "package:inum/presentation/blocs/channel_list/channel_list_state.dart";
import "package:inum/presentation/blocs/chat_session/chat_session_cubit.dart";
import "package:inum/presentation/blocs/connectivity/connectivity_cubit.dart";
import "package:inum/presentation/blocs/contacts/contacts_cubit.dart";
import "package:inum/presentation/blocs/recordings/recordings_cubit.dart";
import "package:inum/presentation/blocs/disappearing_messages/disappearing_messages_cubit.dart";
import "package:inum/presentation/blocs/custom_status/custom_status_cubit.dart";
import "package:inum/presentation/blocs/theme/theme_cubit.dart";
import "package:inum/presentation/blocs/theme/theme_state.dart";
import "package:inum/presentation/design_system/theme.dart";
import "package:inum/presentation/views/call/incoming_call_screen.dart";
import 'package:inum/core/services/blocked_users_service.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthSessionCubit>(
          create: (_) => getIt<AuthSessionCubit>(),
        ),
        BlocProvider<ChatSessionCubit>(
          create: (_) => getIt<ChatSessionCubit>(),
        ),
        BlocProvider<ChannelListCubit>(
          create: (_) => getIt<ChannelListCubit>(),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (_) => getIt<ConnectivityCubit>(),
        ),
        BlocProvider<CallCubit>(
          create: (_) => getIt<CallCubit>(),
        ),
        BlocProvider<ContactsCubit>(
          create: (_) => getIt<ContactsCubit>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<CallHistoryCubit>(
          create: (_) => getIt<CallHistoryCubit>(),
        ),
        BlocProvider<RecordingsCubit>(
          create: (_) => getIt<RecordingsCubit>(),
        ),
        BlocProvider<DisappearingMessagesCubit>(
          create: (_) => getIt<DisappearingMessagesCubit>(),
        ),
        BlocProvider<CustomStatusCubit>(
          create: (_) => getIt<CustomStatusCubit>(),
        ),
            BlocProvider<BlockedUsersCubit>(
              create: (_) => getIt<BlockedUsersCubit>(),
            ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: "INUM",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              return _WebShortcutsWrapper(
                child: _UnreadTitleUpdater(
                  child: _IncomingCallOverlay(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Updates browser tab title and favicon badge based on unread count.
class _UnreadTitleUpdater extends StatelessWidget {
  final Widget child;
  const _UnreadTitleUpdater({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return BlocListener<ChannelListCubit, ChannelListState>(
      listener: (context, state) {
        if (state is ChannelListLoaded) {
          int totalUnread = 0;
          for (final ch in state.channels) {
            totalUnread += ch.unreadCount;
          }
          if (totalUnread > 0) {
            setWebTitle('($totalUnread) INUM');
            setWebFaviconBadge(true);
          } else {
            setWebTitle('INUM');
            setWebFaviconBadge(false);
          }
        }
      },
      child: child,
    );
  }
}

/// Keyboard shortcuts wrapper for web.
class _WebShortcutsWrapper extends StatelessWidget {
  final Widget child;
  const _WebShortcutsWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _NewChatIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _SearchChannelsIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const _GoBackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewChatIntent: CallbackAction<_NewChatIntent>(
            onInvoke: (_) {
              final ctx = AppRouter.router.routerDelegate.navigatorKey.currentContext;
              if (ctx != null) {
                ctx.push(RouterEnum.createChannelView.routeName);
              }
              return null;
            },
          ),
          _SearchChannelsIntent: CallbackAction<_SearchChannelsIntent>(
            onInvoke: (_) {
              final ctx = AppRouter.router.routerDelegate.navigatorKey.currentContext;
              if (ctx != null) {
                ctx.go(RouterEnum.dashboardView.routeName);
              }
              return null;
            },
          ),
          _GoBackIntent: CallbackAction<_GoBackIntent>(
            onInvoke: (_) {
              final ctx = AppRouter.router.routerDelegate.navigatorKey.currentContext;
              if (ctx != null) {
                final nav = Navigator.of(ctx);
                if (nav.canPop()) {
                  nav.pop();
                }
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _NewChatIntent extends Intent {
  const _NewChatIntent();
}

class _SearchChannelsIntent extends Intent {
  const _SearchChannelsIntent();
}

class _GoBackIntent extends Intent {
  const _GoBackIntent();
}

class _IncomingCallOverlay extends StatelessWidget {
  final Widget child;
  const _IncomingCallOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallCubit, CallState>(
      listenWhen: (prev, curr) => curr is CallIncoming,
      listener: (context, state) {
        if (state is CallIncoming) {
          Navigator.of(context, rootNavigator: true).push(
            PageRouteBuilder(
              opaque: true,
              pageBuilder: (_, __, ___) => const IncomingCallScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                );
              },
            ),
          );
        }
      },
      child: child,
    );
  }
}
