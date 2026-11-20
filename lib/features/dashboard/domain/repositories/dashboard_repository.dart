import '../../data/models/employee_model.dart';

abstract class DashboardRepository {
  Future<EmployeeModel> getEmployee();
}
