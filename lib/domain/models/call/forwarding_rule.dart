import 'package:equatable/equatable.dart';

enum ForwardingCondition { always, busy, noAnswer, offline }

class ForwardingRule extends Equatable {
  final ForwardingCondition condition;
  final bool enabled;
  final String destination;
  final int delaySeconds;

  const ForwardingRule({
    required this.condition,
    this.enabled = false,
    this.destination = '',
    this.delaySeconds = 20,
  });

  ForwardingRule copyWith({
    ForwardingCondition? condition,
    bool? enabled,
    String? destination,
    int? delaySeconds,
  }) {
    return ForwardingRule(
      condition: condition ?? this.condition,
      enabled: enabled ?? this.enabled,
      destination: destination ?? this.destination,
      delaySeconds: delaySeconds ?? this.delaySeconds,
    );
  }

  Map<String, dynamic> toMap() => {
        'condition': condition.name,
        'enabled': enabled,
        'destination': destination,
        'delay_seconds': delaySeconds,
      };

  factory ForwardingRule.fromMap(Map<String, dynamic> map) {
    return ForwardingRule(
      condition: ForwardingCondition.values.firstWhere(
        (c) => c.name == (map['condition'] as String? ?? 'always'),
        orElse: () => ForwardingCondition.always,
      ),
      enabled: map['enabled'] as bool? ?? false,
      destination: map['destination'] as String? ?? '',
      delaySeconds: map['delay_seconds'] as int? ?? 20,
    );
  }

  String get conditionLabel => switch (condition) {
        ForwardingCondition.always => 'Always',
        ForwardingCondition.busy => 'When Busy',
        ForwardingCondition.noAnswer => 'When No Answer',
        ForwardingCondition.offline => 'When Offline',
      };

  @override
  List<Object?> get props => [condition, enabled, destination, delaySeconds];
}
