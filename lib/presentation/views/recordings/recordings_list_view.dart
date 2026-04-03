import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/domain/models/call/recording_model.dart';
import 'package:inum/presentation/blocs/recordings/recordings_cubit.dart';
import 'package:inum/presentation/blocs/recordings/recordings_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class RecordingsListView extends StatefulWidget {
  const RecordingsListView({super.key});

  @override
  State<RecordingsListView> createState() => _RecordingsListViewState();
}

class _RecordingsListViewState extends State<RecordingsListView> {
  @override
  void initState() {
    super.initState();
    context.read<RecordingsCubit>().loadRecordings();
  }

  Future<void> _onRefresh() async {
    await context.read<RecordingsCubit>().loadRecordings();
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
    return DateFormat.yMMMd().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings'),
        centerTitle: false,
      ),
      body: BlocBuilder<RecordingsCubit, RecordingsState>(
        builder: (context, state) {
          if (state is RecordingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RecordingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: customGreyColor500),
                  const SizedBox(height: 16),
                  Text(state.message,
                      style: const TextStyle(color: customGreyColor700)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is RecordingsLoaded) {
            if (state.recordings.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off_outlined,
                        size: 64, color: customGreyColor400),
                    SizedBox(height: 16),
                    Text(
                      'No recordings yet',
                      style:
                          TextStyle(color: customGreyColor600, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Recorded calls will appear here',
                      style: TextStyle(
                        color: customGreyColor500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.separated(
                itemCount: state.recordings.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  return _RecordingTile(
                    recording: state.recordings[index],
                    formatDuration: _formatDuration,
                    formatDate: _formatDate,
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  final RecordingModel recording;
  final String Function(int) formatDuration;
  final String Function(DateTime) formatDate;

  const _RecordingTile({
    required this.recording,
    required this.formatDuration,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: inumSecondary.withAlpha(30),
        child: const Icon(Icons.videocam, color: inumSecondary, size: 20),
      ),
      title: Text(
        recording.participants.isNotEmpty
            ? recording.participants.join(', ')
            : 'Recording',
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            formatDuration(recording.durationSecs),
            style: const TextStyle(fontSize: 13, color: secondaryTextColor),
          ),
          if (recording.transcriptUrl != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.subtitles, size: 14, color: inumSecondary),
          ],
          if (recording.summaryUrl != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.auto_awesome, size: 14, color: inumSecondary),
          ],
        ],
      ),
      trailing: Text(
        formatDate(recording.createdAt),
        style: const TextStyle(fontSize: 12, color: customGreyColor600),
      ),
      onTap: () {
        context.push(
          '${RouterEnum.recordingsView.routeName}/${recording.id}',
        );
      },
    );
  }
}
