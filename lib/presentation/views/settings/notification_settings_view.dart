import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});
  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  bool _messageNotifications = true;
  bool _showPreview = true;
  String _messageSound = 'Default';
  bool _callNotifications = true;
  String _ringtone = 'Classic';
  bool _vibration = true;
  bool _dndEnabled = false;
  TimeOfDay _dndStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dndEnd = const TimeOfDay(hour: 7, minute: 0);
  final Set<int> _dndDays = {1, 2, 3, 4, 5};

  static const _soundOptions = ['Default', 'Chime', 'Bell', 'Ding', 'Pop', 'Swoosh', 'None'];
  static const _ringtoneOptions = ['Classic', 'Modern', 'Gentle', 'Urgent', 'Melody', 'Vibrate Only'];
  static const _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _dndStart : _dndEnd;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) setState(() { if (isStart) _dndStart = picked; else _dndEnd = picked; });
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings'), centerTitle: false),
      body: ListView(children: [
        _sectionHeader('Message Notifications'),
        SwitchListTile(secondary: const Icon(Icons.notifications_outlined), title: const Text('Message Notifications'),
          subtitle: const Text('Show notifications for new messages'), value: _messageNotifications,
          onChanged: (v) => setState(() => _messageNotifications = v)),
        if (_messageNotifications) ...[
          SwitchListTile(secondary: const Icon(Icons.visibility_outlined), title: const Text('Preview Text'),
            subtitle: const Text('Show message content in notification'), value: _showPreview,
            onChanged: (v) => setState(() => _showPreview = v)),
          ListTile(leading: const Icon(Icons.music_note_outlined), title: const Text('Notification Sound'),
            subtitle: Text(_messageSound), trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSoundPicker('Notification Sound', _soundOptions, _messageSound, (v) => setState(() => _messageSound = v))),
        ],
        const Divider(),
        _sectionHeader('Call Notifications'),
        SwitchListTile(secondary: const Icon(Icons.call_outlined), title: const Text('Call Notifications'),
          subtitle: const Text('Ring and notify for incoming calls'), value: _callNotifications,
          onChanged: (v) => setState(() => _callNotifications = v)),
        if (_callNotifications)
          ListTile(leading: const Icon(Icons.ring_volume_outlined), title: const Text('Ringtone'),
            subtitle: Text(_ringtone), trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSoundPicker('Ringtone', _ringtoneOptions, _ringtone, (v) => setState(() => _ringtone = v))),
        SwitchListTile(secondary: const Icon(Icons.vibration), title: const Text('Vibration'),
          subtitle: const Text('Vibrate on notifications'), value: _vibration,
          onChanged: (v) => setState(() => _vibration = v)),
        const Divider(),
        _sectionHeader('Do Not Disturb'),
        SwitchListTile(secondary: const Icon(Icons.do_not_disturb_on_outlined), title: const Text('Do Not Disturb'),
          subtitle: const Text('Silence notifications on schedule'), value: _dndEnabled,
          onChanged: (v) => setState(() => _dndEnabled = v)),
        if (_dndEnabled) ...[
          ListTile(leading: const Icon(Icons.access_time), title: const Text('Start Time'),
            subtitle: Text(_formatTime(_dndStart)), trailing: const Icon(Icons.chevron_right), onTap: () => _pickTime(true)),
          ListTile(leading: const Icon(Icons.access_time_filled), title: const Text('End Time'),
            subtitle: Text(_formatTime(_dndEnd)), trailing: const Icon(Icons.chevron_right), onTap: () => _pickTime(false)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Active Days', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(7, (i) {
                final day = i + 1; final isSelected = _dndDays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() { if (isSelected) _dndDays.remove(day); else _dndDays.add(day); }),
                  child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: isSelected ? inumPrimary : customGreyColor200, shape: BoxShape.circle),
                    child: Center(child: Text(_dayNames[day].substring(0, 1),
                      style: TextStyle(color: isSelected ? white : customGreyColor700, fontWeight: FontWeight.w600, fontSize: 13)))));
              })),
            ])),
        ],
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: inumPrimary, letterSpacing: 0.5)));
  }

  void _showSoundPicker(String title, List<String> options, String current, void Function(String) onSelect) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        const Divider(height: 1),
        ...options.map((opt) => ListTile(
          leading: Icon(opt == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: opt == current ? inumPrimary : customGreyColor500),
          title: Text(opt),
          onTap: () { onSelect(opt); Navigator.pop(ctx); })),
        const SizedBox(height: 8),
      ])));
  }
}
