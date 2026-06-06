import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/models/user_model.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/core/widgets/pressable_card.dart';
import 'package:opalmer_education/core/widgets/learning_tip_card.dart';
import 'package:opalmer_education/core/widgets/animated_wave_header.dart';
import 'package:opalmer_education/parent_role/LearningTipsScreen/models/learning_tip.dart';
import 'package:opalmer_education/parent_role/services/learning_tips_service.dart';
import 'package:opalmer_education/notification/notification.dart';
import 'package:opalmer_education/parent_role/LearningTipsScreen/learning_tips_screen.dart';
import 'package:opalmer_education/parent_role/LearningTipsScreen/learning_tip_detail_screen.dart';
import 'package:opalmer_education/parent_role/ChildsProfilesScreen/childs_profiles_screen.dart';
import 'package:opalmer_education/parent_role/ChildsProfilesScreen/models/child_profile.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/subjects_screen.dart';

class ParentHomeDashboard extends ConsumerStatefulWidget {
  const ParentHomeDashboard({super.key});

  @override
  ConsumerState<ParentHomeDashboard> createState() =>
      _ParentHomeDashboardState();
}

class _ParentHomeDashboardState extends ConsumerState<ParentHomeDashboard> {
  bool _isLoading = true;
  bool _isLoadingProfiles = true;
  bool _isLoadingTips = true;
  List<ChildProfile> _profiles = [];
  List<LearningTip> _tips = [];
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _loadUserFromStorageIfEmpty();
    _loadProfiles();
    _loadTips();
  }

  Future<void> _loadTips() async {
    try {
      final tips = await LearningTipsService.instance.fetch();
      if (mounted) {
        setState(() {
          _tips = tips;
        });
      }
    } catch (e) {
      debugPrint('Failed to load dashboard learning tips: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTips = false;
        });
      }
    }
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoadingProfiles = true;
    });
    try {
      String? userData = await _storage.getUserData();
      if (userData != null) {
        final userMap = jsonDecode(userData);
        final parentId = userMap['id'] ?? userMap['_id'];

        final response = await _apiClient.get('/parent/child/parent/$parentId');
        if (response.data['success'] == true) {
          final List childrenList = response.data['data']['children'] ?? [];
          if (mounted) {
            setState(() {
              _profiles = childrenList
                  .map((c) {
                    final child = c['childId'];
                    if (child is! Map) return null;
                    return ChildProfile.fromJson(
                      Map<String, dynamic>.from(child),
                      relationId: c['_id']?.toString(),
                    );
                  })
                  .whereType<ChildProfile>()
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to load dashboard profiles: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfiles = false;
        });
      }
    }
  }

  Future<void> _loadUserFromStorageIfEmpty() async {
    // If the global state is null, try to load it from storage
    if (ref.read(authStateProvider) == null) {
      try {
        final userDataStr = await _storage.getUserData();
        if (userDataStr != null) {
          final map = jsonDecode(userDataStr);
          ref.read(authStateProvider.notifier).state = UserModel.fromJson(map);
        }
      } catch (_) {}
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Stack(
            children: [
              const AnimatedWaveHeader(height: 200),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "Hi, ${user?.username ?? 'User'} 👋",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              Text(
                                "Check your Children's activities",
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
                          // Notification bell
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Image.asset(
                                'assets/images/home_dashboard/notification.png',
                                height: 24,
                                width: 24,
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

          // Content below header gracefully fills remaining space
          Expanded(
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Child's Profiles ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Child's Profiles",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChildsProfilesScreen(),
                              ),
                            ).then((_) => _loadProfiles());
                          },
                          child: Text(
                            "View All",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryMid,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingProfiles
                      ? const SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryMid,
                            ),
                          ),
                        )
                      : _profiles.isEmpty
                      ? const SizedBox(
                          height: 120,
                          child: Center(
                            child: Text(
                              "No children added yet.\nTap 'View All' to add.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: _profiles.take(3).map((profile) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: _buildChildCard(profile),
                              );
                            }).toList(),
                          ),
                        ),

                  const SizedBox(height: 32),

                  // ── Learning Tips ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Learning Tips",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LearningTipsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "View All",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryMid,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoadingTips
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryMid,
                            ),
                          )
                        : _tips.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'No learning tips available yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                children: [
                                  ..._tips.take(5).map((tip) {
                                    return LearningTipCard(
                                      title: tip.title,
                                      imageUrl: tip.imageUrl,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                LearningTipDetailScreen(
                                                  tip: tip,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(ChildProfile profile) {
    return PressableCard(
      onTap: () {
        final childId = profile.mongoId;
        if (childId == null || childId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Child id not available yet.')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectsScreen(
              initialChildId: childId,
              initialChildName: profile.name,
            ),
          ),
        );
      },
      child: Container(
        width: 290,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Left color bar
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: profile.leftBorderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(profile.imageUrl),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile.gradeAge,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Excellent Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: profile.tagColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            profile.tagText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Progress Bar
                    Row(
                      children: [
                        Text(
                          "Progress",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryMid,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${(profile.progress * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: profile.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        profile.barColor,
                      ),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
