import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:inum/core/interfaces/i_chat_repository.dart';
import 'package:inum/core/di/dependency_injector.dart';
import 'package:inum/core/services/web/web_drop_helper.dart';
import 'package:inum/domain/models/chat/message_model.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/design_system/widgets/user_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inum/presentation/blocs/call/call_cubit.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/presentation/views/chat/widgets/voice_message_recorder.dart';
import 'package:inum/presentation/views/chat/widgets/voice_message_player.dart';
import 'package:inum/presentation/views/chat/widgets/sticker_picker.dart';
import 'package:inum/presentation/blocs/chat_session/chat_session_cubit.dart';
import 'package:inum/presentation/blocs/saved/saved_messages_cubit.dart';
import 'package:inum/presentation/blocs/saved/saved_messages_state.dart';
import 'package:inum/presentation/views/chat/widgets/formatted_text.dart';
import 'package:inum/presentation/views/chat/widgets/poll_widget.dart';
import 'package:inum/presentation/views/chat/widgets/unread_separator.dart';
import 'package:inum/presentation/views/chat/widgets/disappearing_messages_widgets.dart';
import 'package:inum/presentation/blocs/disappearing_messages/disappearing_messages_cubit.dart';
import 'package:inum/core/services/disappearing_messages_service.dart';

// Emoji name to unicode mapping for common reactions
const Map<String, String> kEmojiMap = {
  'thumbsup': '\u{1F44D}',
  '+1': '\u{1F44D}',
  'heart': '\u{2764}\u{FE0F}',
  'joy': '\u{1F602}',
  'open_mouth': '\u{1F62E}',
  'cry': '\u{1F622}',
  'tada': '\u{1F389}',
  'thumbsdown': '\u{1F44E}',
  '-1': '\u{1F44E}',
  'smile': '\u{1F604}',
  'laughing': '\u{1F606}',
  'wink': '\u{1F609}',
  'grinning': '\u{1F600}',
  'thinking': '\u{1F914}',
  'fire': '\u{1F525}',
  'rocket': '\u{1F680}',
  'eyes': '\u{1F440}',
  'raised_hands': '\u{1F64C}',
  'clap': '\u{1F44F}',
  'ok_hand': '\u{1F44C}',
  'pray': '\u{1F64F}',
  'muscle': '\u{1F4AA}',
  'sunglasses': '\u{1F60E}',
  'wave': '\u{1F44B}',
  'white_check_mark': '\u{2705}',
  'x': '\u{274C}',
  '100': '\u{1F4AF}',
};

String emojiFromName(String name) => kEmojiMap[name] ?? ':$name:';

// Quick reaction options
const List<Map<String, String>> kQuickReactions = [
  {'name': 'thumbsup', 'emoji': '\u{1F44D}'},
  {'name': 'heart', 'emoji': '\u{2764}\u{FE0F}'},
  {'name': 'joy', 'emoji': '\u{1F602}'},
  {'name': 'open_mouth', 'emoji': '\u{1F62E}'},
  {'name': 'cry', 'emoji': '\u{1F622}'},
  {'name': 'tada', 'emoji': '\u{1F389}'},
];

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

  // Edit mode
  String? _editingPostId;
  // Typing
  Timer? _typingDebounce;
  final Set<String> _typingUserIds = {};
  final Map<String, Timer> _typingTimers = {};
  // File upload
  bool _isUploading = false;
  List<String> _pendingFileIds = [];
  // Phase 8: Expanded actions, sticker picker, voice recording
  bool _showExpandedActions = false;
  bool _showStickerPicker = false;
  bool _isVoiceRecording = false;

  // Reply state
  MessageModel? _replyingTo;
  String? _replyingSenderName;

  // Unread separator state
  int? _lastViewedAt;
  int? _unreadSeparatorIndex;
  bool _separatorVisible = false;
  final GlobalKey _separatorKey = GlobalKey();

  // UX polish: drag overlay, last seen, read receipts
  bool _isDragOver = false;
  String? _lastSeenText;
  int? _otherUserLastViewedAt; // epoch ms when the other user last viewed this channel
  int _memberCount = 0;
  bool _isDmChannel = false;

  late final IChatRepository _chatRepo;

  // User statuses cache (userId -> status string: online/away/dnd/offline)
  final Map<String, String> _userStatuses = {};

  @override
  void initState() {
    super.initState();
    _chatRepo = getIt<IChatRepository>();
    _loadMessages();
    _listenToWsEvents();
    _scrollController.addListener(_onScroll);
    _fetchLastViewedAt();
    // Set active channel to suppress notifications for it
    try {
      context.read<ChatSessionCubit>().setActiveChannel(widget.channelId);
    } catch (_) {}
    // Web: drag & drop and paste
    if (kIsWeb) {
      setupWebDragDrop(
        onDrop: _handleWebFileDrop,
        onDragOver: (over) { if (mounted) setState(() => _isDragOver = over); },
      );
      setupWebPasteHandler(onPaste: _handleWebFileDrop);
    }
    // Fetch last seen / member count
    _fetchLastSeen();
  }

  @override
  void dispose() {
    // Clear active channel so notifications resume
    try {
      context.read<ChatSessionCubit>().setActiveChannel(null);
    } catch (_) {}
    _messageController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    _typingDebounce?.cancel();
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    if (kIsWeb) {
      teardownWebDragDrop();
      teardownWebPasteHandler();
    }
    super.dispose();
  }

  void _listenToWsEvents() {
    _wsSubscription = _chatRepo.wsEvents.listen((event) {
      final eventType = event['event'] as String?;
      final data = event['data'] as Map<String, dynamic>? ?? {};
      final broadcast = event['broadcast'] as Map<String, dynamic>? ?? {};

      switch (eventType) {
        case 'posted':
          _handleNewPost(data);
        case 'post_edited':
          _handleEditedPost(data);
        case 'post_deleted':
          _handleDeletedPost(data);
        case 'reaction_added':
        case 'reaction_removed':
          _handleReactionChange(data);
        case 'typing':
          _handleTypingEvent(data, broadcast);
        case 'channel_viewed':
          _handleChannelViewed(data, broadcast);
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
        // Deduplicate: own messages arrive via REST response + WS event
        if (_messages.any((m) => m.id == msg.id)) return;
        if (mounted) {
          setState(() => _messages.insert(0, msg));
          // Auto-scroll to bottom if user is near the bottom (reverse list: 0 = bottom)
          if (_scrollController.hasClients &&
              _scrollController.position.pixels < 150) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            });
          }
          // Mark channel as read since we are viewing it
          _chatRepo.markChannelAsRead(widget.channelId);
        }
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

  void _handleReactionChange(Map<String, dynamic> data) {
    final reactionStr = data['reaction'] as String?;
    if (reactionStr == null) return;
    try {
      final reactionJson = jsonDecode(reactionStr) as Map<String, dynamic>;
      final postId = reactionJson['post_id'] as String?;
      if (postId == null) return;
      _refreshSinglePost(postId);
    } catch (_) {}
  }

  Future<void> _refreshSinglePost(String postId) async {
    try {
      final freshMessages = await _chatRepo.getChannelMessages(widget.channelId, 0);
      final fresh = freshMessages.where((m) => m.id == postId).firstOrNull;
      if (fresh != null && mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == postId);
          if (idx != -1) _messages[idx] = fresh;
        });
      }
    } catch (_) {}
  }

  void _handleTypingEvent(Map<String, dynamic> data, Map<String, dynamic> broadcast) {
    final channelId = broadcast['channel_id'] as String?;
    if (channelId != widget.channelId) return;
    final userId = data['user_id'] as String?;
    if (userId == null || userId == _chatRepo.currentUserId) return;

    if (mounted) {
      setState(() => _typingUserIds.add(userId));
    }

    _typingTimers[userId]?.cancel();
    _typingTimers[userId] = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _typingUserIds.remove(userId));
      }
      _typingTimers.remove(userId);
    });
  }

  void _handleChannelViewed(Map<String, dynamic> data, Map<String, dynamic> broadcast) {
    final channelId = data['channel_id'] as String? ?? broadcast['channel_id'] as String?;
    if (channelId != widget.channelId) return;
    // The other user viewed this channel -- mark all messages as read
    if (mounted) {
      setState(() {
        _otherUserLastViewedAt = DateTime.now().millisecondsSinceEpoch;
      });
    }
  }

  Future<void> _fetchLastSeen() async {
    try {
      // Determine if DM by checking channel name format (userId1__userId2)
      // We need channel info -- approximate by checking members from messages
      // For simplicity, use the channel name passed in; DMs have format "userid__userid"
      // We can check via the statuses we already fetch
      // Wait for first messages to load, then check
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final otherUserIds = _messages
          .map((m) => m.userId)
          .where((id) => id != _chatRepo.currentUserId && id.isNotEmpty)
          .toSet()
          .toList();

      if (otherUserIds.isEmpty) return;

      // Heuristic: if only 1 other user in messages, treat as DM
      if (otherUserIds.length == 1) {
        _isDmChannel = true;
        _memberCount = 2;
        // Fetch last_activity_at for last seen
        try {
          final userDetails = await _chatRepo.getUserDetails(otherUserIds.first);
          final lastActivity = userDetails['last_activity_at'] as int? ?? 0;
          final status = _userStatuses[otherUserIds.first] ?? 'offline';
          if (mounted) {
            setState(() {
              if (status == 'online') {
                _lastSeenText = 'online';
              } else if (lastActivity > 0) {
                _lastSeenText = _formatLastSeen(DateTime.fromMillisecondsSinceEpoch(lastActivity));
              }
            });
          }
        } catch (_) {}
      } else {
        if (mounted) {
          setState(() {
            _isDmChannel = false;
            _memberCount = otherUserIds.length + 1;
          });
        }
      }
    } catch (_) {}
  }

  static String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inSeconds < 60) return 'last seen just now';
    if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'last seen yesterday';
    return 'last seen ${diff.inDays}d ago';
  }

  void _handleWebFileDrop(Uint8List bytes, String fileName) async {
    if (!mounted) return;
    setState(() => _isUploading = true);
    try {
      final fileIds = await _chatRepo.uploadFileBytes(widget.channelId, bytes.toList(), fileName);
      if (mounted) {
        setState(() {
          _pendingFileIds.addAll(fileIds);
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _fetchLastViewedAt() async {
    try {
      final memberData = await _chatRepo.getChannelMember(widget.channelId);
      final lva = memberData['last_viewed_at'] as int? ?? 0;
      if (mounted && lva > 0) {
        setState(() => _lastViewedAt = lva);
        _computeSeparator();
      }
    } catch (_) {}
    // Mark as read AFTER capturing last_viewed_at
    _chatRepo.markChannelAsRead(widget.channelId);
  }

  void _computeSeparator() {
    if (_lastViewedAt == null || _messages.isEmpty) return;
    final idx = computeUnreadSeparatorIndex(_messages, _lastViewedAt);
    if (idx != null && mounted) {
      setState(() {
        _unreadSeparatorIndex = idx;
        _separatorVisible = true;
      });
      // Auto-scroll to separator after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients && _unreadSeparatorIndex != null) {
          final targetIndex = _unreadSeparatorIndex! + 1;
          final approxOffset = targetIndex * 72.0;
          if (approxOffset > 200) {
            _scrollController.animateTo(
              approxOffset - 100,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        }
      });
      // Clear separator visibility after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _separatorVisible = false);
        }
      });
    }
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
      // Compute separator after first load
      if (_page == 1) {
        _computeSeparator();
      }
      // Fetch user statuses for loaded messages
      _fetchUserStatuses(messages);
    }
  }

  Future<void> _fetchUserStatuses(List<MessageModel> messages) async {
    final userIds = messages.map((m) => m.userId).toSet().toList();
    userIds.removeWhere((id) => _userStatuses.containsKey(id));
    if (userIds.isEmpty) return;
    try {
      final statuses = await _chatRepo.getUserStatuses(userIds);
      if (mounted) {
        setState(() => _userStatuses.addAll(statuses));
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMessages();
    }
  }

  static Color _onlineStatusColor(String status) {
    switch (status) {
      case 'online': return const Color(0xFF4CAF50);
      case 'away': return const Color(0xFFFFC107);
      case 'dnd': return const Color(0xFFF44336);
      default: return const Color(0xFF9E9E9E);
    }
  }

  void _onTextChanged(String text) {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 300), () {
      if (text.isNotEmpty) {
        _chatRepo.sendTyping(widget.channelId);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingFileIds.isEmpty) return;

    final editId = _editingPostId;
    _messageController.clear();

    if (editId != null) {
      // Edit mode
      setState(() => _editingPostId = null);
      try {
        await _chatRepo.updateMessage(editId, text);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to edit message: $e')),
          );
        }
      }
    } else {
      // New message, possibly with files and/or reply
      final fileIds = _pendingFileIds.isNotEmpty ? List<String>.from(_pendingFileIds) : null;
      final rootId = _replyingTo?.id;
      setState(() {
        _pendingFileIds = [];
        _replyingTo = null;
        _replyingSenderName = null;
      });
      try {
        await _chatRepo.sendMessage(widget.channelId, text, rootId: rootId, fileIds: fileIds);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message: $e')),
          );
        }
      }
    }
  }

  void _startEdit(MessageModel msg) {
    setState(() {
      _editingPostId = msg.id;
      _messageController.text = msg.message;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingPostId = null;
      _messageController.clear();
    });
  }

  void _startReply(MessageModel msg, String senderName) {
    setState(() {
      _replyingTo = msg;
      _replyingSenderName = senderName;
      _editingPostId = null;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyingSenderName = null;
    });
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final path = file.path;
      if (path == null) return;

      setState(() => _isUploading = true);
      try {
        final fileIds = await _chatRepo.uploadFile(widget.channelId, path, file.name);
        if (mounted) {
          setState(() {
            _pendingFileIds.addAll(fileIds);
            _isUploading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(MessageModel msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _chatRepo.deleteMessage(msg.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Future<void> _addReaction(String postId, String emojiName) async {
    try {
      await _chatRepo.addReaction(postId, emojiName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reaction failed: $e')),
        );
      }
    }
  }

  Future<void> _removeReaction(String postId, String emojiName) async {
    try {
      await _chatRepo.removeReaction(postId, emojiName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remove reaction failed: $e')),
        );
      }
    }
  }

  Future<void> _pinMessage(MessageModel msg) async {
    try {
      await _chatRepo.pinMessage(msg.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message pinned'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pin: $e')),
        );
      }
    }
  }

  void _showPinnedMessages() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
        builder: (ctx, scrollController) => _PinnedMessagesSheet(
          channelId: widget.channelId, chatRepo: _chatRepo, scrollController: scrollController),
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start >= 0 ? selection.start : text.length,
      selection.end >= 0 ? selection.end : text.length,
      emoji,
    );
    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(
      offset: (selection.start >= 0 ? selection.start : text.length) + emoji.length,
    );
    setState(() => _showStickerPicker = false);
  }

  void _sendSticker(String sticker) {
    _chatRepo.sendMessage(widget.channelId, sticker);
    setState(() => _showStickerPicker = false);
  }

  void _showMessageActions(MessageModel msg) {
    final isOwn = msg.userId == _chatRepo.currentUserId;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: customGreyColor400, borderRadius: BorderRadius.circular(2)),
            ),
            // Quick reaction bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: kQuickReactions.map((r) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _addReaction(msg.id, r['name']!);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(r['emoji']!, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // Copy
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg.message));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                );
              },
            ),
            // Reply (quote)
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                _startReply(msg, '');
              },
            ),
            // Reply in thread
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Reply in thread'),
              onTap: () {
                Navigator.pop(ctx);
                _openThread(msg);
              },
            ),
            // Forward
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(ctx);
                _forwardMessage(msg);
              },
            ),
            // Save / Bookmark
            BlocBuilder<SavedMessagesCubit, SavedMessagesState>(
              builder: (bCtx, savedState) {
                final isSaved = bCtx.read<SavedMessagesCubit>().isSaved(msg.id);
                return ListTile(
                  leading: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                  title: Text(isSaved ? 'Unsave' : 'Save'),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isSaved) {
                      context.read<SavedMessagesCubit>().unsaveMessage(msg.id);
                    } else {
                      context.read<SavedMessagesCubit>().saveMessage(
                        SavedMessageEntry(
                          messageId: msg.id,
                          channelId: widget.channelId,
                          channelName: widget.channelName,
                          messageText: msg.message,
                          savedAt: DateTime.now(),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message saved'), duration: Duration(seconds: 1)),
                      );
                    }
                  },
                );
              },
            ),
            // Pin message
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('Pin Message'),
              onTap: () {
                Navigator.pop(ctx);
                _pinMessage(msg);
              },
            ),
            if (isOwn) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _startEdit(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: errorColor),
                title: const Text('Delete', style: TextStyle(color: errorColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(msg);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }



  Future<void> _forwardMessage(MessageModel msg) async {
    final channels = await _chatRepo.getChannelList();
    if (!mounted) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _ForwardPickerDialog(channels: channels),
    );
    if (selected == null) return;

    final targetChannelId = selected['id'] as String? ?? '';
    if (targetChannelId.isEmpty) return;

    try {
      final senderName = msg.userId; // userId as fallback
      final forwardText = 'Forwarded from $senderName:\n${msg.message}';
      await _chatRepo.sendMessage(targetChannelId, forwardText);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message forwarded'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Forward failed: $e')),
        );
      }
    }
  }

  void _createPoll() async {
    setState(() => _showExpandedActions = false);
    final pollMsg = await showDialog<String>(
      context: context,
      builder: (ctx) => const CreatePollDialog(),
    );
    if (pollMsg != null && pollMsg.isNotEmpty) {
      await _chatRepo.sendMessage(widget.channelId, pollMsg);
    }
  }

  void _shareContact() async {
    setState(() => _showExpandedActions = false);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _ShareContactDialog(),
    );
    if (result != null && result.isNotEmpty) {
      await _chatRepo.sendMessage(widget.channelId, result);
    }
  }

  void _shareLocation() async {
    setState(() => _showExpandedActions = false);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _ShareLocationDialog(),
    );
    if (result != null && result.isNotEmpty) {
      await _chatRepo.sendMessage(widget.channelId, result);
    }
  }

  void _openThread(MessageModel rootMsg) {
    final rootId = rootMsg.isReply ? rootMsg.rootId : rootMsg.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => _ThreadView(
          rootPostId: rootId,
          channelId: widget.channelId,
          chatRepo: _chatRepo,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(widget.channelName.isNotEmpty ? widget.channelName : 'Chat', overflow: TextOverflow.ellipsis)),
                if (_userStatuses.isNotEmpty)
                  Builder(builder: (context) {
                    final otherStatuses = _userStatuses.entries
                        .where((e) => e.key != _chatRepo.currentUserId);
                    if (otherStatuses.isEmpty) return const SizedBox.shrink();
                    final status = otherStatuses.first.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _onlineStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
              ],
            ),
            // Last seen or member count subtitle
            if (_lastSeenText != null)
              Text(
                _lastSeenText!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: _lastSeenText == 'online'
                      ? const Color(0xFF4CAF50)
                      : customGreyColor500,
                ),
              )
            else if (!_isDmChannel && _memberCount > 0)
              Text(
                '$_memberCount members',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: customGreyColor500),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, size: 22),
            tooltip: 'Audio call',
            onPressed: () {
              context.read<CallCubit>().initiateCall(widget.channelId);
              context.push(RouterEnum.callView.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, size: 22),
            tooltip: 'Video call',
            onPressed: () {
              context.read<CallCubit>().initiateCall(
                    widget.channelId,
                    isVideo: true,
                  );
              context.push(RouterEnum.callView.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.push_pin_outlined, size: 20),
            tooltip: 'Pinned messages',
            onPressed: _showPinnedMessages,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            tooltip: 'Channel info',
            onPressed: () {
              final encodedName = Uri.encodeComponent(widget.channelName);
              context.push(
                '${RouterEnum.channelInfoView.routeName}?channelId=${widget.channelId}&channelName=$encodedName',
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
        children: [
          // Disappearing messages banner
          DisappearingMessagesBanner(channelId: widget.channelId),
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length + (_hasMore ? 1 : 0) + (_separatorVisible && _unreadSeparatorIndex != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Determine if separator should be inserted
                      final sepIdx = (_separatorVisible && _unreadSeparatorIndex != null)
                          ? _unreadSeparatorIndex! + 1
                          : -1;
                      final totalItems = _messages.length + (sepIdx >= 0 ? 1 : 0);

                      // Loading indicator at the end
                      if (_hasMore && index == totalItems) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      // Unread separator
                      if (sepIdx >= 0 && index == sepIdx) {
                        return UnreadSeparator(key: _separatorKey);
                      }

                      // Adjust index for messages after separator
                      final msgIndex = (sepIdx >= 0 && index > sepIdx) ? index - 1 : index;
                      if (msgIndex >= _messages.length) return const SizedBox.shrink();

                      final msg = _messages[msgIndex];
                      // Find quoted text for replies
                      String? quotedText;
                      if (msg.isReply) {
                        final parent = _messages.where((m) => m.id == msg.rootId).firstOrNull;
                        quotedText = parent?.message;
                      }
                      final isNewest = msgIndex == 0;
                      // Disappearing messages: check expiry
                      final _dmCubit = context.read<DisappearingMessagesCubit>();
                      final _dmOn = _dmCubit.isEnabled(widget.channelId);
                      final _dmExpiring = _dmOn && _dmCubit.service.isExpiringSoon(widget.channelId, msg.createAt);
                      final _dmExpiryText = _dmOn ? _dmCubit.service.formatRemainingTime(widget.channelId, msg.createAt) : null;

                      return DisappearingMessageWrapper(
                        expiringSoon: _dmExpiring,
                        child: _AnimatedMessageWrapper(
                          key: ValueKey(msg.id),
                          animate: isNewest,
                          child: Column(
                            crossAxisAlignment: msg.userId == _chatRepo.currentUserId
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              _RichMessageBubble(
                                message: msg,
                                isOwn: msg.userId == _chatRepo.currentUserId,
                                currentUserId: _chatRepo.currentUserId ?? '',
                                authToken: _chatRepo.authToken,
                                userStatus: _userStatuses[msg.userId],
                                otherUserLastViewedAt: _otherUserLastViewedAt,
                                onLongPress: () => _showMessageActions(msg),
                                onReactionTap: (emojiName, hasOwn) {
                                  if (hasOwn) {
                                    _removeReaction(msg.id, emojiName);
                                  } else {
                                    _addReaction(msg.id, emojiName);
                                  }
                                },
                                onThreadTap: () => _openThread(msg),
                                getFileUrl: _chatRepo.getFileUrl,
                                getFileThumbnailUrl: _chatRepo.getFileThumbnailUrl,
                                getProfileImageUrl: _chatRepo.getProfileImageUrl,
                                quotedText: quotedText,
                                onQuotedTap: msg.isReply ? () => _openThread(msg) : null,
                              ),
                              if (_dmOn && _dmExpiryText != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: DisappearingTimerIcon(
                                    expiryText: _dmExpiryText,
                                    expiringSoon: _dmExpiring,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Typing indicator
          if (_typingUserIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Text(
                _typingUserIds.length == 1
                    ? 'Someone is typing...'
                    : '${_typingUserIds.length} people are typing...',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: customGreyColor500,
                ),
              ),
            ),
          // Reply banner
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: inumSecondary.withAlpha(30),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: inumSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${_replyingSenderName?.isNotEmpty == true ? _replyingSenderName! : "message"}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: inumSecondary),
                        ),
                        Text(
                          _replyingTo!.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: customGreyColor600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, size: 18, color: customGreyColor600),
                  ),
                ],
              ),
            ),
          // Edit banner
          if (_editingPostId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: inumSecondary.withAlpha(30),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: inumSecondary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Editing message', style: TextStyle(fontSize: 13, color: inumSecondary)),
                  ),
                  GestureDetector(
                    onTap: _cancelEdit,
                    child: const Icon(Icons.close, size: 18, color: customGreyColor600),
                  ),
                ],
              ),
            ),
          // Pending files indicator
          if (_pendingFileIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: inumPrimary.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 16, color: inumPrimary),
                  const SizedBox(width: 8),
                  Text('${_pendingFileIds.length} file(s) attached',
                      style: const TextStyle(fontSize: 13, color: inumPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _pendingFileIds.clear()),
                    child: const Icon(Icons.close, size: 18, color: customGreyColor600),
                  ),
                ],
              ),
            ),
          // Sticker picker panel
          if (_showStickerPicker)
            StickerPicker(
              onEmojiSelected: _insertEmoji,
              onStickerSelected: _sendSticker,
              onClose: () => setState(() => _showStickerPicker = false),
            ),
          // Expanded action buttons
          if (_showExpandedActions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: customGreyColor200)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(icon: Icons.camera_alt, label: 'Camera', onTap: () { setState(() => _showExpandedActions = false); _pickAndUploadFile(); }),
                  _ActionButton(icon: Icons.photo_library, label: 'Gallery', onTap: () { setState(() => _showExpandedActions = false); _pickAndUploadFile(); }),
                  _ActionButton(icon: Icons.insert_drive_file, label: 'File', onTap: () { setState(() => _showExpandedActions = false); _pickAndUploadFile(); }),
                  _ActionButton(icon: Icons.mic, label: 'Voice', onTap: () { setState(() { _showExpandedActions = false; _isVoiceRecording = true; }); }),
                  _ActionButton(icon: Icons.emoji_emotions, label: 'Sticker', onTap: () { setState(() { _showExpandedActions = false; _showStickerPicker = !_showStickerPicker; }); }),
                  _ActionButton(icon: Icons.poll, label: 'Poll', onTap: _createPoll),
                  _ActionButton(icon: Icons.contact_page, label: 'Contact', onTap: _shareContact),
                  _ActionButton(icon: Icons.location_on, label: 'Location', onTap: _shareLocation),
                ],
              ),
              ),
            ),
          // Message input
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
              left: 8, right: 4, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: _isVoiceRecording
                ? Row(children: [
                    Expanded(
                      child: VoiceMessageRecorder(
                        onRecordingComplete: (path, duration) {
                          setState(() => _isVoiceRecording = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Voice message recorded (upload pending)'), duration: Duration(seconds: 2)),
                          );
                        },
                        onCancel: () => setState(() => _isVoiceRecording = false),
                      ),
                    ),
                    IconButton(onPressed: () => setState(() => _isVoiceRecording = false),
                      icon: const Icon(Icons.close), color: errorColor),
                  ])
                : Row(
                    children: [
                      // Expand actions button
                      IconButton(
                        onPressed: () => setState(() { _showExpandedActions = !_showExpandedActions; _showStickerPicker = false; }),
                        icon: AnimatedRotation(
                          turns: _showExpandedActions ? 0.125 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.add_circle_outline),
                        ),
                        color: inumPrimary,
                        iconSize: 24,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onChanged: _onTextChanged,
                          onTap: () { if (_showExpandedActions) setState(() => _showExpandedActions = false); },
                          decoration: InputDecoration(
                            hintText: _editingPostId != null ? 'Edit message...' : 'Type a message...',
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
                      // Emoji quick toggle
                      IconButton(
                        onPressed: () => setState(() { _showStickerPicker = !_showStickerPicker; _showExpandedActions = false; }),
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        color: customGreyColor600,
                        iconSize: 22,
                      ),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(_editingPostId != null ? Icons.check : Icons.send),
                        color: inumPrimary,
                      ),
                    ],
                  ),
          ),
        ],
      ),
          // Drag overlay
          if (_isDragOver)
            Positioned.fill(
              child: Container(
                color: inumPrimary.withAlpha(40),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 12)],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 48, color: inumPrimary),
                        SizedBox(height: 8),
                        Text('Drop file here', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: inumPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Animated Message Wrapper ---

class _AnimatedMessageWrapper extends StatefulWidget {
  final Widget child;
  final bool animate;

  const _AnimatedMessageWrapper({
    super.key,
    required this.child,
    this.animate = false,
  });

  @override
  State<_AnimatedMessageWrapper> createState() => _AnimatedMessageWrapperState();
}

class _AnimatedMessageWrapperState extends State<_AnimatedMessageWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

// --- Rich Message Bubble ---

class _RichMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwn;
  final String currentUserId;
  final String? authToken;
  final String? userStatus;
  final int? otherUserLastViewedAt;
  final VoidCallback onLongPress;
  final void Function(String emojiName, bool hasOwn) onReactionTap;
  final VoidCallback onThreadTap;
  final String Function(String) getFileUrl;
  final String Function(String) getFileThumbnailUrl;
  final String Function(String) getProfileImageUrl;
  final VoidCallback? onQuotedTap;
  final String? quotedText;

  const _RichMessageBubble({
    required this.message,
    required this.isOwn,
    required this.currentUserId,
    this.authToken,
    this.userStatus,
    this.otherUserLastViewedAt,
    required this.onLongPress,
    required this.onReactionTap,
    required this.onThreadTap,
    required this.getFileUrl,
    required this.getFileThumbnailUrl,
    required this.getProfileImageUrl,
    this.onQuotedTap,
    this.quotedText,
  });

  static Color _statusColor(String status) {
    switch (status) {
      case "online": return const Color(0xFF4CAF50);
      case "away": return const Color(0xFFFFC107);
      case "dnd": return const Color(0xFFF44336);
      default: return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(150),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isOwn ? inumPrimary : isDark ? darkCard : const Color(0xFFF0F2F5);
    final textColor = isOwn ? white : isDark ? white : black;
    final timeColor = isOwn ? white.withAlpha(180) : customGreyColor500;
    final timeStr = DateFormat.jm().format(message.createAt);

    return GestureDetector(
      onLongPress: onLongPress,
      onSecondaryTapUp: (_) => onLongPress(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isOwn) ...[
                  Stack(
                    children: [
                      UserAvatar(
                        imageUrl: getProfileImageUrl(message.userId),
                        name: message.userId,
                        radius: 16,
                        authToken: authToken,
                      ),
                      if (userStatus != null)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: _statusColor(userStatus!),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isOwn ? 18 : 4),
                        bottomRight: Radius.circular(isOwn ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message text
                        if (message.message.isNotEmpty)
                          _buildMessageText(context, textColor),
                        // File attachments
                        if (message.fileIds.isNotEmpty) ...[
                          if (message.message.isNotEmpty) const SizedBox(height: 8),
                          _buildFileAttachments(context),
                        ],
                        // Link previews
                        ..._buildLinkPreviews(context),
                        // Time + edited indicator + delivery ticks
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.isEdited)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text('(edited)', style: TextStyle(fontSize: 10, color: timeColor, fontStyle: FontStyle.italic)),
                              ),
                            Text(timeStr, style: TextStyle(fontSize: 11, color: timeColor)),
                            if (isOwn) ...[
                              const SizedBox(width: 4),
                              _DeliveryTick(
                                messageCreateAt: message.createAt.millisecondsSinceEpoch,
                                otherUserLastViewedAt: otherUserLastViewedAt,
                                isOwn: isOwn,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOwn) const SizedBox(width: 8),
              ],
            ),
            // Reaction chips
            if (message.reactions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: isOwn ? 0 : 40,
                  right: isOwn ? 8 : 0,
                  top: 4,
                ),
                child: _buildReactionChips(context),
              ),
            // Thread indicator
            if (message.hasReplies && !message.isReply)
              Padding(
                padding: EdgeInsets.only(
                  left: isOwn ? 0 : 40,
                  right: isOwn ? 8 : 0,
                  top: 2,
                ),
                child: GestureDetector(
                  onTap: onThreadTap,
                  child: Text(
                    '${message.replyCount} ${message.replyCount == 1 ? "reply" : "replies"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: inumSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageText(BuildContext context, Color textColor) {
    // Check for special message types
    // Poll
    final pollData = PollData.tryParse(message.message);
    if (pollData != null) {
      return PollWidget(
        poll: pollData,
        reactionGroups: message.reactionGroups,
        currentUserId: currentUserId,
        onVote: onReactionTap,
      );
    }

    // Contact card
    if (message.message.startsWith('\u{1F4C7} Contact:') || message.message.startsWith('\xf0\x9f\x93\x87 Contact:')) {
      return _buildContactCard(context, textColor);
    }

    // Location
    if (message.message.startsWith('\u{1F4CD} Location:') || message.message.startsWith('\xf0\x9f\x93\x8d Location:')) {
      return _buildLocationCard(context, textColor);
    }

    // Quoted reply preview
    Widget? quoteWidget;
    if (message.isReply && onQuotedTap != null) {
      quoteWidget = GestureDetector(
        onTap: onQuotedTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isOwn ? white : inumPrimary).withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: inumSecondary, width: 3)),
          ),
          child: Text(
            quotedText ?? 'Original message',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: textColor.withAlpha(160), fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // Use FormattedText for markdown support
    final formattedWidget = FormattedText(text: message.message, textColor: textColor);

    if (quoteWidget != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [quoteWidget, formattedWidget],
      );
    }
    return formattedWidget;
  }

  Widget _buildContactCard(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isOwn ? white : inumPrimary).withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.contact_page, color: isOwn ? white.withAlpha(200) : inumSecondary, size: 28),
          const SizedBox(width: 10),
          Flexible(child: Text(message.message, style: TextStyle(fontSize: 14, color: textColor))),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isOwn ? white : inumPrimary).withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: isOwn ? white.withAlpha(200) : errorColor, size: 28),
          const SizedBox(width: 10),
          Flexible(child: Text(message.message, style: TextStyle(fontSize: 14, color: textColor))),
        ],
      ),
    );
  }

  Widget _buildFileAttachments(BuildContext context) {
    return Column(
      children: message.fileIds.map((fileId) {
        final thumbUrl = getFileThumbnailUrl(fileId);
        final fileUrl = getFileUrl(fileId);

        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: GestureDetector(
            onTap: () => _showFullScreenImage(context, fileUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: thumbUrl,
                httpHeaders: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 200, height: 150,
                  color: customGreyColor300,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isOwn ? white : inumPrimary).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insert_drive_file, size: 24,
                          color: isOwn ? white.withAlpha(200) : inumPrimary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'File attachment',
                          style: TextStyle(
                            fontSize: 13,
                            color: isOwn ? white.withAlpha(200) : inumPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              httpHeaders: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
              placeholder: (_, __) => const CircularProgressIndicator(),
              errorWidget: (_, __, ___) => const Icon(Icons.error, color: white, size: 48),
            ),
          ),
        ),
      ),
    ));
  }

  List<Widget> _buildLinkPreviews(BuildContext context) {
    if (message.metadata == null) return [];
    final embeds = message.metadata!['embeds'] as List<dynamic>?;
    if (embeds == null || embeds.isEmpty) return [];

    final widgets = <Widget>[];
    for (final embed in embeds) {
      final embedMap = embed as Map<String, dynamic>?;
      if (embedMap == null) continue;
      final embedType = embedMap['type'] as String?;
      if (embedType != 'opengraph') continue;

      final ogData = embedMap['data'] as Map<String, dynamic>?;
      if (ogData == null) continue;

      final title = ogData['title'] as String?;
      final description = ogData['description'] as String?;
      final siteName = ogData['site_name'] as String?;

      if (title == null && description == null) continue;

      String? imageUrl;
      final images = ogData['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        final firstImg = images[0] as Map<String, dynamic>?;
        imageUrl = firstImg?['secure_url'] as String? ?? firstImg?['url'] as String?;
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isOwn ? white : inumPrimary).withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: inumSecondary, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (siteName != null)
                Text(siteName, style: TextStyle(fontSize: 11, color: isOwn ? white.withAlpha(160) : customGreyColor500)),
              if (title != null) ...[
                const SizedBox(height: 2),
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOwn ? white : inumPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 12, color: isOwn ? white.withAlpha(180) : customGreyColor600), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              if (imageUrl != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildReactionChips(BuildContext context) {
    final groups = message.reactionGroups;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: groups.entries.map((entry) {
        final hasOwn = entry.value.contains(currentUserId);
        return GestureDetector(
          onTap: () => onReactionTap(entry.key, hasOwn),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasOwn ? inumSecondary.withAlpha(40) : customGreyColor300.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
              border: hasOwn ? Border.all(color: inumSecondary, width: 1) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emojiFromName(entry.key), style: const TextStyle(fontSize: 14)),
                if (entry.value.length > 1) ...[
                  const SizedBox(width: 2),
                  Text('${entry.value.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- Thread View (Bottom Sheet) ---

class _ThreadView extends StatefulWidget {
  final String rootPostId;
  final String channelId;
  final IChatRepository chatRepo;
  final ScrollController scrollController;

  const _ThreadView({
    required this.rootPostId,
    required this.channelId,
    required this.chatRepo,
    required this.scrollController,
  });

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _replyController = TextEditingController();
  List<MessageModel> _threadMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    final messages = await widget.chatRepo.getThread(widget.rootPostId);
    if (mounted) {
      setState(() {
        _threadMessages = messages;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    _replyController.clear();
    try {
      await widget.chatRepo.sendMessage(widget.channelId, text, rootId: widget.rootPostId);
      await _loadThread();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Handle bar
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: customGreyColor400, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Thread', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_threadMessages.length} messages',
                  style: const TextStyle(fontSize: 13, color: customGreyColor500)),
            ],
          ),
        ),
        const Divider(height: 16),
        // Thread messages
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _threadMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _threadMessages[index];
                    final isRoot = index == 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRoot
                              ? (isDark ? darkCard : const Color(0xFFF0F2F5))
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                UserAvatar(
                                  imageUrl: widget.chatRepo.getProfileImageUrl(msg.userId),
                                  name: msg.userId,
                                  radius: 14,
                                  authToken: widget.chatRepo.authToken,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    msg.userId.length > 8 ? msg.userId.substring(0, 8) : msg.userId,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                                Text(
                                  DateFormat.jm().format(msg.createAt),
                                  style: const TextStyle(fontSize: 11, color: customGreyColor500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(msg.message, style: const TextStyle(fontSize: 14, height: 1.3)),
                            if (msg.isEdited)
                              const Text('(edited)', style: TextStyle(fontSize: 10, color: customGreyColor500, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Reply input
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(10), offset: const Offset(0, -1), blurRadius: 4),
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
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'Reply in thread...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendReply(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _sendReply,
                icon: const Icon(Icons.send),
                color: inumPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Delivery receipt tick widget ---

class _DeliveryTick extends StatelessWidget {
  final int messageCreateAt;
  final int? otherUserLastViewedAt;
  final bool isOwn;

  const _DeliveryTick({
    required this.messageCreateAt,
    this.otherUserLastViewedAt,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOwn) return const SizedBox.shrink();

    // Determine read status
    final isRead = otherUserLastViewedAt != null && otherUserLastViewedAt! >= messageCreateAt;

    // All sent messages have been delivered (we got 201 from API)
    // So we always show double tick; blue if read
    final tickColor = isRead ? const Color(0xFF2196F3) : (white.withAlpha(180));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_all, size: 14, color: tickColor),
      ],
    );
  }
}

// --- Phase 8: Action Button for expanded input ---

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: inumPrimary.withAlpha(20), shape: BoxShape.circle),
            child: Icon(icon, color: inumPrimary, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: customGreyColor600)),
        ],
      ),
    );
  }
}

// --- Phase 8: Pinned Messages Sheet ---

class _PinnedMessagesSheet extends StatefulWidget {
  final String channelId;
  final IChatRepository chatRepo;
  final ScrollController scrollController;

  const _PinnedMessagesSheet({required this.channelId, required this.chatRepo, required this.scrollController});

  @override
  State<_PinnedMessagesSheet> createState() => _PinnedMessagesSheetState();
}

class _PinnedMessagesSheetState extends State<_PinnedMessagesSheet> {
  List<MessageModel> _pinned = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPinned();
  }

  Future<void> _loadPinned() async {
    try {
      final msgs = await widget.chatRepo.getPinnedMessages(widget.channelId);
      if (mounted) setState(() { _pinned = msgs; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: customGreyColor400, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.push_pin, size: 20, color: inumPrimary),
            const SizedBox(width: 8),
            const Text('Pinned Messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${_pinned.length}', style: const TextStyle(fontSize: 13, color: customGreyColor500)),
          ]),
        ),
        const Divider(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pinned.isEmpty
                  ? const Center(child: Text('No pinned messages', style: TextStyle(color: customGreyColor500)))
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _pinned.length,
                      itemBuilder: (context, index) {
                        final msg = _pinned[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.push_pin, size: 18, color: inumSecondary),
                            title: Text(msg.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                            subtitle: Text(DateFormat.yMd().add_jm().format(msg.createAt),
                              style: const TextStyle(fontSize: 11, color: customGreyColor500)),
                          ),
                        );
                      }),
        ),
      ],
    );
  }
}


// --- Forward Message Picker ---

class _ForwardPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> channels;
  const _ForwardPickerDialog({required this.channels});

  @override
  State<_ForwardPickerDialog> createState() => _ForwardPickerDialogState();
}

class _ForwardPickerDialogState extends State<_ForwardPickerDialog> {
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.channels;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.channels;
      } else {
        _filtered = widget.channels.where((ch) {
          final name = (ch['display_name'] as String? ?? '').toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Forward to...'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search channels...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final ch = _filtered[index];
                  final name = ch['display_name'] as String? ?? ch['name'] as String? ?? '';
                  final type = ch['type'] as String? ?? '';
                  IconData icon;
                  switch (type) {
                    case 'D': icon = Icons.person; break;
                    case 'G': icon = Icons.group; break;
                    case 'P': icon = Icons.lock; break;
                    default: icon = Icons.tag; break;
                  }
                  return ListTile(
                    leading: Icon(icon, color: inumSecondary),
                    title: Text(name.isNotEmpty ? name : 'Channel'),
                    dense: true,
                    onTap: () => Navigator.pop(context, ch),
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

// --- Share Contact Dialog ---

class _ShareContactDialog extends StatefulWidget {
  @override
  State<_ShareContactDialog> createState() => _ShareContactDialogState();
}

class _ShareContactDialogState extends State<_ShareContactDialog> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username (optional)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final parts = <String>['\u{1F4C7} Contact: $name'];
            if (_usernameController.text.trim().isNotEmpty) {
              parts.add('Username: @${_usernameController.text.trim()}');
            }
            if (_emailController.text.trim().isNotEmpty) {
              parts.add('Email: ${_emailController.text.trim()}');
            }
            Navigator.pop(context, parts.join('\n'));
          },
          child: const Text('Share'),
        ),
      ],
    );
  }
}

// --- Share Location Dialog ---

class _ShareLocationDialog extends StatefulWidget {
  @override
  State<_ShareLocationDialog> createState() => _ShareLocationDialogState();
}

class _ShareLocationDialogState extends State<_ShareLocationDialog> {
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Location'),
      content: TextField(
        controller: _locationController,
        decoration: const InputDecoration(
          labelText: 'Address or coordinates',
          hintText: 'e.g. 51.5074, -0.1278',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final loc = _locationController.text.trim();
            if (loc.isEmpty) return;
            Navigator.pop(context, '\u{1F4CD} Location: $loc');
          },
          child: const Text('Share'),
        ),
      ],
    );
  }
}

