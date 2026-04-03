import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/presentation/blocs/contacts/contacts_cubit.dart';
import 'package:inum/presentation/blocs/contacts/contacts_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ContactsCubit>().loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ContactsCubit>().searchContacts(query);
  }

  Future<void> _onRefresh() async {
    await context.read<ContactsCubit>().loadContacts();
  }

  Future<void> _openDm(ContactUser contact) async {
    try {
      final apiClient = getIt<MattermostApiClient>();
      final currentUserId = apiClient.currentUserId ?? '';
      if (currentUserId.isEmpty) return;

      final channel = await apiClient.createDirectChannel([currentUserId, contact.id]);
      final channelId = channel['id'] as String? ?? '';
      if (channelId.isNotEmpty && mounted) {
        context.push(
          '${RouterEnum.chatView.routeName}?channelId=$channelId&channelName=${Uri.encodeComponent(contact.displayName)}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open conversation: $e')),
        );
      }
    }
  }

  void _callContact(ContactUser contact, {bool isVideo = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${contact.displayName}...')),
    );
  }

  // Phase 7: Open SMS conversation with contact
  void _smsContact(ContactUser contact) {
    context.push('${RouterEnum.smsView.routeName}/${Uri.encodeComponent(contact.username)}');
  }

  Color _statusColor(String status) {
    return switch (status) {
      'online' => Colors.green,
      'away' => Colors.orange,
      'dnd' => Colors.red,
      _ => customGreyColor500,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
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
                hintText: 'Search contacts...',
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
            child: BlocBuilder<ContactsCubit, ContactsState>(
              builder: (context, state) {
                if (state is ContactsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ContactsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: customGreyColor500),
                        const SizedBox(height: 16),
                        const Text('Error loading contacts',
                            style: TextStyle(color: customGreyColor700)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _onRefresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ContactsLoaded) {
                  final contacts = state.filteredContacts;
                  if (contacts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.contacts_outlined, size: 64, color: customGreyColor400),
                          const SizedBox(height: 16),
                          Text(
                            state.searchQuery.isNotEmpty
                                ? 'No contacts matching "${state.searchQuery}"'
                                : 'No contacts yet',
                            style: const TextStyle(color: customGreyColor600, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: inumPrimary.withAlpha(30),
                                child: Text(
                                  contact.displayName.isNotEmpty
                                      ? contact.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: inumPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _statusColor(contact.status),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            contact.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '@${contact.username}',
                            style: const TextStyle(color: secondaryTextColor, fontSize: 13),
                          ),
                          onTap: () => _openDm(contact),
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.call),
                                      title: const Text('Audio Call'),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _callContact(contact);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.videocam),
                                      title: const Text('Video Call'),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _callContact(contact, isVideo: true);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.chat),
                                      title: const Text('Message'),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _openDm(contact);
                                      },
                                    ),
                                    // Phase 7: SMS option in contact actions
                                    ListTile(
                                      leading: const Icon(Icons.sms_outlined),
                                      title: const Text('SMS'),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _smsContact(contact);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
