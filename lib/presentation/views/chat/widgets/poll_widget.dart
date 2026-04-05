import 'package:flutter/material.dart';
import 'package:inum/presentation/design_system/colors.dart';

/// Prefix used to detect a poll message.
const String kPollPrefix = '[POLL]';

/// Number emojis used as reaction votes.
const List<String> kPollVoteEmojis = [
  '1\u{FE0F}\u{20E3}',
  '2\u{FE0F}\u{20E3}',
  '3\u{FE0F}\u{20E3}',
  '4\u{FE0F}\u{20E3}',
  '5\u{FE0F}\u{20E3}',
  '6\u{FE0F}\u{20E3}',
];

/// Mattermost emoji names used for voting reactions.
const List<String> kPollVoteEmojiNames = [
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
];

/// Parsed poll data from a message string.
class PollData {
  final String question;
  final List<String> options;

  const PollData({required this.question, required this.options});

  /// Try to parse a message that starts with [POLL].
  static PollData? tryParse(String message) {
    if (!message.startsWith(kPollPrefix)) return null;
    final lines = message.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 3) return null;

    String? question;
    final options = <String>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('Question:')) {
        question = line.substring('Question:'.length).trim();
      } else {
        final stripped = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        options.add(stripped);
      }
    }

    if (question == null || options.isEmpty) return null;
    return PollData(question: question, options: options);
  }
}

/// Renders a poll card.
class PollWidget extends StatelessWidget {
  final PollData poll;
  final Map<String, List<String>> reactionGroups;
  final String currentUserId;
  final void Function(String emojiName, bool hasOwn) onVote;

  const PollWidget({
    super.key,
    required this.poll,
    required this.reactionGroups,
    required this.currentUserId,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    int totalVotes = 0;
    for (var i = 0; i < poll.options.length && i < kPollVoteEmojiNames.length; i++) {
      totalVotes += (reactionGroups[kPollVoteEmojiNames[i]]?.length ?? 0);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inumSecondary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inumSecondary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll, color: inumSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < poll.options.length && i < kPollVoteEmojiNames.length; i++)
            _buildOptionRow(i, totalVotes),
          const SizedBox(height: 6),
          Text(
            '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: customGreyColor500),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(int index, int totalVotes) {
    final emojiName = kPollVoteEmojiNames[index];
    final voters = reactionGroups[emojiName] ?? [];
    final count = voters.length;
    final hasOwn = voters.contains(currentUserId);
    final fraction = totalVotes > 0 ? count / totalVotes : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => onVote(emojiName, hasOwn),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasOwn ? inumSecondary : customGreyColor300,
              width: hasOwn ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(kPollVoteEmojis[index], style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poll.options[index], style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 4,
                        backgroundColor: customGreyColor200,
                        valueColor: const AlwaysStoppedAnimation(inumSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$count', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for creating a new poll.
class CreatePollDialog extends StatefulWidget {
  const CreatePollDialog({super.key});

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 6) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  String? _buildPollMessage() {
    final question = _questionController.text.trim();
    if (question.isEmpty) return null;
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (options.length < 2) return null;

    final buffer = StringBuffer('$kPollPrefix\nQuestion: $question');
    for (var i = 0; i < options.length; i++) {
      buffer.write('\n${i + 1}. ${options[i]}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Poll'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'What should we do?',
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _optionControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Option ${i + 1}',
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: errorColor),
                        onPressed: () => _removeOption(i),
                      ),
                  ],
                ),
              ),
            if (_optionControllers.length < 6)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final msg = _buildPollMessage();
            if (msg != null) {
              Navigator.pop(context, msg);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
