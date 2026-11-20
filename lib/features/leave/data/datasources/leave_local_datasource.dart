import '../../../../core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';
import '../models/leave_request_model.dart';
import '../models/leave_balance_model.dart';

class LeaveLocalDataSource {
  Future<void> saveLeaveRequests(List<LeaveRequestModel> requests) async {
    final db = await AppDatabase.database;

    final batch = db.batch();

    for (final request in requests) {
      batch.insert(
        'leave_requests',
        request.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<LeaveRequestModel>> getLeaveRequests(String employeeId) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'leave_requests',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      orderBy: 'created_at DESC',
    );

    return result.map(LeaveRequestModel.fromMap).toList();
  }

  Future<void> saveLeaveRequest(LeaveRequestModel request) async {
    final db = await AppDatabase.database;

    await db.insert(
      'leave_requests',
      request.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveLeaveBalance({
    required String employeeId,
    required LeaveBalanceModel balance,
  }) async {
    final db = await AppDatabase.database;

    await db.insert(
      'leave_balance_cache',
      balance.toMap(employeeId: employeeId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LeaveBalanceModel?> getLeaveBalance(String employeeId) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'leave_balance_cache',
      where: 'employee_id = ?',
      whereArgs: [employeeId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return LeaveBalanceModel.fromMap(result.first);
  }
}
