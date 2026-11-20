class LeaveBalanceModel {
  final int balance;

  const LeaveBalanceModel({required this.balance});

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(balance: (json['balance'] as num).toInt());
  }

  factory LeaveBalanceModel.fromMap(Map<String, dynamic> map) {
    return LeaveBalanceModel(balance: (map['balance'] as num).toInt());
  }

  Map<String, dynamic> toMap({required String employeeId}) {
    return {
      'employee_id': employeeId,
      'balance': balance,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
