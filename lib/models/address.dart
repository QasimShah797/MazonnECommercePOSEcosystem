class Address {
  const Address({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.region,
    required this.postalCode,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String line1;
  final String city;
  final String region;
  final String postalCode;
  final bool isDefault;

  String get summary => '$line1, $city';

  Address copyWith({
    String? label,
    String? fullName,
    String? phone,
    String? line1,
    String? city,
    String? region,
    String? postalCode,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      city: city ?? this.city,
      region: region ?? this.region,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'fullName': fullName,
        'phone': phone,
        'line1': line1,
        'city': city,
        'region': region,
        'postalCode': postalCode,
        'isDefault': isDefault,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String,
        label: json['label'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        line1: json['line1'] as String,
        city: json['city'] as String,
        region: json['region'] as String,
        postalCode: json['postalCode'] as String,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
