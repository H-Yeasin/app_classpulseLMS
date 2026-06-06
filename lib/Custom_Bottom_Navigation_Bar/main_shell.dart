import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/custom_bottom_navigation_bar/custom_bottom_navigation_bar.dart';
import 'package:opalmer_education/chat/models/chat_role.dart';
import 'package:opalmer_education/chat/screens/chat_dashboard.dart';
import 'package:opalmer_education/teacher_role/Home_Dashboard/home_dashboard.dart';
import 'package:opalmer_education/teacher_role/Classes_Screen/classes_screen.dart';
import 'package:opalmer_education/teacher_role/profile_screen/profile.dart';
import 'package:opalmer_education/teacher_role/Quiz_Screen/grading_tool.dart';
import 'package:opalmer_education/core/providers/navigation_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(teacherTabIndexProvider);

    final List<Widget> pages = [
      const HomeDashboard(),
      const ClassesScreen(),
      const GradingToolScreen(),
      const ChatDashboard(role: ChatRole.teacher),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(teacherTabIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
