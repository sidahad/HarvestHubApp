class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String role; // 'Customer', 'Farmer', 'Admin'
  final String? profilePic;
  final DateTime createdAt;
  final bool emailVerified;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    this.profilePic,
    DateTime? createdAt,
    this.emailVerified = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'profilePic': profilePic,
      'createdAt': createdAt.toIso8601String(),
      'emailVerified': emailVerified,
      'isVerified': false, // default false; admin sets to true via dashboard
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? 'Customer',
      profilePic: map['profilePic'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      emailVerified: map['emailVerified'] == true,
    );
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? profilePic,
    bool? emailVerified,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      profilePic: profilePic ?? this.profilePic,
      createdAt: createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
