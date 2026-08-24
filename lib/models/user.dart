class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarLabel = 'S',
    this.city = 'San Francisco',
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarLabel;
  final String city;

  String get firstName => fullName.split(' ').first;

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? city,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarLabel: avatarLabel,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'avatarLabel': avatarLabel,
        'city': city,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        avatarLabel: json['avatarLabel'] as String? ?? 'M',
        city: json['city'] as String? ?? 'San Francisco',
      );
}
