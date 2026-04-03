import 'package:equatable/equatable.dart';

enum SmsStatus { sent, delivered, failed }

class SmsModel extends Equatable {
  final String id;
  final String fromNumber;
  final String toNumber;
  final String message;
  final DateTime sentAt;
  final SmsStatus status;

  const SmsModel({
    required this.id,
    required this.fromNumber,
    required this.toNumber,
    required this.message,
    required this.sentAt,
    this.status = SmsStatus.sent,
  });

  SmsModel copyWith({
    String? id,
    String? fromNumber,
    String? toNumber,
    String? message,
    DateTime? sentAt,
    SmsStatus? status,
  }) {
    return SmsModel(
      id: id ?? this.id,
      fromNumber: fromNumber ?? this.fromNumber,
      toNumber: toNumber ?? this.toNumber,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'from_number': fromNumber,
        'to_number': toNumber,
        'message': message,
        'sent_at': sentAt.toIso8601String(),
        'status': status.name,
      };

  factory SmsModel.fromMap(Map<String, dynamic> map) {
    return SmsModel(
      id: map['id'] as String,
      fromNumber: map['from_number'] as String? ?? '',
      toNumber: map['to_number'] as String? ?? '',
      message: map['message'] as String? ?? '',
      sentAt: DateTime.parse(map['sent_at'] as String),
      status: SmsStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'sent'),
        orElse: () => SmsStatus.sent,
      ),
    );
  }

  @override
  List<Object?> get props => [id, fromNumber, toNumber, message, sentAt, status];
}
