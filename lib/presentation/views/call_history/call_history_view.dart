import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/domain/models/call/call_record.dart';
import 'package:inum/presentation/blocs/call_history/call_history_cubit.dart';
import 'package:inum/presentation/blocs/call_history/call_history_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class CallHistoryView extends StatefulWidget {
  const CallHistoryView({super.key});

  @override
  State<CallHistoryView> createState() => _CallHistoryViewState();
}

class _CallHistoryViewState extends State<CallHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _filters = [
    CallHistoryFilter.all,
    CallHistoryFilter.missed,
    CallHistoryFilter.incoming,
    CallHistoryFilter.outgoing,
  ];

  static const _tabLabels = ['All', 'Missed', 'Incoming', 'Outgoing'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    context.read<CallHistoryCubit>().loadHistory();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<CallHistoryCubit>().loadHistory(filter: _filters[_tabController.index]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final cubit = context.read<CallHistoryCubit>();
    final currentState = cubit.state;
    final filter = currentState is CallHistoryLoaded
        ? currentState.filter
        : CallHistoryFilter.all;
    await cubit.loadHistory(filter: filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
          labelColor: inumPrimary,
          unselectedLabelColor: customGreyColor600,
          indicatorColor: inumPrimary,
        ),
      ),
      body: BlocBuilder<CallHistoryCubit, CallHistoryState>(
        builder: (context, state) {
          if (state is CallHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CallHistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: customGreyColor500),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: customGreyColor700)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is CallHistoryLoaded) {
            if (state.records.isEmpty) {
              return _buildEmptyState(state.filter);
            }
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.separated(
                itemCount: state.records.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  return _CallRecordTile(record: state.records[index]);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(CallHistoryFilter filter) {
    final label = switch (filter) {
      CallHistoryFilter.all => 'No call history',
      CallHistoryFilter.missed => 'No missed calls',
      CallHistoryFilter.incoming => 'No incoming calls',
      CallHistoryFilter.outgoing => 'No outgoing calls',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.call_outlined, size: 64, color: customGreyColor400),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: customGreyColor600, fontSize: 16)),
        ],
      ),
    );
  }
}

class _CallRecordTile extends StatelessWidget {
  final CallRecord record;
  const _CallRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isMissed = record.status == CallRecordStatus.missed;
    final nameColor = isMissed ? errorColor : null;
    final isVideo = record.callType == 'video';

    final displayName = record.direction == CallDirection.outgoing
        ? record.targetUsername
        : record.initiatedByUsername;

    final directionIcon = record.direction == CallDirection.incoming
        ? Icons.call_received
        : Icons.call_made;
    final directionColor = isMissed
        ? errorColor
        : (record.direction == CallDirection.incoming ? successColor : inumPrimary);

    final timeStr = _formatTime(record.startedAt);
    final durationStr = record.durationSecs > 0
        ? _formatDuration(record.durationSecs)
        : (isMissed ? 'Missed' : 'No answer');

    final hasRecording = record.recordingUrl != null &&
        record.recordingUrl!.isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: inumPrimary.withAlpha(30),
        child: Icon(
          isVideo ? Icons.videocam : Icons.call,
          color: isMissed ? errorColor : inumPrimary,
          size: 20,
        ),
      ),
      title: Text(
        displayName.isNotEmpty ? displayName : 'Unknown',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: nameColor,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(directionIcon, size: 14, color: directionColor),
          const SizedBox(width: 4),
          Text(
            durationStr,
            style: TextStyle(
              fontSize: 13,
              color: isMissed ? errorColor : secondaryTextColor,
            ),
          ),
          if (hasRecording) ...[
            const SizedBox(width: 8),
            const Icon(Icons.videocam, size: 14, color: inumSecondary),
          ],
          if (record.transcriptUrl != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.subtitles, size: 14, color: inumSecondary),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasRecording)
            IconButton(
              icon: const Icon(Icons.play_circle_outline,
                  color: inumSecondary, size: 22),
              tooltip: 'View recording',
              onPressed: () {
                context.push(
                  '${RouterEnum.recordingsView.routeName}/${record.roomId}',
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: const TextStyle(fontSize: 12, color: customGreyColor600),
          ),
        ],
      ),
      onTap: () {
        // Future: call detail / call back
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat.jm().format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.E().format(dt);
    return DateFormat.MMMd().format(dt);
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}
