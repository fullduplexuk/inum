import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inum/presentation/design_system/colors.dart';

class CallSummaryView extends StatelessWidget {
  final String callId;
  final String? roomId;

  const CallSummaryView({
    super.key,
    required this.callId,
    this.roomId,
  });

  // Placeholder summary data - will be replaced by LLM-generated content
  Map<String, dynamic> get _placeholderSummary => {
        'title': 'Call Summary',
        'date': DateTime.now().toIso8601String(),
        'duration': '12m 34s',
        'participants': ['Alice', 'Bob'],
        'key_points': [
          'Discussed Q2 project timeline and milestones',
          'Reviewed budget allocation for new features',
          'Agreed on weekly sync meetings starting next Monday',
        ],
        'action_items': [
          {
            'assignee': 'Alice',
            'task': 'Prepare project timeline document',
            'due': 'Friday',
          },
          {
            'assignee': 'Bob',
            'task': 'Send budget proposal to finance team',
            'due': 'Wednesday',
          },
          {
            'assignee': 'Both',
            'task': 'Review and approve feature specifications',
            'due': 'Next Monday',
          },
        ],
        'decisions': [
          'Use weekly sprint cycles instead of bi-weekly',
          'Prioritize mobile app features over desktop',
          'Postpone internationalization to Q3',
        ],
      };

  void _copyToClipboard(BuildContext context) {
    final summary = _placeholderSummary;
    final buffer = StringBuffer();
    buffer.writeln('Call Summary');
    buffer.writeln(
        'Participants: ${(summary["participants"] as List).join(", ")}');
    buffer.writeln('Duration: ${summary["duration"]}');
    buffer.writeln('');
    buffer.writeln('Key Points:');
    for (final point in summary['key_points'] as List) {
      buffer.writeln('  - $point');
    }
    buffer.writeln('');
    buffer.writeln('Action Items:');
    for (final item in summary['action_items'] as List) {
      final m = item as Map<String, dynamic>;
      buffer.writeln(
          '  - [${m["assignee"]}] ${m["task"]} (due: ${m["due"]})');
    }
    buffer.writeln('');
    buffer.writeln('Decisions:');
    for (final d in summary['decisions'] as List) {
      buffer.writeln('  - $d');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _placeholderSummary;
    final keyPoints = summary['key_points'] as List;
    final actionItems = summary['action_items'] as List;
    final decisions = summary['decisions'] as List;
    final participants = summary['participants'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Summary'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy summary',
            onPressed: () => _copyToClipboard(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: inumSecondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI-Generated Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 16, color: customGreyColor600),
                      const SizedBox(width: 6),
                      Text(
                        participants.join(', '),
                        style: const TextStyle(
                          color: customGreyColor700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.timer_outlined,
                          size: 16, color: customGreyColor600),
                      const SizedBox(width: 4),
                      Text(
                        summary['duration'] as String,
                        style: const TextStyle(
                          color: customGreyColor700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Key Points
          const _SectionTitle(
            icon: Icons.lightbulb_outline,
            title: 'Key Points',
            color: Color(0xFFFF9800),
          ),
          const SizedBox(height: 8),
          ...keyPoints.map((point) => _BulletItem(
                text: point as String,
                icon: Icons.circle,
                iconSize: 6,
              )),
          const SizedBox(height: 20),

          // Action Items
          const _SectionTitle(
            icon: Icons.check_circle_outline,
            title: 'Action Items',
            color: successColor,
          ),
          const SizedBox(height: 8),
          ...actionItems.map((item) {
            final m = item as Map<String, dynamic>;
            return _ActionItem(
              assignee: m['assignee'] as String,
              task: m['task'] as String,
              due: m['due'] as String,
            );
          }),
          const SizedBox(height: 20),

          // Decisions
          const _SectionTitle(
            icon: Icons.gavel_outlined,
            title: 'Decisions',
            color: inumPrimary,
          ),
          const SizedBox(height: 8),
          ...decisions.map((d) => _BulletItem(
                text: d as String,
                icon: Icons.arrow_right,
                iconSize: 20,
              )),
          const SizedBox(height: 24),

          // Placeholder note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: inumSecondary.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: inumSecondary.withAlpha(40)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: inumSecondary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is placeholder content. AI summaries will be generated '
                    'from call transcripts when the Agents service is deployed.',
                    style: TextStyle(
                      fontSize: 12,
                      color: customGreyColor700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final double iconSize;

  const _BulletItem({
    required this.text,
    required this.icon,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, size: iconSize, color: customGreyColor600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String assignee;
  final String task;
  final String due;

  const _ActionItem({
    required this.assignee,
    required this.task,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: successColor.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: successColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: inumPrimary.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  assignee,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: inumPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Due: $due',
                style: const TextStyle(
                  fontSize: 11,
                  color: customGreyColor600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(task, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
