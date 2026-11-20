import 'package:dio/dio.dart';

import '../models/leave_request_model.dart';
import '../models/leave_balance_model.dart';

class LeaveRemoteDataSource {
  final Dio dio;

  LeaveRemoteDataSource(this.dio);

  Future<LeaveBalanceModel> getLeaveBalance() async {
    final response = await dio.get('/leave/balance');

    return LeaveBalanceModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    final response = await dio.get('/leave/requests');

    final List<dynamic> data = response.data as List<dynamic>;

    return data.map((item) {
      return LeaveRequestModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<LeaveRequestModel> submitLeaveRequest(
    LeaveRequestModel request,
  ) async {
    final response = await dio.post('/leave/requests', data: request.toJson());

    return LeaveRequestModel.fromJson(Map<String, dynamic>.from(response.data));
  }
}
