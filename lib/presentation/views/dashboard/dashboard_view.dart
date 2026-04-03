import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_cubit.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_state.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/domain/models/chat/channel_model.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ChannelListCubit>();
    if (cubit.state is ChannelListLoading) {
      cubit.loadChannels();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ChannelListCubit>().searchChannels(query);
  }

  Future<void> _onRefresh() async {
    context.read<ChannelListCubit>().loadChannels();
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  void _onChannelTap(ChannelModel channel) {
    context.push(
      '${RouterEnum.chatView.routeName}?channelId=${channel.id}&channelName=${Uri.encodeComponent(channel.displayName)}',
    );
  }

  Widget _buildChannelIcon(ChannelModel channel) {
    IconData icon;
    if (channel.isDirect) {
      icon = Icons.person;
    } else if (channel.isGroup) {
      icon = Icons.group;
    } else if (channel.isPrivate) {
      icon = Icons.lock;
    } else {
      icon = Icons.tag;
    }
    return CircleAvatar(
      backgroundColor: inumPrimary.withAlpha(30),
      child: Icon(icon, color: inumPrimary, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INUM', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search channels...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ChannelListCubit, ChannelListState>(
              builder: (context, state) {
                if (state is ChannelListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ChannelListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: customGreyColor500),
                        const SizedBox(height: 16),
                        const Text('Error loading channels',
                            style: TextStyle(color: customGreyColor700)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.read<ChannelListCubit>().loadChannels(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ChannelListLoaded) {
                  final channels = state.filteredChannels;
                  if (channels.isEmpty) {
                    return const Center(
                      child: Text('No channels found',
                          style: TextStyle(color: customGreyColor500)),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.separated(
                      itemCount: channels.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        return _ChannelListItem(
                          channel: channel,
                          onTap: () => _onChannelTap(channel),
                          leading: _buildChannelIcon(channel),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelListItem extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback onTap;
  final Widget leading;

  const _ChannelListItem({
    required this.channel,
    required this.onTap,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = timeago.format(channel.lastPostAt, locale: 'en_short');

    return ListTile(
      leading: leading,
      title: Text(
        channel.displayName.isNotEmpty ? channel.displayName : 'Direct Message',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: channel.header.isNotEmpty
          ? Text(
              channel.header,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: secondaryTextColor, fontSize: 13),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeStr, style: const TextStyle(fontSize: 12, color: customGreyColor600)),
          if (channel.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: inumSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                channel.unreadCount.toString(),
                style: const TextStyle(color: white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
