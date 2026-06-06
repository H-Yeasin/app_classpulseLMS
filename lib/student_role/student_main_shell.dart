import 'package:flutter/material.dart';
import 'package:opalmer_education/student_role/StudentHomeDashboard/student_home_dashboard.dart';
import 'package:opalmer_education/student_role/widgets/student_bottom_navbar.dart';
import 'package:opalmer_education/student_role/Quizzes/student_quiz_main_screen.dart';
import 'package:opalmer_education/student_role/Subjects/subjects_screen.dart';
import 'package:opalmer_education/chat/models/chat_role.dart';
import 'package:opalmer_education/chat/screens/chat_dashboard.dart';
import 'package:opalmer_education/student_role/Profile/student_profile_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/providers/navigation_provider.dart';

class StudentMainShell extends ConsumerStatefulWidget {
  const StudentMainShell({super.key});

  @override
  ConsumerState<StudentMainShell> createState() => _StudentMainShellState();
}

class _StudentMainShellState extends ConsumerState<StudentMainShell> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(studentTabIndexProvider);

    final List<Widget> pages = [
      const StudentHomeDashboard(),
      const SubjectsScreen(),
      const ChatDashboard(role: ChatRole.student),
      const StudentQuizMainScreen(),
      const StudentProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: StudentBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(studentTabIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
