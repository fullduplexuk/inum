import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/config/env_config.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_cubit.dart';
import 'package:inum/presentation/blocs/auth_session/auth_session_state.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_cubit.dart';
import 'package:inum/presentation/blocs/theme/theme_cubit.dart';
import 'package:inum/presentation/blocs/theme/theme_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _noiseSuppression = true;
  bool _pushNotifications = true;
  bool _useFrontCamera = true;

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatSessionCubit>().disconnect();
              context.read<AuthSessionCubit>().logout();
              context.go(RouterEnum.signInView.routeName);
            },
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: BlocBuilder<AuthSessionCubit, AuthSessionState>(
        builder: (context, authState) {
          final user = authState is AuthSessionAuthenticated ? authState.user : null;

          return ListView(
            children: [
              // --- Account Section ---
              const _SectionHeader(title: 'Account'),
              if (user != null) ...[
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Username'),
                  subtitle: Text('@${user.username}'),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user.email.isNotEmpty ? user.email : 'Not set'),
                ),
              ],

              const Divider(),

              // --- Appearance Section ---
              const _SectionHeader(title: 'Appearance'),
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark Mode'),
                    subtitle: Text(themeState.isDark ? 'On' : 'Off'),
                    value: themeState.isDark,
                    onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                  );
                },
              ),

              const Divider(),

              // --- Notifications Section ---
              const _SectionHeader(title: 'Notifications'),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Push Notifications'),
                value: _pushNotifications,
                onChanged: (val) => setState(() => _pushNotifications = val),
              ),

              const Divider(),

              // --- Calls Section ---
              const _SectionHeader(title: 'Calls'),
              SwitchListTile(
                secondary: const Icon(Icons.camera_front_outlined),
                title: const Text('Default Camera'),
                subtitle: Text(_useFrontCamera ? 'Front' : 'Back'),
                value: _useFrontCamera,
                onChanged: (val) => setState(() => _useFrontCamera = val),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.noise_aware_outlined),
                title: const Text('Noise Suppression'),
                value: _noiseSuppression,
                onChanged: (val) => setState(() => _noiseSuppression = val),
              ),
              // Phase 7: Call Forwarding
              ListTile(
                leading: const Icon(Icons.phone_forwarded_outlined),
                title: const Text('Call Forwarding'),
                subtitle: const Text('Configure forwarding rules'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(RouterEnum.callForwardingView.routeName),
              ),
              // Phase 7: Voicemail Settings
              ListTile(
                leading: const Icon(Icons.voicemail_outlined),
                title: const Text('Voicemail'),
                subtitle: const Text('Greeting, timing, notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(RouterEnum.voicemailSettingsView.routeName),
              ),

              const Divider(),

              // --- Recordings & Transcription Section ---
              const _SectionHeader(title: 'Recordings & Transcription'),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Recordings'),
                subtitle: const Text('View recorded calls'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(RouterEnum.recordingsView.routeName),
              ),
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('Language & Translation'),
                subtitle: const Text('Live translation preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(RouterEnum.languageSettingsView.routeName),
              ),

              // Phase 8: Notification Settings
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Notification Sounds'),
                subtitle: const Text('Sounds, DND, per-contact'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(RouterEnum.notificationSettingsView.routeName),
              ),

              const Divider(),

              // --- Security Section ---
              const _SectionHeader(title: 'Security'),
              ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: const Text('QR Code Login'),
                subtitle: const Text('Scan to login on other devices'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(RouterEnum.qrLoginView.routeName),
              ),

              const Divider(),

              // --- About Section ---
              const _SectionHeader(title: 'About'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('App Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Server'),
                subtitle: Builder(
                  builder: (_) {
                    try {
                      return Text(EnvConfig.instance.mattermostBaseUrl);
                    } catch (_) {
                      return const Text('Not configured');
                    }
                  },
                ),
              ),

              const Divider(),

              // --- Logout ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout, color: errorColor),
                    label: const Text('Sign Out', style: TextStyle(color: errorColor)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: inumPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
