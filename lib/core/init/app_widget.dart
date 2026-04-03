import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/core/init/router/app_router.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_cubit.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_cubit.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_cubit.dart';
import 'package:inum/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:inum/presentation/design_system/theme.dart';

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
      ],
      child: MaterialApp.router(
        title: 'INUM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
