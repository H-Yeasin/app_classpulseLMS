import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { teacher, student, parent, guest }

class RoleNotifier extends StateNotifier<UserRole> {
  RoleNotifier() : super(UserRole.guest);

  void setRole(UserRole role) {
    state = role;
  }

  void setRoleFromString(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'teacher':
        state = UserRole.teacher;
        break;
      case 'student':
        state = UserRole.student;
        break;
      case 'parent':
        state = UserRole.parent;
        break;
      default:
        state = UserRole.guest;
    }
  }
}

final roleProvider = StateNotifierProvider<RoleNotifier, UserRole>((ref) {
  return RoleNotifier();
});
