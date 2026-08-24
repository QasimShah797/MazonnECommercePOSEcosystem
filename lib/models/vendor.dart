class Vendor {
  const Vendor({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.category,
    required this.address,
    this.storeStatus = 'Open',
    this.logoLabel = 'A',
    this.bio = 'Independent atelier crafting considered essentials.',
  });

  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String category;
  final String address;
  final String storeStatus;
  final String logoLabel;
  final String bio;

  Vendor copyWith({
    String? businessName,
    String? ownerName,
    String? email,
    String? phone,
    String? category,
    String? address,
    String? storeStatus,
    String? bio,
  }) {
    return Vendor(
      id: id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      address: address ?? this.address,
      storeStatus: storeStatus ?? this.storeStatus,
      logoLabel: logoLabel,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'ownerName': ownerName,
        'email': email,
        'phone': phone,
        'category': category,
        'address': address,
        'storeStatus': storeStatus,
        'logoLabel': logoLabel,
        'bio': bio,
      };

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: json['id'] as String,
        businessName: json['businessName'] as String,
        ownerName: json['ownerName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        category: json['category'] as String,
        address: json['address'] as String,
        storeStatus: json['storeStatus'] as String? ?? 'Open',
        logoLabel: json['logoLabel'] as String? ?? 'V',
        bio: json['bio'] as String? ?? '',
      );
}
