import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _blobController;

  late Animation<double> _scaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _textSlideAnim;
  late Animation<double> _textFadeAnim;
  late Animation<double> _blobAnim;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _textSlideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _blobAnim = Tween<double>(begin: 0, end: 1).animate(_blobController);

    _logoController.forward().then((_) => _textController.forward());
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2, milliseconds: 500));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final hasToken = await auth.checkAuthStatus();
    if (!mounted) return;
    if (hasToken) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00A878), Color(0xFF00C896), Color(0xFF00E5AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative blobs
            AnimatedBuilder(
              animation: _blobAnim,
              builder: (_, __) {
                final v = _blobAnim.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -60 + v * 30,
                      right: -40 + v * 20,
                      child: _blob(size.width * 0.55, Colors.white.withOpacity(0.07)),
                    ),
                    Positioned(
                      bottom: size.height * 0.15 - v * 20,
                      left: -60 + v * 10,
                      child: _blob(size.width * 0.65, Colors.white.withOpacity(0.06)),
                    ),
                    Positioned(
                      top: size.height * 0.45 + v * 15,
                      right: size.width * 0.05,
                      child: _blob(size.width * 0.3, Colors.white.withOpacity(0.05)),
                    ),
                  ],
                );
              },
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _logoFadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Column(
                        children: [
                          // Outer glow ring
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.electric_bolt_rounded,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Text — slides up with delay
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _textSlideAnim.value),
                      child: Opacity(
                        opacity: _textFadeAnim.value,
                        child: Column(
                          children: [
                            Text(
                              AppStrings.appName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.tagline,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 72),

                  // Loader
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.8),
                      strokeWidth: 2.5,
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

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// Ignore unused import warning
// ignore: unused_import
const _ignore = math.pi;
