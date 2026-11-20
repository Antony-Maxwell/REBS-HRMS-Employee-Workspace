import 'package:equatable/equatable.dart';

import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';

class LeaveState extends Equatable {
  final LeaveBalanceModel? balance;
  final List<LeaveRequestModel> requests;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? message;

  const LeaveState({
    this.balance,
    this.requests = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.message,
  });

  LeaveState copyWith({
    LeaveBalanceModel? balance,
    List<LeaveRequestModel>? requests,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return LeaveState(
      balance: balance ?? this.balance,
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    balance,
    requests,
    isLoading,
    isSubmitting,
    error,
    message,
  ];
}
