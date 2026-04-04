import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_cubit.dart';
import 'package:inum/presentation/blocs/channel_list/channel_list_state.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/design_system/widgets/user_avatar.dart';
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
    final name = channel.displayName.isNotEmpty ? channel.displayName : 'Chat';
    context.push(
      '${RouterEnum.chatView.routeName}?channelId=${channel.id}&channelName=${Uri.encodeComponent(name)}',
    );
  }

  void _openNewChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _NewChatSheet(),
    );
  }

  Widget _buildChannelLeading(ChannelModel channel) {
    final chatRepo = getIt<IChatRepository>();

    if (channel.isDirect) {
      final currentUid = chatRepo.currentUserId ?? '';
      final otherId = channel.otherUserId(currentUid);
      final displayName = channel.displayName.isNotEmpty ? channel.displayName : 'User';
      return UserAvatar(
        name: displayName,
        imageUrl: otherId != null ? chatRepo.getProfileImageUrl(otherId) : null,
        authToken: chatRepo.authToken,
        radius: 22,
      );
    } else if (channel.isGroup) {
      return CircleAvatar(
        backgroundColor: inumSecondary.withAlpha(30),
        radius: 22,
        child: const Icon(Icons.group, color: inumSecondary, size: 22),
      );
    } else if (channel.isPrivate) {
      return CircleAvatar(
        backgroundColor: inumPrimary.withAlpha(30),
        radius: 22,
        child: const Icon(Icons.lock, color: inumPrimary, size: 20),
      );
    } else {
      return CircleAvatar(
        backgroundColor: inumPrimary.withAlpha(30),
        radius: 22,
        child: const Icon(Icons.tag, color: inumPrimary, size: 20),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INUM', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewChat,
        backgroundColor: inumPrimary,
        child: const Icon(Icons.edit, color: white),
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
                          leading: _buildChannelLeading(channel),
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
    final hasUnread = channel.unreadCount > 0;
    final displayName = channel.displayName.isNotEmpty
        ? channel.displayName
        : (channel.isDirect ? 'Direct Message' : channel.name);

    // Subtitle: show last message preview, or fall back to header
    String? subtitle;
    if (channel.lastMessage.isNotEmpty) {
      subtitle = channel.lastMessage;
    } else if (channel.header.isNotEmpty) {
      subtitle = channel.header;
    }

    return ListTile(
      leading: leading,
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread ? customGreyColor800 : secondaryTextColor,
                fontSize: 13,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeStr, style: TextStyle(
            fontSize: 12,
            color: hasUnread ? inumPrimary : customGreyColor600,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          )),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              constraints: const BoxConstraints(minWidth: 22),
              decoration: BoxDecoration(
                color: inumPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                channel.unreadCount > 99 ? '99+' : channel.unreadCount.toString(),
                textAlign: TextAlign.center,
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

/// Bottom sheet for starting a new DM conversation
class _NewChatSheet extends StatefulWidget {
  const _NewChatSheet();

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _results = [];
        _lastQuery = query;
      });
      return;
    }
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() => _loading = true);
    try {
      final chatRepo = getIt<IChatRepository>();
      final results = await chatRepo.searchUsers(query);
      // Filter out current user
      final currentUid = chatRepo.currentUserId ?? '';
      final filtered = results.where((u) => (u['id'] as String?) != currentUid).toList();
      if (mounted) {
        setState(() {
          _results = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startDm(Map<String, dynamic> user) async {
    final userId = user['id'] as String? ?? '';
    if (userId.isEmpty) return;

    setState(() => _loading = true);
    try {
      final chatRepo = getIt<IChatRepository>();
      final channelId = await chatRepo.createDirectMessage(userId);
      if (channelId.isNotEmpty && mounted) {
        final first = user['first_name'] as String? ?? '';
        final last = user['last_name'] as String? ?? '';
        final username = user['username'] as String? ?? '';
        final name = (first.isNotEmpty || last.isNotEmpty)
            ? '$first $last'.trim()
            : username;
        Navigator.of(context).pop();
        context.push(
          '${RouterEnum.chatView.routeName}?channelId=$channelId&channelName=${Uri.encodeComponent(name)}',
        );
        // Reload channels to pick up the new DM
        context.read<ChannelListCubit>().loadChannels();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create conversation: $e')),
        );
      }
    }
  }

  String _userDisplayName(Map<String, dynamic> user) {
    final first = user['first_name'] as String? ?? '';
    final last = user['last_name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return username;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: customGreyColor400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'New Conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.length < 2
                              ? 'Type at least 2 characters to search'
                              : 'No users found',
                          style: const TextStyle(color: customGreyColor500),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final displayName = _userDisplayName(user);
                          final username = user['username'] as String? ?? '';
                          return ListTile(
                            leading: UserAvatar(
                              name: displayName,
                              radius: 20,
                            ),
                            title: Text(displayName),
                            subtitle: Text('@$username',
                                style: const TextStyle(fontSize: 13, color: secondaryTextColor)),
                            onTap: () => _startDm(user),
                          );
                        },
                      ),
              ),
          ],
        );
      },
    );
  }
}
