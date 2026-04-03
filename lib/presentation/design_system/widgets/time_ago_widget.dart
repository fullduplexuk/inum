import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:inum/presentation/design_system/colors.dart';

class TimeAgoWidget extends StatelessWidget {
  final DateTime dateTime;
  final TextStyle? style;

  const TimeAgoWidget({
    super.key,
    required this.dateTime,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      timeago.format(dateTime, locale: 'en_short'),
      style: style ??
          const TextStyle(
            fontSize: 12,
            color: customGreyColor600,
          ),
    );
  }
}
