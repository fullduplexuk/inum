import 'package:flutter/material.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/core/services/disappearing_messages_service.dart';
import 'package:inum/presentation/blocs/disappearing_messages/disappearing_messages_cubit.dart';
import 'package:inum/presentation/views/chat/widgets/disappearing_messages_widgets.dart';
import 'package:inum/presentation/views/channels/media_gallery_view.dart';
import 'package:inum/core/services/blocked_users_service.dart';
import 'package:inum/presentation/views/settings/blocked_users_view.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/domain/models/chat/message_model.dart';

class ChannelInfoView extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelInfoView({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  State<ChannelInfoView> createState() => _ChannelInfoViewState();
}

class _ChannelInfoViewState extends State<ChannelInfoView> {
  final _api = getIt<MattermostApiClient>();
  Map<String, dynamic>? _channel;
  List<Map<String, dynamic>> _members = [];
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, String> _statusCache = {};
  bool _isLoading = true;
  bool _isMuted = false;
  bool _isEditing = false;
  List<MessageModel> _allMessages = [];
  bool _isLoadingMedia = false;
  final _nameController = TextEditingController();
  final _headerController = TextEditingController();
  final _purposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChannelInfo();
    _loadChannelMedia();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headerController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadChannelInfo() async {
    try {
      final channel = await _api.getChannel(widget.channelId);
      final members = await _api.getChannelMembers(widget.channelId);

      final userIds = members
          .map((m) => (m as Map<String, dynamic>)['user_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final users = await _api.getUsersByIds(userIds);
      for (final u in users) {
        final user = u as Map<String, dynamic>;
        _userCache[user['id'] as String] = user;
      }

      final statuses = await _api.getUserStatusesByIds(userIds);
      for (final s in statuses) {
        final status = s as Map<String, dynamic>;
        _statusCache[status['user_id'] as String? ?? ''] =
            status['status'] as String? ?? 'offline';
      }

      if (mounted) {
        setState(() {
          _channel = channel;
          _members = members.map((m) => m as Map<String, dynamic>).toList();
          _isLoading = false;
          _nameController.text = channel['display_name'] as String? ?? '';
          _headerController.text = channel['header'] as String? ?? '';
          _purposeController.text = channel['purpose'] as String? ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load channel info: $e')),
        );
      }
    }
  }

    Future<void> _loadChannelMedia() async {
    setState(() => _isLoadingMedia = true);
    try {
      final chatRepo = getIt<IChatRepository>();
      final messages = await chatRepo.getChannelMessages(widget.channelId, 0);
      if (mounted) {
        setState(() {
          _allMessages = messages;
          _isLoadingMedia = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMedia = false);
    }
  }

  String get _channelType => _channel?['type'] as String? ?? '';
  bool get _isDm => _channelType == 'D';
  bool get _isGroup => !_isDm;
  bool get _isCreator => _channel?['creator_id'] == _api.currentUserId;

  Future<void> _updateChannelInfo() async {
    try {
      await _api.updateChannel(
        widget.channelId,
        displayName: _nameController.text.trim(),
        header: _headerController.text.trim(),
        purpose: _purposeController.text.trim(),
      );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _addMember() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _UserSearchDialog(api: _api),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await _api.addChannelMember(widget.channelId, result);
        await _loadChannelInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member added')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add member: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: const Text('This will remove the user from this channel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.removeChannelMember(widget.channelId, userId);
        await _loadChannelInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e')),
          );
        }
      }
    }
  }

  Future<void> _leaveChannel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave channel?'),
        content: const Text('You will no longer receive messages from this channel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.leaveChannel(widget.channelId, _api.currentUserId ?? '');
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to leave: $e')),
          );
        }
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'online':
        return successColor;
      case 'away':
        return customOrangeColor;
      case 'dnd':
        return errorColor;
      default:
        return customGreyColor400;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.channelName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDm ? 'User Info' : 'Channel Info'),
        actions: [
          if (_isGroup && _isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateChannelInfo,
            ),
          if (_isGroup && !_isEditing && _isCreator)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isDm) _buildDmProfile(),
          if (_isGroup) ...[
            _buildChannelHeader(),
            const SizedBox(height: 16),
            _buildMuteToggle(),
            const SizedBox(height: 8),
            _buildDisappearingMessagesToggle(),
            const Divider(height: 32),
            _buildMemberSection(),
            const Divider(height: 32),
            // Shared media
            const Text('Shared Media',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_isLoadingMedia)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              MediaGalleryTabs(channelId: widget.channelId, messages: _allMessages),
            const Divider(height: 32),
            _buildLeaveButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildDmProfile() {
    final otherUserId = _members
        .map((m) => m['user_id'] as String? ?? '')
        .where((id) => id != _api.currentUserId)
        .firstOrNull;

    if (otherUserId == null) {
      return const Center(child: Text('No user info available'));
    }

    final user = _userCache[otherUserId] ?? {};
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final dn = '$firstName $lastName'.trim();
    final displayName = dn.isNotEmpty ? dn : username;
    final status = _statusCache[otherUserId] ?? 'offline';

    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 48,
          backgroundColor: inumPrimary.withAlpha(30),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: inumPrimary),
          ),
        ),
        const SizedBox(height: 12),
        Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('@$username', style: const TextStyle(fontSize: 15, color: customGreyColor500)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(_capitalise(status), style: const TextStyle(color: customGreyColor600)),
          ],
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(email),
            subtitle: const Text('Email'),
          ),
        ],
        const SizedBox(height: 16),
        _buildMuteToggle(),
        const SizedBox(height: 8),
        _buildDisappearingMessagesToggle(),
        const Divider(height: 32),
        // Block & Report
        _buildBlockReportSection(otherUserId),
        const Divider(height: 32),
        // Shared media
        if (_isLoadingMedia)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          MediaGalleryTabs(channelId: widget.channelId, messages: _allMessages),
      ],
    );
  }

  Widget _buildBlockReportSection(String userId) {
    final user = _userCache[userId] ?? {};
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final dn = '$firstName $lastName'.trim();
    final displayName = dn.isNotEmpty ? dn : username;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.block, color: errorColor),
          title: const Text('Block User', style: TextStyle(color: errorColor)),
          onTap: () => showBlockUserDialog(context, userId, displayName),
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined, color: customOrangeColor),
          title: const Text('Report User'),
          onTap: () => showReportUserDialog(context, userId, displayName),
        ),
      ],
    );
  }

  static String _capitalise(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _buildChannelHeader() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Channel Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _headerController,
            decoration: InputDecoration(
              labelText: 'Header',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _purposeController,
            decoration: InputDecoration(
              labelText: 'Purpose',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
        ],
      );
    }

    final displayName = _channel?['display_name'] as String? ?? widget.channelName;
    final header = _channel?['header'] as String? ?? '';
    final purpose = _channel?['purpose'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: inumPrimary.withAlpha(30),
            child: Icon(
              _channelType == 'P' ? Icons.lock : Icons.group,
              size: 36, color: inumPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        if (header.isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(child: Text(header, style: const TextStyle(color: customGreyColor600))),
        ],
        if (purpose.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(child: Text(purpose, style: const TextStyle(fontSize: 13, color: customGreyColor500))),
        ],
      ],
    );
  }

  Widget _buildDisappearingMessagesToggle() {
    return BlocBuilder<DisappearingMessagesCubit, DisappearingMessagesState>(
      builder: (context, state) {
        final cubit = context.read<DisappearingMessagesCubit>();
        final current = cubit.getDuration(widget.channelId);
        final isOn = current != DisappearingDuration.off;

        return Column(
          children: [
            SwitchListTile(
              title: const Text('Disappearing Messages'),
              subtitle: Text(isOn ? 'Messages auto-delete after ${current.label}' : 'Messages are kept forever'),
              secondary: Icon(
                Icons.timer_outlined,
                color: isOn ? inumSecondary : customGreyColor400,
              ),
              value: isOn,
              activeColor: inumSecondary,
              onChanged: (val) {
                if (val) {
                  _showDurationPicker(cubit);
                } else {
                  cubit.setDuration(widget.channelId, DisappearingDuration.off);
                }
              },
            ),
            if (isOn)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: DisappearingDurationPicker(
                  currentDuration: current,
                  onChanged: (d) => cubit.setDuration(widget.channelId, d),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDurationPicker(DisappearingMessagesCubit cubit) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Auto-delete messages after:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...DisappearingDuration.values.where((d) => d != DisappearingDuration.off).map((d) {
                return ListTile(
                  title: Text(d.label),
                  leading: const Icon(Icons.timer_outlined),
                  onTap: () {
                    cubit.setDuration(widget.channelId, d);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuteToggle() {
    return SwitchListTile(
      title: const Text('Mute Channel'),
      subtitle: const Text('Silence notifications for this channel'),
      secondary: Icon(
        _isMuted ? Icons.notifications_off : Icons.notifications,
        color: _isMuted ? customGreyColor400 : inumPrimary,
      ),
      value: _isMuted,
      activeColor: inumPrimary,
      onChanged: (val) => setState(() => _isMuted = val),
    );
  }

  Widget _buildMemberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Members (${_members.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._members.map(_buildMemberTile),
      ],
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final userId = member['user_id'] as String? ?? '';
    final user = _userCache[userId] ?? {};
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final dn = '$firstName $lastName'.trim();
    final displayName = dn.isNotEmpty ? dn : username;
    final status = _statusCache[userId] ?? 'offline';
    final isCurrentUser = userId == _api.currentUserId;
    final isChannelCreator = userId == (_channel?['creator_id'] as String? ?? '');

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: inumPrimary.withAlpha(30),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: inumPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
                border: Border.all(color: white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Flexible(child: Text(displayName)),
          if (isCurrentUser)
            const Text(' (you)', style: TextStyle(fontSize: 12, color: customGreyColor500)),
          if (isChannelCreator)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: inumSecondary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Admin', style: TextStyle(fontSize: 10, color: inumSecondary)),
            ),
        ],
      ),
      subtitle: Text('@$username', style: const TextStyle(fontSize: 13)),
      trailing: (_isCreator && !isCurrentUser)
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: errorColor, size: 20),
              onPressed: () => _removeMember(userId),
            )
          : null,
    );
  }

  Widget _buildLeaveButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _leaveChannel,
        icon: const Icon(Icons.exit_to_app, color: errorColor),
        label: const Text('Leave Channel', style: TextStyle(color: errorColor)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: errorColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _UserSearchDialog extends StatefulWidget {
  final MattermostApiClient api;
  const _UserSearchDialog({required this.api});

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  Future<void> _search(String term) async {
    if (term.length < 2) return;
    setState(() => _searching = true);
    try {
      final results = await widget.api.searchUsers(term);
      if (mounted) {
        setState(() {
          _results = results.map((u) => u as Map<String, dynamic>).toList();
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Member'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  final firstName = user['first_name'] as String? ?? '';
                  final lastName = user['last_name'] as String? ?? '';
                  final username = user['username'] as String? ?? '';
                  final dn = '$firstName $lastName'.trim();
                  final displayName = dn.isNotEmpty ? dn : username;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: inumPrimary.withAlpha(30),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: inumPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(displayName),
                    subtitle: Text('@$username'),
                    onTap: () => Navigator.pop(context, user['id'] as String? ?? ''),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
