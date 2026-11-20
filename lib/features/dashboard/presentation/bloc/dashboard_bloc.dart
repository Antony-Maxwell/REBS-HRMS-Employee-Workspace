import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/services/attendance_summary_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;
  final AttendanceSummaryService attendanceSummaryService;

  DashboardBloc({
    required this.repository,
    required this.attendanceSummaryService,
  }) : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      final employee = await repository.getEmployee();

      final attendanceSummary = await attendanceSummaryService.getSummary(
        employee,
      );

      emit(
        DashboardLoaded(
          employee: employee,
          attendanceSummary: attendanceSummary,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
