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
    this.country = 'Pakistan',
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
  final String country;
  final bool isDefault;

  String get summary => '$line1, $city, $region, $country';

  bool get isLegacyForeign {
    final haystack = '$city $region $country'.toLowerCase();
    return haystack.contains('san francisco') ||
        haystack.contains('california') ||
        region.toUpperCase() == 'CA' ||
        country.toLowerCase() == 'united states' ||
        country.toLowerCase() == 'usa';
  }

  Address copyWith({
    String? label,
    String? fullName,
    String? phone,
    String? line1,
    String? city,
    String? region,
    String? postalCode,
    String? country,
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
      country: country ?? this.country,
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
        'country': country,
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
        postalCode: json['postalCode'] as String? ?? '',
        country: json['country'] as String? ?? 'Pakistan',
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
