import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_local_datasource.dart';
import '../datasources/leave_remote_datasource.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_request_model.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource remoteDataSource;
  final LeaveLocalDataSource localDataSource;
  final Connectivity connectivity;

  LeaveRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  Future<bool> _isOnline() async {
    final results = await connectivity.checkConnectivity();

    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  Future<LeaveBalanceModel> getLeaveBalance(String employeeId) async {
    if (await _isOnline()) {
      try {
        final balance = await remoteDataSource.getLeaveBalance();

        await localDataSource.saveLeaveBalance(
          employeeId: employeeId,
          balance: balance,
        );

        return balance;
      } catch (_) {
        // Use cached data if the server is unavailable.
      }
    }

    final cachedBalance = await localDataSource.getLeaveBalance(employeeId);

    if (cachedBalance != null) {
      return cachedBalance;
    }

    throw Exception(
      'Leave balance is unavailable. Please connect to the internet.',
    );
  }

  @override
  Future<List<LeaveRequestModel>> getLeaveRequests(String employeeId) async {
    if (await _isOnline()) {
      try {
        final requests = await remoteDataSource.getLeaveRequests();

        await localDataSource.saveLeaveRequests(requests);

        return requests;
      } catch (_) {
        // Use cached requests if the server is unavailable.
      }
    }

    return localDataSource.getLeaveRequests(employeeId);
  }

  @override
  Future<LeaveRequestModel> submitLeaveRequest({
    required String employeeId,
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    if (!await _isOnline()) {
      throw Exception(
        'You are offline. Connect to the internet to submit a leave request.',
      );
    }

    final draft = LeaveRequestModel(
      id: '',
      employeeId: employeeId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      days: 0,
      reason: reason.trim(),
      status: 'Pending',
      createdAt: DateTime.now(),
    );

    final submittedRequest = await remoteDataSource.submitLeaveRequest(draft);

    await localDataSource.saveLeaveRequest(submittedRequest);

    // Refresh cached balance after successful submission.
    try {
      final balance = await remoteDataSource.getLeaveBalance();

      await localDataSource.saveLeaveBalance(
        employeeId: employeeId,
        balance: balance,
      );
    } catch (_) {
      // Submission succeeded. Keep the previous cached balance.
    }

    return submittedRequest;
  }
}
