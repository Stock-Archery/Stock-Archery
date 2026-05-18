class UserModel {
  final String firebaseUid;
  final String name;
  final String email;
  final String phoneNumber;
  final String location;
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  UserModel({
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.isPremium,
    this.premiumExpiresAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firebaseUid: json['firebaseUid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      location: json['location'] ?? '',
      isPremium: json['isPremium'] ?? false,
      premiumExpiresAt: json['premiumExpiresAt'] != null 
          ? DateTime.tryParse(json['premiumExpiresAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firebaseUid': firebaseUid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'location': location,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? firebaseUid,
    String? name,
    String? email,
    String? phoneNumber,
    String? location,
    bool? isPremium,
    DateTime? premiumExpiresAt,
  }) {
    return UserModel(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
    );
  }
}
