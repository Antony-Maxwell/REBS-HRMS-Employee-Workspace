import 'package:equatable/equatable.dart';

abstract class LeaveEvent extends Equatable {
  const LeaveEvent();

  @override
  List<Object?> get props => [];
}

class LeaveLoadRequested extends LeaveEvent {
  const LeaveLoadRequested();
}

class LeaveRefreshRequested extends LeaveEvent {
  const LeaveRefreshRequested();
}

class LeaveSubmitRequested extends LeaveEvent {
  final String employeeId;
  final String timezone;
  final String type;
  final String startDate;
  final String endDate;
  final String reason;

  const LeaveSubmitRequested({
    required this.employeeId,
    required this.timezone,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  @override
  List<Object?> get props => [
    employeeId,
    timezone,
    type,
    startDate,
    endDate,
    reason,
  ];
}
