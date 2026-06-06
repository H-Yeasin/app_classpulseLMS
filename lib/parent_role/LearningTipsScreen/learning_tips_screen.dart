import 'package:flutter/material.dart';
import 'package:opalmer_education/core/widgets/learning_tip_card.dart';
import 'package:opalmer_education/parent_role/LearningTipsScreen/models/learning_tip.dart';
import 'package:opalmer_education/parent_role/LearningTipsScreen/learning_tip_detail_screen.dart';
import 'package:opalmer_education/parent_role/services/learning_tips_service.dart';

class LearningTipsScreen extends StatefulWidget {
  const LearningTipsScreen({super.key});

  @override
  State<LearningTipsScreen> createState() => _LearningTipsScreenState();
}

class _LearningTipsScreenState extends State<LearningTipsScreen> {
  List<LearningTip> _tips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final tips = await LearningTipsService.instance.fetch(force: true);
      if (mounted) {
        setState(() {
          _tips = tips;
        });
      }
    } catch (e) {
      debugPrint('Failed to load learning tips: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load learning tips: $e')),
        );
      }
    } finally {
      if (mounted) {
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
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header matching design exactly
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF871DAD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Learning Tips",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tips.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'No learning tips available yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTips,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            itemCount: _tips.length,
                            itemBuilder: (context, index) {
                              final tip = _tips[index];
                              return LearningTipCard(
                                title: tip.title,
                                imageUrl: tip.imageUrl,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LearningTipDetailScreen(tip: tip),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
