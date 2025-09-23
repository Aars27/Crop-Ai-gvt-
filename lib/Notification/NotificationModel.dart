
class NotificationModel {
  final int id;
  final String stNo;
  final int userId;
  final String blockName;
  final String plotName;
  final String priority;
  final String notificationType;
  final String? roll;
  final String message;
  late final String status;
  final String createdAt;
  final String updatedAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.stNo,
    required this.userId,
    required this.blockName,
    required this.plotName,
    required this.priority,
    required this.notificationType,
    this.roll,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      stNo: json['st_no'],
      userId: json['user_id'],
      blockName: json['block_name'],
      plotName: json['plot_name'],
      priority: json['priority'],
      notificationType: json['notification_type'],
      roll: json['roll'],
      message: json['message'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
