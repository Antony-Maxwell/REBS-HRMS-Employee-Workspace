import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../../../core/location/location_service.dart';
import '../../../dashboard/data/models/employee_model.dart';
import '../../data/datasources/attendance_local_datasource.dart';
import '../../data/models/attendance_event_model.dart';

class AttendanceActionService {
  final LocationService locationService;
  final AttendanceLocalDataSource localDataSource;
  final Uuid uuid;

  AttendanceActionService({
    required this.locationService,
    required this.localDataSource,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<AttendanceEventModel> recordAttendance({
    required AttendanceEventType eventType,
    required EmployeeModel employee,
  }) async {
    final office = employee.office;

    final position = await locationService.getCurrentLocation();

    final distance = locationService.calculateDistance(
      currentLatitude: position.latitude,
      currentLongitude: position.longitude,
      officeLatitude: office.latitude,
      officeLongitude: office.longitude,
    );

    if (distance > office.radius) {
      throw Exception(
        'You are ${distance.toStringAsFixed(0)} metres '
        'away from the office. Attendance is allowed '
        'only within ${office.radius.toStringAsFixed(0)} metres.',
      );
    }

    final companyLocation = tz.getLocation(office.timezone);
    final companyNow = tz.TZDateTime.now(companyLocation);

    final events = await localDataSource.getAllEvents();

    final todayEvents = events.where((event) {
      if (event.employeeId != employee.id ||
          event.syncStatus == SyncStatus.rejected) {
        return false;
      }

      final eventTime = tz.TZDateTime.from(event.timestamp, companyLocation);

      return eventTime.year == companyNow.year &&
          eventTime.month == companyNow.month &&
          eventTime.day == companyNow.day;
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final checkInExists = todayEvents.any(
      (event) => event.eventType == AttendanceEventType.checkIn,
    );

    final checkOutExists = todayEvents.any(
      (event) => event.eventType == AttendanceEventType.checkOut,
    );

    if (eventType == AttendanceEventType.checkIn) {
      if (checkInExists) {
        throw Exception('You have already checked in today.');
      }
    } else {
      if (!checkInExists) {
        throw Exception('You must check in before checking out.');
      }

      if (checkOutExists) {
        throw Exception('You have already checked out today.');
      }
    }

    final event = AttendanceEventModel(
      eventId: uuid.v4(),
      employeeId: employee.id,
      eventType: eventType,
      timestamp: companyNow.toUtc(),
      latitude: position.latitude,
      longitude: position.longitude,
    );

    await localDataSource.saveEvent(event);

    return event;
  }
}
