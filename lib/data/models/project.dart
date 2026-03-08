class Project {
  Project({
    required this.id,
    required this.name,
    required this.status,
    this.clientName,
    this.location,
    this.estimatedBudget,
    this.startDate,
    this.dueDate,
  });

  final String id;
  final String name;
  final String status;
  final String? clientName;
  final String? location;
  final double? estimatedBudget;
  final DateTime? startDate;
  final DateTime? dueDate;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      clientName: json['client_name'] as String?,
      location: json['location'] as String?,
      estimatedBudget: (json['estimated_budget'] as num?)?.toDouble(),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'client_name': clientName,
      'location': location,
      'estimated_budget': estimatedBudget,
      'status': status,
      if (startDate != null) 'start_date': startDate!.toIso8601String().split('T')[0],
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
    };
  }
}

