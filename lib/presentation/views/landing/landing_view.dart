import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_cubit.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class LandingView extends StatefulWidget {
  const LandingView({super.key});

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  @override
  void initState() {
    super.initState();
    context.read<AuthSessionCubit>().checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthSessionCubit, AuthSessionState>(
      listener: (context, state) {
        if (state is AuthSessionAuthenticated) {
          context.go(RouterEnum.dashboardView.routeName);
        } else if (state is AuthSessionUnauthenticated || state is AuthSessionError) {
          context.go(RouterEnum.signInView.routeName);
        }
      },
      child: Scaffold(
        backgroundColor: inumPrimary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    'INUM',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: inumPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: white),
              const SizedBox(height: 16),
              const Text(
                'Connecting...',
                style: TextStyle(color: white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
