enum AttendanceEventType { checkIn, checkOut }

enum SyncStatus { pending, synced, rejected }

class AttendanceEventModel {
  final String eventId;
  final String employeeId;
  final AttendanceEventType eventType;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final SyncStatus syncStatus;
  final int attemptCount;
  final String? lastError;

  const AttendanceEventModel({
    required this.eventId,
    required this.employeeId,
    required this.eventType,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.syncStatus = SyncStatus.pending,
    this.attemptCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'employee_id': employeeId,
      'event_type': eventType.name,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'sync_status': syncStatus.name,
      'attempt_count': attemptCount,
      'last_error': lastError,
    };
  }

  factory AttendanceEventModel.fromMap(Map<String, dynamic> map) {
    return AttendanceEventModel(
      eventId: map['event_id'] as String,
      employeeId: map['employee_id'] as String,
      eventType: AttendanceEventType.values.byName(map['event_type'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String).toUtc(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
      attemptCount: map['attempt_count'] as int,
      lastError: map['last_error'] as String?,
    );
  }
}
