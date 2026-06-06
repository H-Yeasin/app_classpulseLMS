import 'package:flutter/material.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';

class ChildProfile {
  final String? relationId;
  final String? mongoId; // Mongo ObjectId for API endpoints that use findById
  final String? studentId;
  final String name;
  final String gradeAge;
  final double progress;
  final String tagText;
  final Color tagColor;
  final Color barColor;
  final Color leftBorderColor;
  final String imageUrl;

  const ChildProfile({
    this.relationId,
    this.mongoId,
    this.studentId,
    required this.name,
    required this.gradeAge,
    required this.progress,
    required this.tagText,
    required this.tagColor,
    required this.barColor,
    required this.leftBorderColor,
    required this.imageUrl,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json, {String? relationId}) {
    // Default dummy values for missing metrics
    double prog = (json['progress'] ?? 0).toDouble();
    String tag = json['tagText'] ?? "Evaluating";
    
    // Auto-map colors based on tagText
    Color tColor = const Color(0xFF4CB07D);
    Color lBorderColor = const Color(0xFF4CB07D);
    
    if (tag == "Excellent") {
      tColor = const Color(0xFF4CB07D);
      lBorderColor = const Color(0xFF4CB07D);
    } else if (tag == "Good") {
      tColor = const Color(0xFFF4B84F);
      lBorderColor = const Color(0xFFF4B84F);
    } else if (tag == "Fair") {
      tColor = const Color(0xFFE91E63);
      lBorderColor = const Color(0xFFE91E63);
    } else {
      tColor = Colors.grey;
      lBorderColor = Colors.grey;
    }

    return ChildProfile(
      relationId: relationId,
      mongoId: json['_id']?.toString(),
      studentId: json['Id'] ?? json['_id'],
      name: json['username'] ?? 'Unknown',
      gradeAge: 'Grade ${json['gradeLevel'] ?? 'N/A'} - Age ${json['age'] ?? 'N/A'}',
      progress: prog,
      tagText: tag,
      tagColor: tColor,
      barColor: AppColors.primaryMid,
      leftBorderColor: lBorderColor,
      imageUrl: (json['avatar'] != null && json['avatar']['url'] != null && json['avatar']['url'].toString().isNotEmpty)
          ? json['avatar']['url']
          : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
    );
  }
}

// Dummy data to use across screens
final List<ChildProfile> mockChildProfiles = [
  ChildProfile(
    name: "Mia Johnson",
    gradeAge: "Grade 6 - Age 12",
    progress: 0.93,
    tagText: "Excellent",
    tagColor: const Color(0xFF4CB07D),
    barColor: AppColors.primaryMid,
    leftBorderColor: const Color(0xFF4CB07D),
    imageUrl:
        "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&w=150&q=80",
  ),
  ChildProfile(
    name: "Alex Johnson",
    gradeAge: "Grade 4 - Age 10",
    progress: 0.85,
    tagText: "Good",
    tagColor: const Color(0xFFF4B84F),
    barColor: AppColors.primaryMid,
    leftBorderColor: const Color(0xFFF4B84F),
    imageUrl:
        "https://images.unsplash.com/photo-1503919545889-aef636e10ad4?auto=format&fit=crop&w=150&q=80",
  ),
  ChildProfile(
    name: "Mia Johnson",
    gradeAge: "Grade 6 - Age 12",
    progress: 0.93,
    tagText: "Excellent",
    tagColor: const Color(0xFF4CB07D),
    barColor: AppColors.primaryMid,
    leftBorderColor: const Color(0xFF3892A8),
    imageUrl:
        "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&w=150&q=80",
  ),
];
