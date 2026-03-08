class Attendance {
  Attendance({
    required this.id,
    required this.employeeId,
    required this.projectId,
    required this.date,
    required this.status,
  });

  final String id;
  final String employeeId;
  final String projectId; // Required - attendance is always project-wise
  final DateTime date;
  final String status; // 'present' or 'absent'

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      projectId: json['project_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String? ?? 'present',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'project_id': projectId, // Required
      'date': date.toIso8601String().split('T')[0],
      'status': status,
    };
  }
}
