import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceLoadRequested extends AttendanceEvent {
  const AttendanceLoadRequested();
}

class AttendanceCheckInRequested extends AttendanceEvent {
  const AttendanceCheckInRequested();
}

class AttendanceCheckOutRequested extends AttendanceEvent {
  const AttendanceCheckOutRequested();
}

class AttendanceSyncRequested extends AttendanceEvent {
  const AttendanceSyncRequested();
}
