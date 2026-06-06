import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/core/widgets/animated_wave_header.dart';
import 'package:opalmer_education/core/widgets/pressable_card.dart';
import 'package:opalmer_education/notification/notification.dart';
import 'package:opalmer_education/parent_role/ChildsProfilesScreen/add_child.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/subjects_screen.dart';
import 'package:opalmer_education/parent_role/ChildsProfilesScreen/models/child_profile.dart';

class ChildsProfilesScreen extends StatefulWidget {
  const ChildsProfilesScreen({super.key});

  @override
  State<ChildsProfilesScreen> createState() => _ChildsProfilesScreenState();
}

class _ChildsProfilesScreenState extends State<ChildsProfilesScreen> {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();
  List<ChildProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
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
      debugPrint("Failed to load profiles: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRelation(String relationId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Child'),
        content: const Text(
          'Are you sure you want to remove this child from your dashboard?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.delete('/parent/child/$relationId');
      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Child relation removed.')),
          );
        }
        _loadProfiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove child: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(color: AppColors.primaryMid),
          ),
          Column(
            children: [
              // ── Wave Header ──
              Stack(
                children: [
                  const AnimatedWaveHeader(height: 140),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              if (Navigator.of(context).canPop())
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              const Text(
                                "Child's Profiles",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 16),
              // ── Profiles List ──
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryMid,
                        ),
                      )
                    : _profiles.isEmpty
                    ? const Center(
                        child: Text(
                          "No children added yet.\nPress + to add a child.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        children: _profiles.map((profile) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildProfileCard(
                              context: context,
                              profile: profile,
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'child_profiles_fab',
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => const AddChildDialog(),
          );
          if (result == true) {
            _loadProfiles();
          }
        },
        backgroundColor: AppColors.primaryMid,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required ChildProfile profile,
  }) {
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
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
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
            // Colored Left Border strip
            Container(
              width: 8,
              height: 120,
              decoration: BoxDecoration(
                color: profile.leftBorderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
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
                                  fontSize: 16,
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
                        // Top Right Tag
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: profile.tagColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                profile.tagText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (profile.relationId != null) {
                                  _deleteRelation(profile.relationId!);
                                }
                              },
                              child: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress Bar
                    Row(
                      children: [
                        Text(
                          "Progress",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${(profile.progress * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryMid,
                            fontWeight: FontWeight.w600,
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
