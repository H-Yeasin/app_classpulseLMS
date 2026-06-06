import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/parent_role/ChildsProfilesScreen/models/child_profile.dart';
import 'package:opalmer_education/parent_role/SubjectsScreen/models/subject.dart'
    hide ChildProfile;

class AddChildDialog extends StatefulWidget {
  const AddChildDialog({super.key});

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ChildProfile> _searchResults = [];
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();
  bool _isLoading = false;

  void _onSearchChanged(String query) async {
    if (query.isNotEmpty) {
      if (query.length > 2) {
        setState(() {
          _isLoading = true;
        });
        try {
          final response = await _apiClient.get(
            '/users/search-student',
            queryParameters: {'Id': query},
          );
          if (response.data['success'] == true) {
            final List students = response.data['data'] ?? [];
            if (mounted) {
              setState(() {
                _searchResults = students
                    .map((s) => ChildProfile.fromJson(s))
                    .toList();
              });
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _searchResults = [];
            });
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _addRelation(ChildProfile profile) async {
    try {
      String? userData = await _storage.getUserData();
      if (userData == null) return;
      final userMap = jsonDecode(userData);
      final parentId = userMap['id'] ?? userMap['_id'];

      final response = await _apiClient.post(
        '/parent/child',
        data: {'parentId': parentId, 'childId': profile.studentId},
      );

      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Child added successfully.")),
          );
          Navigator.of(context).pop(true);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String errMsg = "Failed to add child.";
        if (e.response?.statusCode == 409) {
          errMsg = "This child is already added to your profile.";
        } else if (e.response?.data != null &&
            e.response?.data['message'] != null) {
          errMsg = e.response?.data['message'];
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errMsg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${e.toString()}")));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildContentBox(context),
    );
  }

  Widget _buildContentBox(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            top: 60,
            right: 20,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter Child's Id",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Child's Id",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Enter your child's id",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.school_outlined, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primaryMid),
                  ),
                ),
              ),

              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryMid),
                ),
              ],

              // Search results area
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final profile = _searchResults[index];
                      return _buildSearchResultItem(profile);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 32),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primaryMid),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(
                          color: AppColors.primaryMid,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Action when OK is pressed (API integration later)
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMid,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Overlapping top circular icon
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.person_search_outlined,
                  size: 38,
                  color: AppColors.primaryMid,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(ChildProfile profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 60,
            decoration: BoxDecoration(
              color: profile.leftBorderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(profile.imageUrl),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profile.gradeAge,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () {
                _addRelation(profile);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMid,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                "Add",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
