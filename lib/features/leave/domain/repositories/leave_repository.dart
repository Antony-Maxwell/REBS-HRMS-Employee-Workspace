import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';

abstract class LeaveRepository {
  Future<LeaveBalanceModel> getLeaveBalance(String employeeId);

  Future<List<LeaveRequestModel>> getLeaveRequests(String employeeId);

  Future<LeaveRequestModel> submitLeaveRequest({
    required String employeeId,
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
  });
}
