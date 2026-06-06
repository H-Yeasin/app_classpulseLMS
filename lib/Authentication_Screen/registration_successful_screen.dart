import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/providers/role_provider.dart';
import 'package:opalmer_education/core/theme/app_colors.dart';
import 'package:opalmer_education/custom_bottom_navigation_bar/main_shell.dart';
import 'package:opalmer_education/parent_role/parent_main_shell.dart';

class RegistrationSuccessfulScreen extends ConsumerWidget {
  const RegistrationSuccessfulScreen({super.key});

  static const String _teacherSubtitle =
      "Your profile has been set up. You're now ready to start teaching and connecting with your students.";
  static const String _parentSubtitle =
      "Your profile has been set up. You're now ready to start parenting and connecting with your child's";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final subtitle = role == UserRole.parent
        ? _parentSubtitle
        : _teacherSubtitle;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryMid,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(33, 72, 33, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        Column(
                          children: [
                            const _SuccessMark(),
                            const SizedBox(height: 52),
                            const Text(
                              "Registration Successful",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () =>
                                _continueToDashboard(context, role),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "CONTINUE",
                              style: TextStyle(
                                color: AppColors.primaryMid,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _continueToDashboard(BuildContext context, UserRole role) {
    final Widget dashboard = role == UserRole.parent
        ? const ParentMainShell()
        : const MainShell();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false,
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      height: 164,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CustomPaint(
            size: Size.square(164),
            painter: _ConfettiPainter(),
          ),
          CustomPaint(size: const Size.square(112), painter: _BadgePainter()),
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 62,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 7;
    final path = Path();
    const points = 28;

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + i * math.pi / points;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB979D3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BadgePainter oldDelegate) => false;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x55D8A8F0);
    final center = Offset(size.width / 2, size.height / 2);

    final dots = <Offset>[
      const Offset(20, 30),
      const Offset(142, 35),
      const Offset(28, 128),
      const Offset(134, 132),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, dot.dx < center.dx ? 2 : 1.7, paint);
    }

    final triangles = <Offset>[
      const Offset(52, 12),
      const Offset(124, 25),
      const Offset(132, 104),
      const Offset(50, 148),
    ];

    for (final triangle in triangles) {
      final path = Path()
        ..moveTo(triangle.dx, triangle.dy)
        ..lineTo(triangle.dx + 4, triangle.dy + 8)
        ..lineTo(triangle.dx - 4, triangle.dy + 8)
        ..close();
      canvas.drawPath(path, paint);
    }

    final flakes = <Rect>[
      const Rect.fromLTWH(86, 6, 8, 4),
      const Rect.fromLTWH(12, 54, 7, 4),
      const Rect.fromLTWH(144, 76, 6, 4),
      const Rect.fromLTWH(112, 144, 8, 4),
    ];

    for (final flake in flakes) {
      canvas.save();
      canvas.translate(flake.center.dx, flake.center.dy);
      canvas.rotate(0.25);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: flake.width,
          height: flake.height,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}
