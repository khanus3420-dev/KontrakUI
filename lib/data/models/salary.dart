class SalaryCalculation {
  SalaryCalculation({
    required this.employeeId,
    required this.employeeName,
    required this.wageType,
    required this.presentDays,
    this.dailyWage,
    this.monthlySalary,
    required this.calculatedSalary,
    required this.advanceAmount,
    required this.netSalary,
    required this.month,
  });

  final String employeeId;
  final String employeeName;
  final String wageType; // 'daily' or 'monthly'
  final int presentDays;
  final double? dailyWage;
  final double? monthlySalary;
  final double calculatedSalary;
  final double advanceAmount;
  final double netSalary;
  final DateTime month;

  factory SalaryCalculation.fromJson(Map<String, dynamic> json) {
    DateTime monthDate;
    final monthValue = json['month'];
    if (monthValue is String) {
      monthDate = DateTime.parse(monthValue);
    } else {
      monthDate = DateTime.parse(monthValue.toString());
    }

    return SalaryCalculation(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      wageType: json['wage_type'] as String,
      presentDays: json['present_days'] as int,
      dailyWage: (json['daily_wage'] as num?)?.toDouble(),
      monthlySalary: (json['monthly_salary'] as num?)?.toDouble(),
      calculatedSalary: (json['calculated_salary'] as num).toDouble(),
      advanceAmount: (json['advance_amount'] as num).toDouble(),
      netSalary: (json['net_salary'] as num).toDouble(),
      month: monthDate,
    );
  }
}

class SalaryCalculationResponse {
  SalaryCalculationResponse({
    required this.month,
    required this.salaries,
  });

  final DateTime month;
  final List<SalaryCalculation> salaries;

  factory SalaryCalculationResponse.fromJson(Map<String, dynamic> json) {
    DateTime monthDate;
    final monthValue = json['month'];
    if (monthValue is String) {
      monthDate = DateTime.parse(monthValue);
    } else {
      monthDate = DateTime.parse(monthValue.toString());
    }

    final items = json['salaries'] as List<dynamic>? ?? <dynamic>[];
    return SalaryCalculationResponse(
      month: monthDate,
      salaries: items.map((e) => SalaryCalculation.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SalaryPaymentResponse {
  SalaryPaymentResponse({
    required this.transactionId,
    required this.employeeId,
    required this.employeeName,
    required this.amountPaid,
    required this.month,
    required this.message,
  });

  final String transactionId;
  final String employeeId;
  final String employeeName;
  final double amountPaid;
  final DateTime month;
  final String message;

  factory SalaryPaymentResponse.fromJson(Map<String, dynamic> json) {
    DateTime monthDate;
    final monthValue = json['month'];
    if (monthValue is String) {
      monthDate = DateTime.parse(monthValue);
    } else {
      monthDate = DateTime.parse(monthValue.toString());
    }

    return SalaryPaymentResponse(
      transactionId: json['transaction_id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      month: monthDate,
      message: json['message'] as String,
    );
  }
}
