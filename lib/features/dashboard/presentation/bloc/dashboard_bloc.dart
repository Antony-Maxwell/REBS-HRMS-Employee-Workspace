import 'package:dio/dio.dart';
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
    } on DioException catch (e) {
      String message;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          message =
              'Unable to connect to the server. Please check your internet connection and try again.';
          break;

        case DioExceptionType.badResponse:
          message =
              'The server is currently unavailable. Please try again later.';
          break;

        default:
          message =
              'Something went wrong while loading your employee details. Please try again.';
      }

      emit(DashboardError(message));
    } catch (e) {
      emit(
        const DashboardError(
          'Unable to load your employee details. Please try again.',
        ),
      );
    }
  }
}
