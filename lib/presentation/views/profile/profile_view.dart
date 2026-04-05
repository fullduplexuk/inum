import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_cubit.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_state.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_cubit.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/blocs/custom_status/custom_status_cubit.dart';
import 'package:inum/presentation/views/chat/widgets/custom_status_widgets.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
      ),
      body: BlocBuilder<AuthSessionCubit, AuthSessionState>(
        builder: (context, state) {
          if (state is! AuthSessionAuthenticated) {
            return const Center(child: Text('Not signed in'));
          }

          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: inumPrimary.withAlpha(30),
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: inumPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(user.displayName, style: Theme.of(context).textTheme.displaySmall),
              ),
              Center(
                child: Text(
                  '@${user.username}',
                  style: const TextStyle(color: secondaryTextColor, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              _StatusOption(
                label: 'Online', icon: Icons.circle, iconColor: Colors.green,
                isSelected: user.status == 'online',
                onTap: () => context.read<AuthSessionCubit>().updateStatus('online'),
              ),
              _StatusOption(
                label: 'Away', icon: Icons.circle, iconColor: Colors.orange,
                isSelected: user.status == 'away',
                onTap: () => context.read<AuthSessionCubit>().updateStatus('away'),
              ),
              _StatusOption(
                label: 'Do Not Disturb', icon: Icons.remove_circle, iconColor: Colors.red,
                isSelected: user.status == 'dnd',
                onTap: () => context.read<AuthSessionCubit>().updateStatus('dnd'),
              ),
              _StatusOption(
                label: 'Offline', icon: Icons.circle_outlined, iconColor: customGreyColor500,
                isSelected: user.status == 'offline',
                onTap: () => context.read<AuthSessionCubit>().updateStatus('offline'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const CustomStatusSection(),
              const SizedBox(height: 32),
              if (user.email.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
              if (user.position.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: const Text('Position'),
                  subtitle: Text(user.position),
                ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('Saved Messages'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouterEnum.savedMessagesView.routeName),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<ChatSessionCubit>().disconnect();
                    context.read<AuthSessionCubit>().logout();
                    context.go(RouterEnum.signInView.routeName);
                  },
                  icon: const Icon(Icons.logout, color: errorColor),
                  label: const Text('Sign Out', style: TextStyle(color: errorColor)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label, required this.icon, required this.iconColor,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 16),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: inumPrimary) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: isSelected,
      selectedTileColor: inumPrimary.withAlpha(10),
    );
  }
}
