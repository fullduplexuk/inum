import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:get_it/get_it.dart";
import "package:inum/core/di/dependency_injector.dart";
import "package:inum/core/init/router/app_router.dart";
import "package:inum/presentation/blocs/auth_session/auth_session_cubit.dart";
import "package:inum/presentation/blocs/call/call_cubit.dart";
import "package:inum/presentation/blocs/call/call_state.dart";
import "package:inum/presentation/blocs/call_history/call_history_cubit.dart";
import "package:inum/presentation/blocs/channel_list/channel_list_cubit.dart";
import "package:inum/presentation/blocs/chat_session/chat_session_cubit.dart";
import "package:inum/presentation/blocs/connectivity/connectivity_cubit.dart";
import "package:inum/presentation/blocs/contacts/contacts_cubit.dart";
import "package:inum/presentation/blocs/recordings/recordings_cubit.dart";
import "package:inum/presentation/blocs/theme/theme_cubit.dart";
import "package:inum/presentation/blocs/theme/theme_state.dart";
import "package:inum/presentation/design_system/theme.dart";
import "package:inum/presentation/views/call/incoming_call_screen.dart";

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = <BlocProvider>[
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
    ];

    // Add SQLite-backed cubits only if registered (not available on web)
    if (getIt.isRegistered<CallHistoryCubit>()) {
      providers.add(BlocProvider<CallHistoryCubit>(
        create: (_) => getIt<CallHistoryCubit>(),
      ));
    }
    if (getIt.isRegistered<RecordingsCubit>()) {
      providers.add(BlocProvider<RecordingsCubit>(
        create: (_) => getIt<RecordingsCubit>(),
      ));
    }

    return MultiBlocProvider(
      providers: providers,
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
              return _IncomingCallOverlay(child: child ?? const SizedBox.shrink());
            },
          );
        },
      ),
    );
  }
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
