import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inum/domain/models/sms/sms_model.dart';
import 'package:inum/presentation/blocs/sms/sms_cubit.dart';
import 'package:inum/presentation/blocs/sms/sms_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class SmsView extends StatefulWidget {
  final String phoneNumber;
  const SmsView({super.key, required this.phoneNumber});

  @override
  State<SmsView> createState() => _SmsViewState();
}

class _SmsViewState extends State<SmsView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SmsCubit>().loadConversation(widget.phoneNumber);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<SmsCubit>().sendSms(widget.phoneNumber, text);
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.phoneNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Text(
              'SMS',
              style: TextStyle(fontSize: 12, color: customGreyColor600),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Call',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${widget.phoneNumber}... (placeholder)'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<SmsCubit, SmsState>(
              builder: (context, state) {
                final messages = switch (state) {
                  SmsLoaded(:final messages) => messages,
                  SmsSending(:final messages) => messages,
                  SmsError(:final previousMessages) => previousMessages,
                  _ => <SmsModel>[],
                };

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sms_outlined,
                          size: 64,
                          color: customGreyColor400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            color: customGreyColor600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send an SMS to ${widget.phoneNumber}',
                          style: const TextStyle(
                            color: customGreyColor500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isSent = msg.fromNumber != widget.phoneNumber;
                    final showTimestamp = index == 0 ||
                        msg.sentAt
                                .difference(messages[index - 1].sentAt)
                                .inMinutes >
                            5;

                    return Column(
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _formatTimestamp(msg.sentAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: customGreyColor500,
                              ),
                            ),
                          ),
                        _MessageBubble(
                          message: msg.message,
                          isSent: isSent,
                          status: msg.status,
                          time: DateFormat.jm().format(msg.sentAt),
                          isDark: isDark,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Error banner
          BlocBuilder<SmsCubit, SmsState>(
            builder: (context, state) {
              if (state is SmsError) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  color: errorColor.withAlpha(30),
                  child: Text(
                    'Error: ${state.message}',
                    style: const TextStyle(
                      color: errorColor,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Message input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: isDark ? darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : customGreyColor300,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withAlpha(15)
                            : customGreyColor200,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<SmsCubit, SmsState>(
                    builder: (context, state) {
                      final isSending = state is SmsSending;
                      return GestureDetector(
                        onTap: isSending ? null : _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSending
                                ? customGreyColor400
                                : inumSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.EEEE().format(dt);
    return DateFormat.yMMMd().format(dt);
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isSent;
  final SmsStatus status;
  final String time;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isSent,
    required this.status,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isSent ? 64 : 0,
          right: isSent ? 0 : 64,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSent
              ? inumSecondary.withAlpha(40)
              : (isDark ? darkCard : customGreyColor200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isSent ? 16 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withAlpha(120)
                        : customGreyColor600,
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 4),
                  Icon(
                    status == SmsStatus.delivered
                        ? Icons.done_all
                        : status == SmsStatus.failed
                            ? Icons.error_outline
                            : Icons.done,
                    size: 14,
                    color: status == SmsStatus.delivered
                        ? inumSecondary
                        : status == SmsStatus.failed
                            ? errorColor
                            : customGreyColor500,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
