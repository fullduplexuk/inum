import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inum/data/repository/call/call_history_repository.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/domain/models/call/voicemail_model.dart';
import 'package:inum/presentation/design_system/colors.dart';

class VoicemailView extends StatefulWidget {
  const VoicemailView({super.key});

  @override
  State<VoicemailView> createState() => _VoicemailViewState();
}

class _VoicemailViewState extends State<VoicemailView> {
  List<VoicemailModel> _voicemails = [];
  bool _loading = true;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _loadVoicemails();
  }

  Future<void> _loadVoicemails() async {
    setState(() => _loading = true);
    try {
      final repo = getIt<ICallHistoryRepository>();
      final vms = await repo.getVoicemails();
      setState(() {
        _voicemails = vms;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    try {
      final repo = getIt<ICallHistoryRepository>();
      await repo.markVoicemailRead(id);
      await _loadVoicemails();
    } catch (_) {}
  }

  Future<void> _deleteVoicemail(String id) async {
    try {
      final repo = getIt<ICallHistoryRepository>();
      await repo.deleteVoicemail(id);
      await _loadVoicemails();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voicemail'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _voicemails.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVoicemails,
                  child: ListView.separated(
                    itemCount: _voicemails.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final vm = _voicemails[index];
                      final isExpanded = _expandedId == vm.id;
                      return _VoicemailTile(
                        voicemail: vm,
                        isExpanded: isExpanded,
                        onTap: () {
                          setState(() {
                            _expandedId = isExpanded ? null : vm.id;
                          });
                          if (!vm.isRead) {
                            _markRead(vm.id);
                          }
                        },
                        onDelete: () => _deleteVoicemail(vm.id),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.voicemail, size: 64, color: customGreyColor400),
          SizedBox(height: 16),
          Text(
            'No voicemails',
            style: TextStyle(color: customGreyColor600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _VoicemailTile extends StatelessWidget {
  final VoicemailModel voicemail;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VoicemailTile({
    required this.voicemail,
    required this.isExpanded,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final durationStr = _formatDuration(voicemail.durationSecs);
    final dateStr = _formatDate(voicemail.createdAt);

    return Dismissible(
      key: ValueKey(voicemail.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: inumPrimary.withAlpha(30),
                    child: Text(
                      voicemail.fromUsername.isNotEmpty
                          ? voicemail.fromUsername[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: inumPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voicemail.fromUsername.isNotEmpty
                              ? voicemail.fromUsername
                              : 'Unknown',
                          style: TextStyle(
                            fontWeight: voicemail.isRead
                                ? FontWeight.w400
                                : FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voicemail.transcript?.isNotEmpty == true
                              ? voicemail.transcript!
                              : 'Voicemail - $durationStr',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: voicemail.isRead
                                ? secondaryTextColor
                                : customGreyColor900,
                            fontWeight: voicemail.isRead
                                ? FontWeight.w400
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(dateStr,
                      style: const TextStyle(fontSize: 12, color: customGreyColor600)),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                if (voicemail.transcript?.isNotEmpty == true)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      voicemail.transcript!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: customGreyColor600),
                    const SizedBox(width: 4),
                    Text(durationStr, style: const TextStyle(fontSize: 13, color: customGreyColor600)),
                    const SizedBox(width: 16),
                    if (voicemail.audioUrl?.isNotEmpty == true)
                      TextButton.icon(
                        onPressed: () {
                          // Future: audio playback
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Play'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat.jm().format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.E().format(dt);
    return DateFormat.MMMd().format(dt);
  }
}
