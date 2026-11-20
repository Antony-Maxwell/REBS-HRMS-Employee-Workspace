
import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _glowController;
  late final AnimationController _loadingController;

  Timer? _timer;

  static const Color navy = Color(0xFF030B2B);
  static const Color cyan = Color(0xFF16DDF5);
  static const Color purple = Color(0xFF843BFF);

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoController.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoController.dispose();
    _glowController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -120,
            left: -120,
            child: _backgroundGlow(cyan),
          ),

          Positioned(
            bottom: -150,
            right: -120,
            child: _backgroundGlow(purple),
          ),

          // Decorative bottom wave
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WavePainter(),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _logoController,
                  curve: Curves.easeIn,
                ),
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _logoController,
                    curve: Curves.easeOutBack,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),

                      const SizedBox(height: 28),

                      // App name
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                          ),
                          children: [
                            TextSpan(
                              text: 'REBS ',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'HRMS',
                              style: TextStyle(
                                color: Color(0xFF7B83FF),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tagline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _gradientLine(),
                          const SizedBox(width: 14),
                          const Text(
                            'Employee Workspace',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _gradientLine(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading indicator
          Positioned(
            bottom: 75,
            left: 0,
            right: 0,
            child: Center(
              child: RotationTransition(
                turns: _loadingController,
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(cyan),
                    backgroundColor: Color(0xFF202A50),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple gradient employee logo
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = 0.12 + (_glowController.value * 0.12);

        return Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF08143D),
            border: Border.all(
              width: 2.5,
              color: const Color(0xFF438CFF),
            ),
            boxShadow: [
              BoxShadow(
                color: cyan.withValues(alpha: glow),
                blurRadius: 35,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: purple.withValues(alpha: glow),
                blurRadius: 55,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [cyan, purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              child: const Icon(
                Icons.groups_rounded,
                size: 110,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _backgroundGlow(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _gradientLine() {
    return Container(
      width: 35,
      height: 1.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [cyan, purple],
        ),
      ),
    );
  }
}

// Simple decorative background wave
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF102C89),
          Color(0xFF843BFF),
        ],
      ).createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(size.width, size.height * 0.73)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.80,
        size.width * 0.65,
        size.height * 0.95,
        size.width * 0.20,
        size.height,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}
