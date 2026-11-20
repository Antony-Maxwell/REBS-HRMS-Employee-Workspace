import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();

    _database = await openDatabase(
      join(dbPath, 'rebs_hrms.db'),
      version: 3,

      onCreate: (db, version) async {
        await _createEmployeeTable(db);
        await _createAttendanceTable(db);
        await _createLeaveTables(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createAttendanceTable(db);
        }

        if (oldVersion < 3) {
          await _createLeaveTables(db);
        }
      },
    );

    return _database!;
  }

  static Future<void> _createEmployeeTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS employee_cache (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createAttendanceTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance_events (
        event_id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        sync_status TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_attendance_sync_order
      ON attendance_events(sync_status, timestamp)
    ''');
  }

  static Future<void> _createLeaveTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS leave_requests (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        days INTEGER NOT NULL,
        reason TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_leave_requests_dates
      ON leave_requests(start_date, end_date)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS leave_balance_cache (
        employee_id TEXT PRIMARY KEY,
        balance INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
}
