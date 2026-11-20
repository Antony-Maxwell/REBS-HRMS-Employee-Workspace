import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/employee_model.dart';

class DashboardLocalDataSource {
  Future<void> cacheEmployee(EmployeeModel employee) async {
    final db = await AppDatabase.database;

    await db.insert('employee_cache', {
      'id': employee.id,
      'data': jsonEncode(employee.toJson()),
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<EmployeeModel?> getCachedEmployee() async {
    final db = await AppDatabase.database;

    final result = await db.query('employee_cache', limit: 1);

    if (result.isEmpty) return null;

    final json =
        jsonDecode(result.first['data'] as String) as Map<String, dynamic>;

    return EmployeeModel.fromJson(json);
  }
}
