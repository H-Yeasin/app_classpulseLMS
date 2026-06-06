import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/providers/grading_provider.dart';
import 'package:opalmer_education/core/providers/navigation_provider.dart';
import 'package:opalmer_education/core/providers/teacher_provider.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/core/widgets/pressable_card.dart';

import '../../notification/notification.dart';
import '../Classes_Screen/widgets/teacher_class_card.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _quizController;
  late AnimationController _bellController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _bellShake;

  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardFades = [];
  final List<Animation<Offset>> _cardSlides = [];

  final List<AnimationController> _quizCardControllers = [];
  final List<Animation<double>> _quizCardFades = [];
  final List<Animation<Offset>> _quizCardSlides = [];

  @override
  void initState() {
    super.initState();

    // Header animation
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
        );

    // Bell shake animation
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bellShake =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.08), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.06), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
        );

    // Class stat cards staggered animation - initialized with count 2 as default
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Quiz cards staggered animation
    _quizController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _startAnimations();
  }

  void _setupCardAnimations(int count) {
    if (_cardControllers.length == count) return;

    for (var c in _cardControllers) {
      c.dispose();
    }
    _cardControllers.clear();
    _cardFades.clear();
    _cardSlides.clear();

    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _cardControllers.add(controller);
      _cardFades.add(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      _cardSlides.add(
        Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
      );
    }

    _triggerCardAnimations();
  }

  void _setupQuizCardAnimations(int count) {
    if (_quizCardControllers.length == count) return;

    for (final c in _quizCardControllers) {
      c.dispose();
    }
    _quizCardControllers.clear();
    _quizCardFades.clear();
    _quizCardSlides.clear();

    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      );
      _quizCardControllers.add(controller);
      _quizCardFades.add(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      _quizCardSlides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
      );
    }

    _triggerQuizCardAnimations();
  }

  Future<void> _triggerCardAnimations() async {
    for (int i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) _cardControllers[i].forward();
    }
  }

  Future<void> _triggerQuizCardAnimations() async {
    for (int i = 0; i < _quizCardControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _quizCardControllers[i].forward();
    }
  }

  Future<void> _startAnimations() async {
    // Header fades in
    _headerController.forward();

    // Bell shakes after header appears
    await Future.delayed(const Duration(milliseconds: 600));
    _bellController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _quizController.dispose();
    _bellController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    for (final c in _quizCardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(teacherClassesProvider);
    final quizzesAsync = ref.watch(teacherQuizzesProvider);
    final user = ref.watch(authStateProvider);
    final sessionsAsync = ref.watch(teacherSessionsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Stack(
              children: [
                Image.asset(
                  'assets/images/Home_dashboard_header.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Animated greeting text
                            FadeTransition(
                              opacity: _headerFade,
                              child: SlideTransition(
                                position: _headerSlide,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hi, ${user?.username ?? 'Teacher'} 👋",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    Text(
                                      "Check your students activities",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            offset: const Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Animated bell shake
                            AnimatedBuilder(
                              animation: _bellShake,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _bellShake.value,
                                  child: child,
                                );
                              },
                              child: FadeTransition(
                                opacity: _headerFade,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NotificationScreen(),
                                      ),
                                    );
                                  },
                                  child: Image.asset(
                                    'assets/images/home_dashboard/notification.png',
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Main Content Area (Shifted Up to overlap header) ──
            Transform.translate(
              offset: const Offset(0, -25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Class Stats Section ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Class Stats",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(teacherTabIndexProvider.notifier).state =
                                1;
                          },
                          child: Text(
                            "View All",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryMid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal scrollable Class Stats cards
                  SizedBox(
                    height: 220,
                    child: classesAsync.when(
                      data: (classes) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _setupCardAnimations(classes.length);
                        });

                        if (classes.isEmpty) {
                          return const Center(child: Text("No classes found."));
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final cls = classes[index];
                            final Color cardColor = index % 2 == 0
                                ? AppColors.success
                                : AppColors.warning;

                            return Row(
                              children: [
                                FadeTransition(
                                  opacity: index < _cardFades.length
                                      ? _cardFades[index]
                                      : const AlwaysStoppedAnimation(1),
                                  child: SlideTransition(
                                    position: index < _cardSlides.length
                                        ? _cardSlides[index]
                                        : const AlwaysStoppedAnimation(
                                            Offset.zero,
                                          ),
                                    child: TeacherClassCard(
                                      width: 280,
                                      margin: EdgeInsets.zero,
                                      classData: cls,
                                      color: cardColor,
                                    ),
                                  ),
                                ),
                                if (index < classes.length - 1)
                                  const SizedBox(width: 14),
                              ],
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text("Error: $err")),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Quizzes Section ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Quizzes",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quiz list items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: quizzesAsync.when(
                      data: (quizzes) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _setupQuizCardAnimations(quizzes.length);
                        });

                        if (quizzes.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: Text("No quizzes found.")),
                          );
                        }

                        return Column(
                          children: [
                            ...List.generate(quizzes.length, (index) {
                              final quiz = quizzes[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == quizzes.length - 1 ? 0 : 12,
                                ),
                                child: FadeTransition(
                                  opacity: index < _quizCardFades.length
                                      ? _quizCardFades[index]
                                      : const AlwaysStoppedAnimation(1),
                                  child: SlideTransition(
                                    position: index < _quizCardSlides.length
                                        ? _quizCardSlides[index]
                                        : const AlwaysStoppedAnimation(
                                            Offset.zero,
                                          ),
                                    child: _buildQuizCardFromModel(quiz),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 100), // Space for bottom nav
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text("Error: $err")),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCardFromModel(QuizModel quiz) {
    final status = quiz.status.trim().isEmpty ? 'Draft' : quiz.status.trim();
    final normalizedStatus = status.toLowerCase();
    final statusColor = normalizedStatus == 'published'
        ? AppColors.success
        : AppColors.warning;

    return _buildQuizCard(
      title: quiz.title.isNotEmpty ? quiz.title : 'Untitled Quiz',
      questions:
          "${quiz.questionCount} ${quiz.questionCount == 1 ? 'Question' : 'Questions'}",
      duration: "${quiz.durationMinutes} min",
      status: _formatQuizStatus(status),
      statusColor: statusColor,
    );
  }

  String _formatQuizStatus(String status) {
    if (status.isEmpty) return 'Draft';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Widget _buildQuizCard({
    required String title,
    required String questions,
    required String duration,
    required String status,
    required Color statusColor,
  }) {
    return PressableCard(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Quiz thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF4A3B8F),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$questions · $duration",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
