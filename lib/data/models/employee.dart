class Employee {
  Employee({
    required this.id,
    required this.name,
    required this.wageType,
    this.phoneNumber,
    this.aadharNumber,
    this.dailyWage,
    this.monthlySalary,
    this.advanceAmount = 0,
    this.projectId,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? phoneNumber;
  final String? aadharNumber;
  final String wageType; // 'daily' or 'monthly'
  final double? dailyWage;
  final double? monthlySalary;
  final double advanceAmount;
  final String? projectId;
  final bool isActive;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String?,
      aadharNumber: json['aadhar_number'] as String?,
      wageType: json['wage_type'] as String? ?? 'daily',
      dailyWage: (json['daily_wage'] as num?)?.toDouble(),
      monthlySalary: (json['monthly_salary'] as num?)?.toDouble(),
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0,
      projectId: json['project_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'aadhar_number': aadharNumber,
      'wage_type': wageType,
      'daily_wage': dailyWage,
      'monthly_salary': monthlySalary,
      'advance_amount': advanceAmount,
      'project_id': projectId,
      'is_active': isActive,
    };
  }
}
