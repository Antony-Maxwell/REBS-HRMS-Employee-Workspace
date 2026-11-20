import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/leave_repository.dart';
import '../../domain/services/leave_validation_service.dart';
import 'leave_event.dart';
import 'leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final LeaveRepository repository;
  final LeaveValidationService validationService;
  final String employeeId;

  LeaveBloc({
    required this.repository,
    required this.validationService,
    required this.employeeId,
  }) : super(const LeaveState()) {
    on<LeaveLoadRequested>(_onLoad);
    on<LeaveRefreshRequested>(_onRefresh);
    on<LeaveSubmitRequested>(_onSubmit);
  }

  Future<void> _onLoad(
    LeaveLoadRequested event,
    Emitter<LeaveState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));

    await _loadData(emit);
  }

  Future<void> _onRefresh(
    LeaveRefreshRequested event,
    Emitter<LeaveState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));

    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<LeaveState> emit) async {
    try {
      final balance = await repository.getLeaveBalance(employeeId);
      final requests = await repository.getLeaveRequests(employeeId);

      emit(
        state.copyWith(
          balance: balance,
          requests: requests,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSubmit(
    LeaveSubmitRequested event,
    Emitter<LeaveState> emit,
  ) async {
    if (state.isSubmitting) return;

    emit(
      state.copyWith(isSubmitting: true, clearError: true, clearMessage: true),
    );

    try {
      final currentBalance = state.balance;

      if (currentBalance == null) {
        throw const LeaveValidationException(
          'Leave balance is unavailable. Please refresh first.',
        );
      }

      validationService.validate(
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
        reason: event.reason,
        availableBalance: currentBalance.balance,
        existingRequests: state.requests,
        timezone: event.timezone,
      );

      final submittedRequest = await repository.submitLeaveRequest(
        employeeId: event.employeeId,
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
        reason: event.reason,
      );

      final updatedRequests = [
        submittedRequest,
        ...state.requests.where((request) => request.id != submittedRequest.id),
      ];

      var updatedBalance = state.balance;

      try {
        updatedBalance = await repository.getLeaveBalance(event.employeeId);
      } catch (_) {
        // Retain the previously cached balance if refresh fails.
      }

      emit(
        state.copyWith(
          balance: updatedBalance,
          requests: updatedRequests,
          isSubmitting: false,
          message: 'Leave request submitted successfully.',
          clearError: true,
        ),
      );
    } on LeaveValidationException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
