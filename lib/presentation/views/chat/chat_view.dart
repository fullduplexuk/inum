import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/domain/models/chat/message_model.dart';
import 'package:inum/presentation/design_system/colors.dart';

class ChatView extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChatView({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  late final IChatRepository _chatRepo;

  @override
  void initState() {
    super.initState();
    _chatRepo = getIt<IChatRepository>();
    _loadMessages();
    _listenToWsEvents();
    _scrollController.addListener(_onScroll);
    _chatRepo.markChannelAsRead(widget.channelId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _listenToWsEvents() {
    _wsSubscription = _chatRepo.wsEvents.listen((event) {
      final eventType = event['event'] as String?;
      final data = event['data'] as Map<String, dynamic>? ?? {};

      if (eventType == 'posted') {
        _handleNewPost(data);
      } else if (eventType == 'post_edited') {
        _handleEditedPost(data);
      } else if (eventType == 'post_deleted') {
        _handleDeletedPost(data);
      }
    });
  }

  void _handleNewPost(Map<String, dynamic> data) {
    final postStr = data['post'] as String?;
    if (postStr == null) return;
    try {
      final postJson = jsonDecode(postStr) as Map<String, dynamic>;
      if (postJson['channel_id'] == widget.channelId) {
        final msg = MessageModel.fromMattermost(postJson);
        if (mounted) setState(() => _messages.insert(0, msg));
      }
    } catch (_) {}
  }

  void _handleEditedPost(Map<String, dynamic> data) {
    final postStr = data['post'] as String?;
    if (postStr == null) return;
    try {
      final postJson = jsonDecode(postStr) as Map<String, dynamic>;
      if (postJson['channel_id'] == widget.channelId) {
        final msg = MessageModel.fromMattermost(postJson);
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id);
            if (idx != -1) _messages[idx] = msg;
          });
        }
      }
    } catch (_) {}
  }

  void _handleDeletedPost(Map<String, dynamic> data) {
    final postStr = data['post'] as String?;
    if (postStr == null) return;
    try {
      final postJson = jsonDecode(postStr) as Map<String, dynamic>;
      if (postJson['channel_id'] == widget.channelId) {
        if (mounted) {
          setState(() => _messages.removeWhere((m) => m.id == postJson['id']));
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final messages = await _chatRepo.getChannelMessages(widget.channelId, _page);
    if (mounted) {
      setState(() {
        _messages.addAll(messages);
        _isLoading = false;
        _page++;
        if (messages.length < 60) _hasMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMessages();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    try {
      await _chatRepo.sendMessage(widget.channelId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName.isNotEmpty ? widget.channelName : 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 12, right: 4, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: inumPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            message.message,
            style: const TextStyle(color: customGreyColor500, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    final timeStr = timeago.format(message.createAt, locale: 'en_short');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: inumPrimary.withAlpha(30),
            child: Text(
              message.userId.isNotEmpty ? message.userId[0].toUpperCase() : '?',
              style: const TextStyle(color: inumPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        message.userId,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(timeStr, style: const TextStyle(color: customGreyColor500, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(message.message, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
