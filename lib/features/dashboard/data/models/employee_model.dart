class EmployeeModel {
  final String id;
  final String name;
  final String department;
  final OfficeModel office;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.department,
    required this.office,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      office: OfficeModel.fromJson(json['office'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'office': office.toJson(),
    };
  }
}

class OfficeModel {
  final double latitude;
  final double longitude;
  final double radius;
  final String timezone;

  const OfficeModel({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.timezone,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    return OfficeModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      timezone: json['timezone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'timezone': timezone,
    };
  }
}
