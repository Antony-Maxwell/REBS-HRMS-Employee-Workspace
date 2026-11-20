import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/attendance_event_model.dart';

class AttendanceLocalDataSource {
  Future<void> saveEvent(AttendanceEventModel event) async {
    final db = await AppDatabase.database;

    await db.insert(
      'attendance_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<AttendanceEventModel>> getAllEvents() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'attendance_events',
      orderBy: 'timestamp ASC, event_id ASC',
    );

    return result.map(AttendanceEventModel.fromMap).toList();
  }

  Future<List<AttendanceEventModel>> getPendingEvents() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'attendance_events',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC, event_id ASC',
    );

    return result.map(AttendanceEventModel.fromMap).toList();
  }

  Future<void> updateEventStatus({
    required String eventId,
    required SyncStatus status,
    String? error,
  }) async {
    final db = await AppDatabase.database;

    await db.update(
      'attendance_events',
      {'sync_status': status.name, 'last_error': error},
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  Future<void> incrementAttemptCount(String eventId) async {
    final db = await AppDatabase.database;

    await db.rawUpdate(
      '''
    UPDATE attendance_events
    SET attempt_count = attempt_count + 1
    WHERE event_id = ?
    ''',
      [eventId],
    );
  }
}
