import 'package:dio/dio.dart';

import '../models/attendance_event_model.dart';

class AttendanceRemoteDataSource {
  final Dio dio;

  AttendanceRemoteDataSource(this.dio);

  Future<void> submitEvent(AttendanceEventModel event) async {
    final response = await dio.post(
      '/attendance/events',
      data: {
        // The Node.js API expects "id", not "eventId".
        'id': event.eventId,
        'employeeId': event.employeeId,

        // Convert Dart enum values to the API contract.
        'eventType': event.eventType == AttendanceEventType.checkIn
            ? 'check_in'
            : 'check_out',

        'timestamp': event.timestamp.toUtc().toIso8601String(),
        'latitude': event.latitude,
        'longitude': event.longitude,
      },
    );

    if (response.data is! Map ||
        response.data['success'] != true ||
        response.data['eventId'] != event.eventId) {
      throw Exception('Invalid attendance sync response.');
    }
  }
}
