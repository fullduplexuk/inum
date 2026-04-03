import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inum/domain/models/chat/message_model.dart';
import 'package:inum/presentation/design_system/colors.dart';
import 'package:inum/presentation/design_system/widgets/user_avatar.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwn;
  final String senderName;
  final String? senderAvatarUrl;
  final String? authToken;
  final bool showSenderInfo;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.senderName = '',
    this.senderAvatarUrl,
    this.authToken,
    this.showSenderInfo = true,
    this.onDelete,
  });

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

    final timeStr = DateFormat.jm().format(message.createAt);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isOwn ? inumPrimary : isDark ? darkCard : const Color(0xFFF0F2F5);
    final textColor = isOwn ? white : isDark ? white : black;
    final timeColor = isOwn ? white.withAlpha(180) : customGreyColor500;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isOwn && showSenderInfo) ...[
              UserAvatar(imageUrl: senderAvatarUrl, name: senderName, radius: 16, authToken: authToken),
              const SizedBox(width: 8),
            ],
            if (!isOwn && !showSenderInfo) const SizedBox(width: 40),
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
                    if (!isOwn && showSenderInfo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(senderName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: inumSecondary)),
                      ),
                    Text(message.message, style: TextStyle(fontSize: 15, color: textColor, height: 1.3)),
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.bottomRight, child: Text(timeStr, style: TextStyle(fontSize: 11, color: timeColor))),
                  ],
                ),
              ),
            ),
            if (isOwn) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: customGreyColor400, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.message));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)));
              },
            ),
            if (isOwn && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: errorColor),
                title: const Text('Delete', style: TextStyle(color: errorColor)),
                onTap: () { Navigator.pop(ctx); _confirmDelete(context); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(ctx); onDelete?.call(); }, child: const Text('Delete', style: TextStyle(color: errorColor))),
        ],
      ),
    );
  }
}
