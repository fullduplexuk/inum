import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/domain/models/meeting/meeting_model.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/core/services/meeting_link_service.dart';

class ScheduleMeetingView extends StatefulWidget {
  final String? channelId;
  final String? channelName;
  const ScheduleMeetingView({super.key, this.channelId, this.channelName});
  @override
  State<ScheduleMeetingView> createState() => _ScheduleMeetingViewState();
}

class _ScheduleMeetingViewState extends State<ScheduleMeetingView> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 30;
  bool _isCreating = false;
  static const _durationOptions = [15, 30, 45, 60, 90, 120];

  @override
  void dispose() { _titleController.dispose(); _notesController.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate,
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day, _selectedTime.hour, _selectedTime.minute));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() { _selectedTime = picked;
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, picked.hour, picked.minute); });
  }

  Future<void> _scheduleMeeting() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a meeting title'))); return; }
    setState(() => _isCreating = true);
    try {
      final apiClient = getIt<MattermostApiClient>();
      final userId = apiClient.currentUserId ?? '';
      final meeting = MeetingModel(id: 'mtg_${DateTime.now().millisecondsSinceEpoch}', title: title,
        scheduledAt: _selectedDate, durationMinutes: _durationMinutes, participants: [userId],
        notes: _notesController.text.trim(), channelId: widget.channelId ?? '', createdBy: userId);
      if (widget.channelId != null && widget.channelId!.isNotEmpty) {
        final dateStr = DateFormat('EEE, MMM d, yyyy').format(meeting.scheduledAt);
        final timeStr = DateFormat.jm().format(meeting.scheduledAt);
        final message = '**Meeting Scheduled**\n---\n**${meeting.title}**\nDate: $dateStr at $timeStr\nDuration: ${meeting.durationMinutes} minutes\n---';
        await apiClient.createPost(widget.channelId!, message);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting scheduled!'), backgroundColor: successColor));
        Navigator.of(context).pop(meeting);
      }
    } catch (e) {
      if (mounted) { setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule: $e'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Meeting'), centerTitle: false),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Phase 10: Instant meeting link
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: _isCreating ? null : () async {
              setState(() => _isCreating = true);
              try {
                final info = await MeetingLinkService.generateMeetingLink();
                if (widget.channelId != null && widget.channelId!.isNotEmpty) {
                  final apiClient = getIt<MattermostApiClient>();
                  await apiClient.createPost(widget.channelId!, '\u{1F4F9} Join my meeting: \${info.joinUrl}');
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting link created!'), backgroundColor: successColor));
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) { setState(() => _isCreating = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: \$e'))); }
              }
            },
            icon: const Icon(Icons.videocam, color: Color(0xFF43A047)),
            label: const Text('Create Instant Meeting Link'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF43A047),
              side: const BorderSide(color: Color(0xFF43A047)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
          const SizedBox(height: 12),
          const Center(child: Text('or schedule for later', style: TextStyle(color: customGreyColor500, fontSize: 13))),
          const SizedBox(height: 12),
          TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Meeting Title',
            hintText: 'e.g., Sprint Planning', prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.calendar_today, color: inumPrimary), title: const Text('Date'),
            subtitle: Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: customGreyColor300)),
            onTap: _pickDate),
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.access_time, color: inumPrimary), title: const Text('Time'),
            subtitle: Text(DateFormat.jm().format(_selectedDate)),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: customGreyColor300)),
            onTap: _pickTime),
          const SizedBox(height: 16),
          const Text('Duration', style: TextStyle(fontWeight: FontWeight.w500)), const SizedBox(height: 8),
          Wrap(spacing: 8, children: _durationOptions.map((d) {
            final sel = d == _durationMinutes;
            final label = d >= 60 ? '${d ~/ 60}h' : '${d}m';
            return ChoiceChip(label: Text(label), selected: sel,
              onSelected: (_) => setState(() => _durationMinutes = d),
              selectedColor: inumPrimary.withAlpha(30),
              labelStyle: TextStyle(color: sel ? inumPrimary : customGreyColor700));
          }).toList()),
          const SizedBox(height: 16),
          if (widget.channelName != null) ...[
            ListTile(leading: const Icon(Icons.forum_outlined, color: inumSecondary), title: const Text('Channel'),
              subtitle: Text(widget.channelName!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: customGreyColor300))),
            const SizedBox(height: 16),
          ],
          TextField(controller: _notesController, decoration: InputDecoration(labelText: 'Notes (optional)',
            hintText: 'Agenda or additional details...', prefixIcon: const Icon(Icons.notes),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 3),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _isCreating ? null : _scheduleMeeting,
            icon: _isCreating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: white)) : const Icon(Icons.event_available),
            label: Text(_isCreating ? 'Scheduling...' : 'Schedule Meeting'),
            style: ElevatedButton.styleFrom(backgroundColor: inumPrimary, foregroundColor: white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ])),
    );
  }
}
