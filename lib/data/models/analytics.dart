class MonthlyExpensePoint {
  MonthlyExpensePoint({
    required this.month,
    required this.totalExpense,
  });

  final DateTime month;
  final double totalExpense;

  factory MonthlyExpensePoint.fromJson(Map<String, dynamic> json) {
    // Handle different date formats
    DateTime monthDate;
    final monthValue = json['month'];
    if (monthValue is String) {
      monthDate = DateTime.parse(monthValue);
    } else if (monthValue is DateTime) {
      monthDate = monthValue;
    } else {
      // Try to parse as string
      monthDate = DateTime.parse(monthValue.toString());
    }
    
    return MonthlyExpensePoint(
      month: monthDate,
      totalExpense: (json['total_expense'] as num? ?? 0).toDouble(),
    );
  }
}

class MonthlyExpenseData {
  MonthlyExpenseData({required this.points});

  final List<MonthlyExpensePoint> points;

  factory MonthlyExpenseData.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing MonthlyExpenseData from JSON: $json');
      final items = json['points'] as List<dynamic>? ?? <dynamic>[];
      print('Found ${items.length} points in response');
      
      final points = items
          .map((e) {
            try {
              print('Parsing point: $e');
              return MonthlyExpensePoint.fromJson(e as Map<String, dynamic>);
            } catch (err) {
              print('Error parsing point $e: $err');
              rethrow;
            }
          })
          .toList();
      
      print('Successfully parsed ${points.length} points');
      return MonthlyExpenseData(points: points);
    } catch (e, stackTrace) {
      print('Error parsing MonthlyExpenseData: $e');
      print('Stack trace: $stackTrace');
      print('JSON: $json');
      // Return empty data instead of crashing
      return MonthlyExpenseData(points: []);
    }
  }
}

class ProjectProfitPoint {
  ProjectProfitPoint({
    required this.projectId,
    required this.projectName,
    required this.totalCredit,
    required this.totalDebit,
    required this.profit,
  });

  final String projectId;
  final String projectName;
  final double totalCredit;
  final double totalDebit;
  final double profit;

  factory ProjectProfitPoint.fromJson(Map<String, dynamic> json) {
    return ProjectProfitPoint(
      projectId: json['project_id'] as String,
      projectName: json['project_name'] as String,
      totalCredit: (json['total_credit'] as num).toDouble(),
      totalDebit: (json['total_debit'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
    );
  }
}

class ProjectProfitData {
  ProjectProfitData({required this.points});

  final List<ProjectProfitPoint> points;

  factory ProjectProfitData.fromJson(Map<String, dynamic> json) {
    final items = json['points'] as List<dynamic>? ?? <dynamic>[];
    return ProjectProfitData(
      points: items.map((e) => ProjectProfitPoint.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class CategoryExpensePoint {
  CategoryExpensePoint({
    required this.category,
    required this.totalExpense,
  });

  final String category;
  final double totalExpense;

  factory CategoryExpensePoint.fromJson(Map<String, dynamic> json) {
    return CategoryExpensePoint(
      category: json['category'] as String,
      totalExpense: (json['total_expense'] as num).toDouble(),
    );
  }
}

class CategoryExpenseData {
  CategoryExpenseData({required this.points});

  final List<CategoryExpensePoint> points;

  factory CategoryExpenseData.fromJson(Map<String, dynamic> json) {
    final items = json['points'] as List<dynamic>? ?? <dynamic>[];
    return CategoryExpenseData(
      points: items.map((e) => CategoryExpensePoint.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class BudgetVsActualPoint {
  BudgetVsActualPoint({
    required this.projectId,
    required this.projectName,
    required this.estimatedBudget,
    required this.actualExpense,
  });

  final String projectId;
  final String projectName;
  final double estimatedBudget;
  final double actualExpense;

  factory BudgetVsActualPoint.fromJson(Map<String, dynamic> json) {
    return BudgetVsActualPoint(
      projectId: json['project_id'] as String,
      projectName: json['project_name'] as String,
      estimatedBudget: (json['estimated_budget'] as num).toDouble(),
      actualExpense: (json['actual_expense'] as num).toDouble(),
    );
  }
}

class BudgetVsActualData {
  BudgetVsActualData({required this.points});

  final List<BudgetVsActualPoint> points;

  factory BudgetVsActualData.fromJson(Map<String, dynamic> json) {
    final items = json['points'] as List<dynamic>? ?? <dynamic>[];
    return BudgetVsActualData(
      points: items.map((e) => BudgetVsActualPoint.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class EmployeeSalaryPoint {
  EmployeeSalaryPoint({
    required this.employeeId,
    required this.employeeName,
    required this.totalSalary,
  });

  final String employeeId;
  final String employeeName;
  final double totalSalary;

  factory EmployeeSalaryPoint.fromJson(Map<String, dynamic> json) {
    return EmployeeSalaryPoint(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      totalSalary: (json['total_salary'] as num).toDouble(),
    );
  }
}

class EmployeeSalaryData {
  EmployeeSalaryData({required this.points});

  final List<EmployeeSalaryPoint> points;

  factory EmployeeSalaryData.fromJson(Map<String, dynamic> json) {
    final items = json['points'] as List<dynamic>? ?? <dynamic>[];
    return EmployeeSalaryData(
      points: items.map((e) => EmployeeSalaryPoint.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

