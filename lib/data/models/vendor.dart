class Vendor {
  Vendor({
    required this.id,
    required this.name,
    this.contactNumber,
    this.materialType,
    this.projectId,
  });

  final String id;
  final String name;
  final String? contactNumber;
  final String? materialType;
  final String? projectId;

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      name: json['name'] as String,
      contactNumber: json['contact_number'] as String?,
      materialType: json['material_type'] as String?,
      projectId: json['project_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact_number': contactNumber,
      'material_type': materialType,
      'project_id': projectId,
    };
  }
}
