import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/data/api/mattermost/mattermost_api_client.dart';
import 'package:inum/domain/models/chat/message_model.dart';
import 'package:inum/presentation/design_system/colors.dart';

class MessageSearchView extends StatefulWidget {
  const MessageSearchView({super.key});

  @override
  State<MessageSearchView> createState() => _MessageSearchViewState();
}

class _MessageSearchViewState extends State<MessageSearchView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<MessageModel> _results = [];
  // channelId -> channel display name cache
  final Map<String, String> _channelNames = {};

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = getIt<MattermostApiClient>();
      final response = await apiClient.searchPosts(query);

      final order = response['order'] as List<dynamic>? ?? [];
      final posts = response['posts'] as Map<String, dynamic>? ?? {};

      final messages = <MessageModel>[];
      for (final postId in order) {
        final post = posts[postId as String];
        if (post != null) {
          messages.add(MessageModel.fromMattermost(post as Map<String, dynamic>));
        }
      }

      // Fetch channel names for results
      final channelIds = messages.map((m) => m.channelId).toSet();
      for (final cid in channelIds) {
        if (!_channelNames.containsKey(cid)) {
          try {
            final ch = await apiClient.getChannel(cid);
            _channelNames[cid] = ch['display_name'] as String? ?? ch['name'] as String? ?? cid;
          } catch (_) {
            _channelNames[cid] = cid;
          }
        }
      }

      if (mounted) {
        setState(() {
          _results = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group results by channel
    final grouped = <String, List<MessageModel>>{};
    for (final msg in _results) {
      grouped.putIfAbsent(msg.channelId, () => []).add(msg);
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Search across all channels'
                        : 'No results found',
                    style: const TextStyle(color: customGreyColor500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final channelId = grouped.keys.elementAt(index);
                    final messages = grouped[channelId]!;
                    final channelName = _channelNames[channelId] ?? channelId;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Text(
                            channelName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: inumPrimary,
                            ),
                          ),
                        ),
                        ...messages.map((msg) => _SearchResultTile(
                              message: msg,
                              channelName: channelName,
                              onTap: () {
                                final name = Uri.encodeComponent(channelName);
                                context.push(
                                  '${RouterEnum.chatView.routeName}?channelId=${msg.channelId}&channelName=$name',
                                );
                              },
                            )),
                        const Divider(height: 16),
                      ],
                    );
                  },
                ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final MessageModel message;
  final String channelName;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.message,
    required this.channelName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        message.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        DateFormat.yMd().add_jm().format(message.createAt),
        style: const TextStyle(fontSize: 11, color: customGreyColor500),
      ),
      dense: true,
      onTap: onTap,
    );
  }
}
