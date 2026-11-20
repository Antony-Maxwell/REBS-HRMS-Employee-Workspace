import 'package:equatable/equatable.dart';
import 'package:rebs_hrms/features/dashboard/data/models/attendance_summary_model.dart';
import '../../data/models/employee_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final EmployeeModel employee;
  final AttendanceSummary attendanceSummary;

  const DashboardLoaded({
    required this.employee,
    required this.attendanceSummary,
  });

  @override
  List<Object?> get props => [employee, attendanceSummary];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
