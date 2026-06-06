enum ChatRole { teacher, parent, student }

extension ChatRoleConfig on ChatRole {
  String get groupTabLabel {
    switch (this) {
      case ChatRole.parent:
        return 'Teachers';
      case ChatRole.student:
        return 'Groups';
      case ChatRole.teacher:
        return 'Group';
    }
  }

  String get frequentSectionLabel {
    switch (this) {
      case ChatRole.parent:
        return 'Subject Teachers';
      case ChatRole.student:
        return 'Classmates';
      case ChatRole.teacher:
        return 'Frequently Chat';
    }
  }

  String get recentSectionLabel {
    switch (this) {
      case ChatRole.parent:
        return 'Recent Teachers';
      case ChatRole.student:
        return 'Recent Chats';
      case ChatRole.teacher:
        return 'Recent Chats';
    }
  }

  bool get canComposeNewChat => this != ChatRole.student;
}
