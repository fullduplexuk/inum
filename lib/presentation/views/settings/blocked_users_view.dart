import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:inum/core/services/blocked_users_service.dart";
import "package:inum/core/di/dependency_injector.dart";
import "package:inum/data/api/mattermost/mattermost_api_client.dart";
import "package:inum/presentation/design_system/colors.dart";

class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  final _api = getIt<MattermostApiClient>();
  final Map<String, Map<String, dynamic>> _userCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final blockedIds = context.read<BlockedUsersCubit>().state.blockedIds;
    if (blockedIds.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final users = await _api.getUsersByIds(blockedIds.toList());
      for (final u in users) {
        final user = u as Map<String, dynamic>;
        _userCache[user["id"] as String] = user;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _unblockUser(String userId) {
    final cubit = context.read<BlockedUsersCubit>();
    cubit.unblockUser(userId);
    setState(() {
      _userCache.remove(userId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User unblocked")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Blocked Users"),
      ),
      body: BlocBuilder<BlockedUsersCubit, BlockedUsersState>(
        builder: (context, state) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.blockedIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: customGreyColor400),
                  SizedBox(height: 16),
                  Text(
                    "No blocked users",
                    style: TextStyle(fontSize: 16, color: customGreyColor600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Users you block will appear here",
                    style: TextStyle(fontSize: 13, color: customGreyColor500),
                  ),
                ],
              ),
            );
          }

          final blockedList = state.blockedIds.toList();
          return ListView.separated(
            itemCount: blockedList.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final userId = blockedList[index];
              final user = _userCache[userId] ?? {};
              final firstName = user["first_name"] as String? ?? "";
              final lastName = user["last_name"] as String? ?? "";
              final username = user["username"] as String? ?? userId.substring(0, 8);
              final dn = "$firstName $lastName".trim();
              final displayName = dn.isNotEmpty ? dn : username;

              return _BlockedUserTile(
                displayName: displayName,
                username: username,
                onUnblock: () => _unblockUser(userId),
              );
            },
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends StatefulWidget {
  final String displayName;
  final String username;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.displayName,
    required this.username,
    required this.onUnblock,
  });

  @override
  State<_BlockedUserTile> createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends State<_BlockedUserTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInBack));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleUnblock() async {
    await _slideController.forward();
    widget.onUnblock();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: errorColor.withAlpha(30),
          child: const Icon(Icons.block, color: errorColor, size: 20),
        ),
        title: Text(widget.displayName),
        subtitle: Text("@${widget.username}",
            style: const TextStyle(fontSize: 13, color: customGreyColor500)),
        trailing: TextButton(
          onPressed: _handleUnblock,
          child: const Text("Unblock", style: TextStyle(color: inumPrimary)),
        ),
      ),
    );
  }
}

// --- Block / Report Dialogs ---

/// Shows confirmation dialog then blocks the user.
Future<bool> showBlockUserDialog(BuildContext context, String userId, String displayName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Block User"),
      content: Text(
        'Are you sure you want to block $displayName? You won\'t receive messages from them.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: errorColor),
          child: const Text("Block"),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    if (context.mounted) {
      context.read<BlockedUsersCubit>().blockUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$displayName has been blocked")),
      );
    }
    return true;
  }
  return false;
}

/// Shows report user dialog with reason picker.
Future<void> showReportUserDialog(BuildContext context, String userId, String displayName) async {
  const reasons = ["Spam", "Harassment", "Inappropriate content", "Other"];

  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text("Report $displayName"),
      children: reasons.map((r) {
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, r),
          child: Text(r),
        );
      }).toList(),
    ),
  );

  if (reason != null && context.mounted) {
    context.read<BlockedUsersCubit>().reportUser(userId, reason);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report submitted. Thank you.")),
    );
  }
}
