import 'package:timezone/timezone.dart' as tz;

import '../../../attendance/data/datasources/attendance_local_datasource.dart';
import '../../../attendance/data/models/attendance_event_model.dart';
import '../../data/models/attendance_summary_model.dart';
import '../../data/models/employee_model.dart';

class AttendanceSummaryService {
  final AttendanceLocalDataSource localDataSource;

  AttendanceSummaryService({required this.localDataSource});

  Future<AttendanceSummary> getSummary(EmployeeModel employee) async {
    final events = await localDataSource.getAllEvents();

    final companyLocation = tz.getLocation(employee.office.timezone);
    final now = tz.TZDateTime.now(companyLocation);

    final todayEvents = events.where((event) {
      if (event.employeeId != employee.id ||
          event.syncStatus == SyncStatus.rejected) {
        return false;
      }

      final eventTime = tz.TZDateTime.from(event.timestamp, companyLocation);

      return eventTime.year == now.year &&
          eventTime.month == now.month &&
          eventTime.day == now.day;
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final checkInEvents = todayEvents
        .where((e) => e.eventType == AttendanceEventType.checkIn)
        .toList();

    final checkOutEvents = todayEvents
        .where((e) => e.eventType == AttendanceEventType.checkOut)
        .toList();

    final checkIn = checkInEvents.isEmpty ? null : checkInEvents.first;
    final checkOut = checkOutEvents.isEmpty ? null : checkOutEvents.first;

    final status = checkIn == null
        ? 'Not Checked In'
        : checkOut == null
        ? 'Checked In'
        : 'Checked Out';

    final duration = checkIn == null
        ? null
        : (checkOut?.timestamp ?? DateTime.now().toUtc()).difference(
            checkIn.timestamp,
          );

    final recentEvents =
        events.where((e) => e.employeeId == employee.id).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return AttendanceSummary(
      status: status,
      checkIn: checkIn?.timestamp,
      checkOut: checkOut?.timestamp,
      workingDuration: duration,
      recentEvents: recentEvents.take(5).toList(),
    );
  }
}
