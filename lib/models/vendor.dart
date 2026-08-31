class VendorDocument {
  const VendorDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.status = 'pending',
    this.note = '',
  });

  final String id;
  final String name;
  final String type;
  final String url;
  final String status;
  final String note;

  VendorDocument copyWith({String? status, String? note, String? url}) => VendorDocument(
        id: id,
        name: name,
        type: type,
        url: url ?? this.url,
        status: status ?? this.status,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'url': url,
        'status': status,
        'note': note,
      };

  factory VendorDocument.fromJson(Map<String, dynamic> json) => VendorDocument(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Document',
        type: json['type'] as String? ?? 'other',
        url: json['url'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        note: json['note'] as String? ?? '',
      );
}

class VendorHistoryEntry {
  const VendorHistoryEntry({
    required this.at,
    required this.action,
    this.actorId = '',
    this.actorName = '',
    this.detail = '',
  });

  final DateTime at;
  final String action;
  final String actorId;
  final String actorName;
  final String detail;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'action': action,
        'actorId': actorId,
        'actorName': actorName,
        'detail': detail,
      };

  factory VendorHistoryEntry.fromJson(Map<String, dynamic> json) => VendorHistoryEntry(
        at: parseVendorDate(json['at']) ?? DateTime.now(),
        action: json['action'] as String? ?? '',
        actorId: json['actorId'] as String? ?? '',
        actorName: json['actorName'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );
}

DateTime? parseVendorDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    return (value as dynamic).toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}

/// Stored values: pending | approved | rejected | suspended
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
    this.approvalStatus = 'approved',
    this.logoLabel = 'A',
    this.bio = 'Independent atelier crafting considered essentials.',
    this.cnic = '',
    this.logoUrl = '',
    this.bankName = '',
    this.accountTitle = '',
    this.accountNumber = '',
    this.iban = '',
    this.rejectionReason = '',
    this.suspensionReason = '',
    this.reviewedBy = '',
    this.reviewedByName = '',
    this.registeredAt,
    this.reviewedAt,
    this.documents = const [],
    this.history = const [],
    this.billingStatus = 'active',
    this.planId = 'basic',
    this.listingCap = 20,
  });

  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String category;
  final String address;
  final String storeStatus;
  final String approvalStatus;
  final String logoLabel;
  final String bio;
  final String cnic;
  final String logoUrl;
  final String bankName;
  final String accountTitle;
  final String accountNumber;
  final String iban;
  final String rejectionReason;
  final String suspensionReason;
  final String reviewedBy;
  final String reviewedByName;
  final DateTime? registeredAt;
  final DateTime? reviewedAt;
  final List<VendorDocument> documents;
  final List<VendorHistoryEntry> history;
  final String billingStatus;
  final String planId;
  final int listingCap;

  bool get canSell => approvalStatus == 'approved' && billingStatus != 'read_only';
  bool get isReadOnly => billingStatus == 'read_only' || approvalStatus == 'suspended';
  bool get isPending => approvalStatus == 'pending';
  bool get isRejected => approvalStatus == 'rejected';
  bool get isSuspended => approvalStatus == 'suspended';
  bool get canResubmit => approvalStatus == 'rejected';
  bool get isRestricted => !canSell;

  String get roleCode => switch (approvalStatus) {
        'approved' => 'VENDOR_APPROVED',
        'rejected' => 'VENDOR_REJECTED',
        'suspended' => 'VENDOR_SUSPENDED',
        _ => 'VENDOR_PENDING',
      };

  String get displayStatus => switch (approvalStatus) {
        'approved' => 'Approved',
        'rejected' => 'Rejected',
        'suspended' => 'Suspended',
        _ => 'Pending approval',
      };

  String get documentsStatus {
    if (documents.isEmpty) return 'missing';
    if (documents.any((d) => d.status == 'rejected')) return 'rejected';
    if (documents.every((d) => d.status == 'verified')) return 'verified';
    return 'pending';
  }

  String get documentsStatusLabel => switch (documentsStatus) {
        'verified' => 'Verified',
        'rejected' => 'Rejected',
        'missing' => 'Not uploaded',
        _ => 'Pending',
      };

  Vendor copyWith({
    String? businessName,
    String? ownerName,
    String? email,
    String? phone,
    String? category,
    String? address,
    String? storeStatus,
    String? approvalStatus,
    String? bio,
    String? cnic,
    String? logoUrl,
    String? bankName,
    String? accountTitle,
    String? accountNumber,
    String? iban,
    String? rejectionReason,
    String? suspensionReason,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? registeredAt,
    DateTime? reviewedAt,
    List<VendorDocument>? documents,
    List<VendorHistoryEntry>? history,
    String? billingStatus,
    String? planId,
    int? listingCap,
    bool clearRejection = false,
    bool clearSuspension = false,
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
      approvalStatus: approvalStatus ?? this.approvalStatus,
      logoLabel: logoLabel,
      bio: bio ?? this.bio,
      cnic: cnic ?? this.cnic,
      logoUrl: logoUrl ?? this.logoUrl,
      bankName: bankName ?? this.bankName,
      accountTitle: accountTitle ?? this.accountTitle,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      rejectionReason: clearRejection ? '' : (rejectionReason ?? this.rejectionReason),
      suspensionReason: clearSuspension ? '' : (suspensionReason ?? this.suspensionReason),
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      registeredAt: registeredAt ?? this.registeredAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      documents: documents ?? this.documents,
      history: history ?? this.history,
      billingStatus: billingStatus ?? this.billingStatus,
      planId: planId ?? this.planId,
      listingCap: listingCap ?? this.listingCap,
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
        'approvalStatus': approvalStatus,
        'logoLabel': logoLabel,
        'bio': bio,
        'cnic': cnic,
        'logoUrl': logoUrl,
        'bankName': bankName,
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'iban': iban,
        'rejectionReason': rejectionReason,
        'suspensionReason': suspensionReason,
        'reviewedBy': reviewedBy,
        'reviewedByName': reviewedByName,
        'registeredAt': registeredAt?.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'documents': documents.map((e) => e.toJson()).toList(),
        'history': history.map((e) => e.toJson()).toList(),
        'billingStatus': billingStatus,
        'planId': planId,
        'listingCap': listingCap,
      };

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: json['id'] as String? ?? '',
        businessName: json['businessName'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        category: json['category'] as String? ?? '',
        address: json['address'] as String? ?? '',
        storeStatus: json['storeStatus'] as String? ?? 'Open',
        approvalStatus: json['approvalStatus'] as String? ?? 'approved',
        logoLabel: json['logoLabel'] as String? ?? 'V',
        bio: json['bio'] as String? ?? '',
        cnic: json['cnic'] as String? ?? '',
        logoUrl: json['logoUrl'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        accountTitle: json['accountTitle'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
        iban: json['iban'] as String? ?? '',
        rejectionReason: json['rejectionReason'] as String? ?? '',
        suspensionReason: json['suspensionReason'] as String? ?? '',
        reviewedBy: json['reviewedBy'] as String? ?? '',
        reviewedByName: json['reviewedByName'] as String? ?? '',
        registeredAt: parseVendorDate(json['registeredAt']),
        reviewedAt: parseVendorDate(json['reviewedAt']),
        documents: (json['documents'] as List? ?? const [])
            .map((e) => VendorDocument.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        history: (json['history'] as List? ?? const [])
            .map((e) => VendorHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        billingStatus: json['billingStatus'] as String? ?? 'active',
        planId: json['planId'] as String? ?? 'basic',
        listingCap: (json['listingCap'] as num?)?.toInt() ?? 20,
      );
}
