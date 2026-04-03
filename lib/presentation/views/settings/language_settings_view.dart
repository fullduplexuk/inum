import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';

class LanguageSettingsView extends StatefulWidget {
  const LanguageSettingsView({super.key});

  @override
  State<LanguageSettingsView> createState() => _LanguageSettingsViewState();
}

class _LanguageSettingsViewState extends State<LanguageSettingsView> {
  String _sourceLanguage = 'auto';
  String _targetLanguage = 'none';
  bool _liveTranslationEnabled = false;

  static const _supportedLanguages = <String, String>{
    'auto': 'Auto-detect',
    'en': 'English',
    'ar': 'Arabic',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'zh': 'Chinese (Simplified)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'it': 'Italian',
    'nl': 'Dutch',
    'pl': 'Polish',
  };

  static const _targetLanguages = <String, String>{
    'none': 'Off (no translation)',
    'en': 'English',
    'ar': 'Arabic',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'zh': 'Chinese (Simplified)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'it': 'Italian',
    'nl': 'Dutch',
    'pl': 'Polish',
  };

  void _save() {
    // TODO: Persist to user preferences (shared_preferences or server)
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language & Translation'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Live translation toggle
          const _SectionHeader(title: 'Live Translation'),
          SwitchListTile(
            secondary: const Icon(Icons.translate),
            title: const Text('Enable Live Translation'),
            subtitle: const Text(
              'Translate captions during calls in real-time',
            ),
            value: _liveTranslationEnabled,
            onChanged: (val) {
              setState(() {
                _liveTranslationEnabled = val;
                if (!val) _targetLanguage = 'none';
              });
            },
          ),
          const Divider(),

          // Source language
          const _SectionHeader(title: 'Source Language'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'The language being spoken in the call. '
              'Auto-detect uses Whisper to identify the language.',
              style: TextStyle(
                fontSize: 12,
                color: customGreyColor600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._supportedLanguages.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: _sourceLanguage,
              activeColor: inumSecondary,
              onChanged: (val) {
                if (val != null) setState(() => _sourceLanguage = val);
              },
              dense: true,
            );
          }),
          const Divider(),

          // Target language
          const _SectionHeader(title: 'Target Language'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Captions will be translated to this language during calls.',
              style: TextStyle(
                fontSize: 12,
                color: customGreyColor600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._targetLanguages.entries.map((entry) {
            final enabled =
                _liveTranslationEnabled || entry.key == 'none';
            return RadioListTile<String>(
              title: Text(
                entry.value,
                style: TextStyle(
                  color: enabled ? null : customGreyColor400,
                ),
              ),
              value: entry.key,
              groupValue: _targetLanguage,
              activeColor: inumSecondary,
              onChanged: enabled
                  ? (val) {
                      if (val != null) {
                        setState(() => _targetLanguage = val);
                      }
                    }
                  : null,
              dense: true,
            );
          }),
          const SizedBox(height: 16),

          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: inumSecondary.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: inumSecondary.withAlpha(40)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: inumSecondary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live translation requires the LiveKit Agents service '
                    'with Whisper transcription to be deployed on the server.',
                    style: TextStyle(
                      fontSize: 12,
                      color: customGreyColor700,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
