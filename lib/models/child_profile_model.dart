class ChildProfileModel {
  final String id;
  final String userId;
  final String name;
  final String gender; // MALE, FEMALE, OTHER
  final DateTime dateOfBirth;
  final String? schoolOrCollege;
  final String avatarColor; // hex string e.g. '0xFF3B82F6'
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;

  ChildProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.gender = 'MALE',
    required this.dateOfBirth,
    this.schoolOrCollege,
    this.avatarColor = '0xFF3B82F6',
    this.photoUrl,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (now.day < dateOfBirth.day) {
      months--;
    }
    return months < 0 ? 0 : months;
  }

  String get formattedAge {
    final years = ageInYears;
    final months = ageInMonths % 12;
    if (years == 0) {
      return '$months Months';
    } else if (months == 0) {
      return '$years Yrs';
    } else {
      return '$years Yrs $months Mo';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String().split('T')[0],
      'schoolOrCollege': schoolOrCollege,
      'avatarColor': avatarColor,
      'photoUrl': photoUrl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? 'MALE',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'].toString())
          : (json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'].toString())
              : DateTime.now()),
      schoolOrCollege: json['schoolOrCollege'] ?? json['school_or_college'],
      avatarColor: json['avatarColor'] ?? json['avatar_color'] ?? '0xFF3B82F6',
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      'school_or_college': schoolOrCollege,
      'avatar_color': avatarColor,
      'photo_url': photoUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChildProfileModel.fromMap(Map<String, dynamic> map) {
    return ChildProfileModel.fromJson(map);
  }

  ChildProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? gender,
    DateTime? dateOfBirth,
    String? schoolOrCollege,
    String? avatarColor,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return ChildProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      schoolOrCollege: schoolOrCollege ?? this.schoolOrCollege,
      avatarColor: avatarColor ?? this.avatarColor,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
