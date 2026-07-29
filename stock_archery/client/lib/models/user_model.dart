class UserModel {
  final String firebaseUid;
  final String name;
  final String email;
  final String phoneNumber;
  final String location;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String? occupation;
  final String? occupationDetail;
  final String? gender;

  // Alert access fields
  final bool isSOBAlertPremium;
  final DateTime? sobAlertExpiresAt;
  final bool isXaudAlertPremium;
  final DateTime? xaudAlertExpiresAt;
  final bool isCryptoAlertPremium;
  final DateTime? cryptoAlertExpiresAt;
  final int textChatCount;

  UserModel({
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.location,
    required this.isPremium,
    this.premiumExpiresAt,
    this.occupation,
    this.occupationDetail,
    this.gender,
    this.isSOBAlertPremium = false,
    this.sobAlertExpiresAt,
    this.isXaudAlertPremium = false,
    this.xaudAlertExpiresAt,
    this.isCryptoAlertPremium = false,
    this.cryptoAlertExpiresAt,
    this.textChatCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, [Map<String, dynamic>? alertAccess]) {
    final alerts = (alertAccess != null && alertAccess.isNotEmpty) ? alertAccess : json;
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
      occupation: json['occupation'],
      occupationDetail: json['occupationDetail'],
      gender: json['gender'],
      isSOBAlertPremium: alerts['isSOB_alert_premium'] ?? false,
      sobAlertExpiresAt: alerts['SOB_alert_expiresAt'] != null
          ? DateTime.tryParse(alerts['SOB_alert_expiresAt'])
          : null,
      isXaudAlertPremium: alerts['isXaud_alert_premium'] ?? false,
      xaudAlertExpiresAt: alerts['Xaud_alert_expiresAt'] != null
          ? DateTime.tryParse(alerts['Xaud_alert_expiresAt'])
          : null,
      isCryptoAlertPremium: alerts['isCrypto_alert_premium'] ?? false,
      cryptoAlertExpiresAt: alerts['Crypto_alert_expiresAt'] != null
          ? DateTime.tryParse(alerts['Crypto_alert_expiresAt'])
          : null,
      textChatCount: json['textChatCount'] ?? 0,
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
      'occupation': occupation,
      'occupationDetail': occupationDetail,
      'gender': gender,
      'isSOB_alert_premium': isSOBAlertPremium,
      'SOB_alert_expiresAt': sobAlertExpiresAt?.toIso8601String(),
      'isXaud_alert_premium': isXaudAlertPremium,
      'Xaud_alert_expiresAt': xaudAlertExpiresAt?.toIso8601String(),
      'isCrypto_alert_premium': isCryptoAlertPremium,
      'Crypto_alert_expiresAt': cryptoAlertExpiresAt?.toIso8601String(),
      'textChatCount': textChatCount,
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
    String? occupation,
    String? occupationDetail,
    String? gender,
    bool? isSOBAlertPremium,
    DateTime? sobAlertExpiresAt,
    bool? isXaudAlertPremium,
    DateTime? xaudAlertExpiresAt,
    bool? isCryptoAlertPremium,
    DateTime? cryptoAlertExpiresAt,
    int? textChatCount,
  }) {
    return UserModel(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      occupation: occupation ?? this.occupation,
      occupationDetail: occupationDetail ?? this.occupationDetail,
      gender: gender ?? this.gender,
      isSOBAlertPremium: isSOBAlertPremium ?? this.isSOBAlertPremium,
      sobAlertExpiresAt: sobAlertExpiresAt ?? this.sobAlertExpiresAt,
      isXaudAlertPremium: isXaudAlertPremium ?? this.isXaudAlertPremium,
      xaudAlertExpiresAt: xaudAlertExpiresAt ?? this.xaudAlertExpiresAt,
      isCryptoAlertPremium: isCryptoAlertPremium ?? this.isCryptoAlertPremium,
      cryptoAlertExpiresAt: cryptoAlertExpiresAt ?? this.cryptoAlertExpiresAt,
      textChatCount: textChatCount ?? this.textChatCount,
    );
  }
}
