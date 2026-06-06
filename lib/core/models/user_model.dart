import 'dart:convert';

class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final String role;
  final String? type;
  final String? schoolId;
  final String? studentId; // This is the 'Id' from backend
  final String? gradeLevel;
  final String? avatar;
  final int? age;
  final String? gender;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    required this.role,
    this.type,
    this.schoolId,
    this.studentId,
    this.gradeLevel,
    this.avatar,
    this.age,
    this.gender,
  });

  UserModel copyWith({
    String? username,
    String? email,
    String? avatar,
    String? phoneNumber,
    int? age,
    String? gender,
    String? gradeLevel,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role,
      type: type,
      schoolId: schoolId,
      studentId: studentId,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      avatar: avatar ?? this.avatar,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
    );
  }

  /// Recursively extracts a Map from a value that could be a String (JSON), List, or Map
  static Map<String, dynamic> recursiveSafeMap(dynamic value) {
    if (value == null) return {};

    // 1. If it's a String, try to decode it as JSON first
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return recursiveSafeMap(decoded);
      } catch (_) {
        return {}; // Not a JSON string
      }
    }

    // 2. If it's a Map, return it
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    // 3. If it's a List, take the first item and try again recursively
    if (value is List && value.isNotEmpty) {
      return recursiveSafeMap(value[0]);
    }

    return {};
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: (json['username'] ?? json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      role: (json['role'] ?? json['type'] ?? '').toString(),
      type: json['type']?.toString(),
      schoolId: json['schoolId']?.toString(),
      studentId: (json['Id'] ?? json['studentId'])?.toString(),
      gradeLevel: json['gradeLevel']?.toString(),
      avatar: json['avatar'] is Map
          ? json['avatar']['url']?.toString()
          : (json['avatar']?.toString() ?? ''),
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'type': type,
      'schoolId': schoolId,
      'studentId': studentId,
      'gradeLevel': gradeLevel,
      'avatar': avatar,
      'age': age,
      'gender': gender,
    };
  }
}

class LoginResponse {
  final String token;
  final UserModel user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = UserModel.recursiveSafeMap(json['data']);
    final user = UserModel.recursiveSafeMap(data['user']);

    return LoginResponse(
      token: (data['token'] ?? '').toString(),
      user: UserModel.fromJson(user),
    );
  }
}
