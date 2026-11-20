class LeaveRequestModel {
  final String id;
  final String employeeId;
  final String type;
  final String startDate;
  final String endDate;
  final int days;
  final String reason;
  final String status;
  final DateTime createdAt;

  const LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'].toString(),
      employeeId: json['employeeId']?.toString() ?? 'EMP001',
      type: json['type'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      days: (json['days'] as num).toInt(),
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) {
    return LeaveRequestModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      type: map['type'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      days: map['days'] as int,
      reason: map['reason'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'type': type,
      'start_date': startDate,
      'end_date': endDate,
      'days': days,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
    };
  }
}
