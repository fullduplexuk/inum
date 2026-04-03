import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inum/presentation/design_system/colors.dart';

class VoicemailSettingsView extends StatefulWidget {
  const VoicemailSettingsView({super.key});

  @override
  State<VoicemailSettingsView> createState() => _VoicemailSettingsViewState();
}

class _VoicemailSettingsViewState extends State<VoicemailSettingsView> {
  static const _storageKey = 'voicemail_settings';
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;

  bool _enabled = true;
  String _greetingType = 'default'; // 'default' or 'custom'
  int _answerAfterSeconds = 20;
  bool _pushNotification = true;
  bool _emailNotification = false;
  bool _transcribeMessages = true;

  static const _answerOptions = [10, 15, 20, 25, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final json = await _storage.read(key: _storageKey);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _enabled = data['enabled'] as bool? ?? true;
        _greetingType = data['greeting_type'] as String? ?? 'default';
        _answerAfterSeconds = data['answer_after_seconds'] as int? ?? 20;
        _pushNotification = data['push_notification'] as bool? ?? true;
        _emailNotification = data['email_notification'] as bool? ?? false;
        _transcribeMessages = data['transcribe_messages'] as bool? ?? true;
      }
    } catch (_) {
      // Use defaults
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final data = {
      'enabled': _enabled,
      'greeting_type': _greetingType,
      'answer_after_seconds': _answerAfterSeconds,
      'push_notification': _pushNotification,
      'email_notification': _emailNotification,
      'transcribe_messages': _transcribeMessages,
    };
    await _storage.write(key: _storageKey, value: jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voicemail settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voicemail'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: inumSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Enable/Disable
                SwitchListTile(
                  secondary: const Icon(Icons.voicemail),
                  title: const Text('Enable Voicemail'),
                  subtitle: Text(_enabled ? 'On' : 'Off'),
                  value: _enabled,
                  activeColor: inumSecondary,
                  onChanged: (val) => setState(() => _enabled = val),
                ),

                if (_enabled) ...[
                  const Divider(),
                  const _SectionHeader(title: 'Greeting'),

                  // Greeting type
                  RadioListTile<String>(
                    title: const Text('Default greeting'),
                    subtitle: const Text(
                      'Standard system greeting',
                    ),
                    value: 'default',
                    groupValue: _greetingType,
                    activeColor: inumSecondary,
                    onChanged: (val) {
                      if (val != null) setState(() => _greetingType = val);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Custom greeting'),
                    subtitle: const Text(
                      'Record your own greeting',
                    ),
                    value: 'custom',
                    groupValue: _greetingType,
                    activeColor: inumSecondary,
                    onChanged: (val) {
                      if (val != null) setState(() => _greetingType = val);
                    },
                  ),
                  if (_greetingType == 'custom')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Custom greeting recording (placeholder)',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.mic),
                        label: const Text('Record Greeting'),
                      ),
                    ),

                  const Divider(),
                  const _SectionHeader(title: 'Timing'),

                  // Answer after
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Answer after'),
                    trailing: DropdownButton<int>(
                      value: _answerAfterSeconds,
                      underline: const SizedBox.shrink(),
                      items: _answerOptions
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d sec'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _answerAfterSeconds = val);
                        }
                      },
                    ),
                  ),

                  const Divider(),
                  const _SectionHeader(title: 'Notifications'),

                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Push Notifications'),
                    value: _pushNotification,
                    activeColor: inumSecondary,
                    onChanged: (val) =>
                        setState(() => _pushNotification = val),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.email_outlined),
                    title: const Text('Email Notifications'),
                    value: _emailNotification,
                    activeColor: inumSecondary,
                    onChanged: (val) =>
                        setState(() => _emailNotification = val),
                  ),

                  const Divider(),
                  const _SectionHeader(title: 'Transcription'),

                  SwitchListTile(
                    secondary: const Icon(Icons.subtitles_outlined),
                    title: const Text('Transcribe Messages'),
                    subtitle: const Text(
                      'Automatically transcribe voicemails to text',
                    ),
                    value: _transcribeMessages,
                    activeColor: inumSecondary,
                    onChanged: (val) =>
                        setState(() => _transcribeMessages = val),
                  ),
                ],
              ],
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
