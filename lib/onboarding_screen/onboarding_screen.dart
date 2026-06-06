import 'package:flutter/material.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/core/widgets/primary_button.dart';
import '../user_role_screen/user_role_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  late AnimationController _imageController;
  late AnimationController _textController;
  late AnimationController _cardController;

  late Animation<Offset> _imageSlide;
  late Animation<double> _imageFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "text": "Growth",
      "image":
          "assets/images/onbording_background_image/onbording_background_image_1.jpg",
      "bgColor": const Color(0xFF9E92C4),
      "imageBottom": 200.0,
      "imageAlignment": Alignment.topCenter,
      "textTop": 180.0,
      "textRight": 20.0,
      "textFontSize": 50.0,
    },
    {
      "text": "Learning",
      "image":
          "assets/images/onbording_background_image/onbording_background_image_2.png",
      "bgColor": const Color(0xFF094988),
      "imageBottom": -300.0,
      "imageAlignment": Alignment.topCenter,
      "textTop": 180.0,
      "textRight": 20.0,
      "textFontSize": 50.0,
    },
    {
      "text": "Real Success",
      "image":
          "assets/images/onbording_background_image/onbording_background_image_3.png",
      "bgColor": const Color(0xFFFFBE02),
      "imageBottom": -50.0,
      "imageAlignment": Alignment.topRight,
      "textTop": 180.0,
      "textRight": 20.0,
      "textFontSize": 45.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _playAnimations();
  }

  void _setupAnimations() {
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _imageSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _imageController, curve: Curves.easeOut));

    _imageFade = CurvedAnimation(
      parent: _imageController,
      curve: Curves.easeIn,
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeIn);
  }

  void _playAnimations() {
    _imageController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _textController.forward(from: 0);
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _cardController.forward(from: 0);
    });
  }

  void _resetAndPlay() {
    _imageController.reset();
    _textController.reset();
    _cardController.reset();
    _playAnimations();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── PageView background ──
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
              _resetAndPlay();
            },
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                color: onboardingData[index]["bgColor"],
                child: Stack(
                  children: [
                    // Background Image — animated
                    Positioned(
                      bottom: onboardingData[index]["imageBottom"],
                      left: 0,
                      right: 0,
                      top: 0,
                      child: FadeTransition(
                        opacity: _imageFade,
                        child: SlideTransition(
                          position: _imageSlide,
                          child: Image.asset(
                            onboardingData[index]["image"]!,
                            fit: BoxFit.cover,
                            alignment: onboardingData[index]["imageAlignment"],
                          ),
                        ),
                      ),
                    ),

                    // Rotated Text — animated
                    Positioned(
                      top: onboardingData[index]["textTop"],
                      right: onboardingData[index]["textRight"],
                      child: FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              onboardingData[index]["text"]!,
                              style: TextStyle(
                                fontSize: onboardingData[index]["textFontSize"],
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Top Logo ──
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primaryMid,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/onbording_logo.png',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Card — animated ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          onboardingData.length,
                          (index) => buildDot(index: index),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        "Empower Learning",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Manage classes, track progress, and stay\nconnected all in one powerful platform.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      const Spacer(),

                      // Button
                      PrimaryButton(
                        text: _currentPage == onboardingData.length - 1
                            ? "GET STARTED"
                            : "CONTINUE",
                        onPressed: () {
                          if (_currentPage == onboardingData.length - 1) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const UserRoleScreen(),
                              ),
                            );
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 28 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primaryMid
            : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
