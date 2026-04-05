import 'package:flutter/material.dart';

/// Parses markdown-like formatting and returns a styled [Text.rich] widget.
class FormattedText extends StatelessWidget {
  final String text;
  final Color textColor;
  final double fontSize;
  final double height;

  const FormattedText({
    super.key,
    required this.text,
    required this.textColor,
    this.fontSize = 15,
    this.height = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _parse(text)),
      style: TextStyle(fontSize: fontSize, color: textColor, height: height),
    );
  }

  List<InlineSpan> _parse(String input) {
    final spans = <InlineSpan>[];
    // Order matters: code block first, then bold, italic, strikethrough, inline code
    final regex = RegExp(
      r'```([\s\S]*?)```' // code block
      r'|'
      r'\*\*(.+?)\*\*' // bold
      r'|'
      r'~~(.+?)~~' // strikethrough
      r'|'
      r'\*(.+?)\*' // italic
      r'|'
      r'`([^`]+)`', // inline code
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(input)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: input.substring(lastEnd, match.start)));
      }

      if (match.group(1) != null) {
        // Code block
        spans.add(WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(40),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              match.group(1)!.trim(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize - 1,
                color: textColor,
              ),
            ),
          ),
        ));
      } else if (match.group(2) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(3) != null) {
        // Strikethrough
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ));
      } else if (match.group(4) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(5) != null) {
        // Inline code
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(40),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              match.group(5)!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize - 1,
                color: textColor,
              ),
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      spans.add(TextSpan(text: input.substring(lastEnd)));
    }

    return spans;
  }
}
