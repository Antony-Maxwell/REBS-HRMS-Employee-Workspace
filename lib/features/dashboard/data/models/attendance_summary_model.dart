import '../../../attendance/data/models/attendance_event_model.dart';

class AttendanceSummary {
  final String status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final Duration? workingDuration;
  final List<AttendanceEventModel> recentEvents;

  const AttendanceSummary({
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.workingDuration,
    required this.recentEvents,
  });
}
