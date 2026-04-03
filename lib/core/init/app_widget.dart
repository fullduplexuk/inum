import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/core/init/router/app_router.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_cubit.dart';
import 'package:inum/presentation/blocs/call/call_cubit.dart';
import 'package:inum/presentation/blocs/call/call_state.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_cubit.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_cubit.dart';
import 'package:inum/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:inum/presentation/design_system/theme.dart';
import 'package:inum/presentation/views/call/incoming_call_screen.dart';

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
      ],
      child: MaterialApp.router(
        title: 'INUM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return _IncomingCallOverlay(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}

/// Listens for incoming call state and shows the incoming call screen
/// as a full-screen overlay on top of whatever route is active.
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
