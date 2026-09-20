class ReminderModel {
  final String id;
  final String referenceId; // loan_id or transaction_id
  final String referenceType; // LOAN or TRANSACTION
  final String title;
  final String message;
  final DateTime scheduledTime;
  final int offsetDays;
  final String channel; // LOCAL_NOTIFICATION, ALARM, WHATSAPP
  final String status; // SCHEDULED, SENT, DISMISSED, CANCELLED
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.referenceId,
    required this.referenceType,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.offsetDays,
    this.channel = 'LOCAL_NOTIFICATION',
    this.status = 'SCHEDULED',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'title': title,
      'message': message,
      'scheduled_time': scheduledTime.toIso8601String(),
      'offset_days': offsetDays,
      'channel': channel,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as String,
      referenceId: map['reference_id'] as String,
      referenceType: map['reference_type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      offsetDays: map['offset_days'] as int,
      channel: map['channel'] as String? ?? 'LOCAL_NOTIFICATION',
      status: map['status'] as String? ?? 'SCHEDULED',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
