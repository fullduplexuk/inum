import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inum/core/constants/enums/router_enum.dart';
import 'package:inum/presentation/blocs/saved/saved_messages_cubit.dart';
import 'package:inum/presentation/blocs/saved/saved_messages_state.dart';
import 'package:inum/presentation/design_system/colors.dart';

class SavedMessagesView extends StatelessWidget {
  const SavedMessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Messages'),
        centerTitle: false,
      ),
      body: BlocBuilder<SavedMessagesCubit, SavedMessagesState>(
        builder: (context, state) {
          if (state.savedMessages.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: customGreyColor400),
                  SizedBox(height: 16),
                  Text(
                    'No saved messages',
                    style: TextStyle(fontSize: 16, color: customGreyColor500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Long press a message and tap Save',
                    style: TextStyle(fontSize: 13, color: customGreyColor400),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: state.savedMessages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = state.savedMessages[index];
              return Dismissible(
                key: ValueKey(entry.messageId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: errorColor,
                  child: const Icon(Icons.delete, color: white),
                ),
                onDismissed: (_) {
                  context.read<SavedMessagesCubit>().unsaveMessage(entry.messageId);
                },
                child: ListTile(
                  leading: const Icon(Icons.bookmark, color: inumSecondary),
                  title: Text(
                    entry.messageText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${entry.channelName.isNotEmpty ? entry.channelName : 'Channel'}'
                    ' ${entry.senderName.isNotEmpty ? '- ${entry.senderName}' : ''}'
                    ' | ${DateFormat.yMd().add_jm().format(entry.savedAt)}',
                    style: const TextStyle(fontSize: 12, color: customGreyColor500),
                  ),
                  onTap: () {
                    if (entry.channelId.isNotEmpty) {
                      final name = Uri.encodeComponent(
                        entry.channelName.isNotEmpty ? entry.channelName : 'Chat',
                      );
                      context.push(
                        '${RouterEnum.chatView.routeName}?channelId=${entry.channelId}&channelName=$name',
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
