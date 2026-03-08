class Organization {
  Organization({
    required this.id,
    required this.name,
    required this.baseCurrencyCode,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.isActive,
    this.registrationNumber,
    this.gstNumber,
    this.panNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String baseCurrencyCode;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool isActive;
  final String? registrationNumber;
  final String? gstNumber;
  final String? panNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      baseCurrencyCode: json['base_currency_code'] as String? ?? 'INR',
      contactPerson: json['contact_person'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String? ?? 'India',
      subscriptionStartDate: json['subscription_start_date'] != null
          ? DateTime.parse(json['subscription_start_date'] as String)
          : null,
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.parse(json['subscription_end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      registrationNumber: json['registration_number'] as String?,
      gstNumber: json['gst_number'] as String?,
      panNumber: json['pan_number'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

class OrganizationCreate {
  OrganizationCreate({
    required this.name,
    this.baseCurrencyCode = 'INR',
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country = 'India',
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.registrationNumber,
    this.gstNumber,
    this.panNumber,
  });

  final String name;
  final String baseCurrencyCode;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final String? registrationNumber;
  final String? gstNumber;
  final String? panNumber;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'base_currency_code': baseCurrencyCode,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (contactEmail != null) 'contact_email': contactEmail,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (postalCode != null) 'postal_code': postalCode,
      if (country != null) 'country': country,
      if (subscriptionStartDate != null)
        'subscription_start_date': subscriptionStartDate!.toIso8601String().split('T')[0],
      if (subscriptionEndDate != null)
        'subscription_end_date': subscriptionEndDate!.toIso8601String().split('T')[0],
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (gstNumber != null) 'gst_number': gstNumber,
      if (panNumber != null) 'pan_number': panNumber,
    };
  }
}

class OrganizationUpdate {
  OrganizationUpdate({
    this.name,
    this.baseCurrencyCode,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.isActive,
    this.registrationNumber,
    this.gstNumber,
    this.panNumber,
  });

  final String? name;
  final String? baseCurrencyCode;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool? isActive;
  final String? registrationNumber;
  final String? gstNumber;
  final String? panNumber;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (baseCurrencyCode != null) 'base_currency_code': baseCurrencyCode,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (contactEmail != null) 'contact_email': contactEmail,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (postalCode != null) 'postal_code': postalCode,
      if (country != null) 'country': country,
      if (subscriptionStartDate != null)
        'subscription_start_date': subscriptionStartDate!.toIso8601String().split('T')[0],
      if (subscriptionEndDate != null)
        'subscription_end_date': subscriptionEndDate!.toIso8601String().split('T')[0],
      if (isActive != null) 'is_active': isActive,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (gstNumber != null) 'gst_number': gstNumber,
      if (panNumber != null) 'pan_number': panNumber,
    };
  }
}
