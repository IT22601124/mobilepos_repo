import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/app_theme/app_theme.dart';
import 'package:mpos/resources/color_resources.dart';
import 'package:provider/provider.dart';

import 'package:mpos/provider/onboarding_provider.dart';
import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../provider/splash_provider/splash_provider.dart'; // Import color resources

class NovaSplashSelector extends StatefulWidget {
  const NovaSplashSelector({super.key});

  @override
  State<NovaSplashSelector> createState() => _NovaSplashSelectorState();
}

class _NovaSplashSelectorState extends State<NovaSplashSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  double _loadingProgress = 0.0;
  String _statusText = 'Initializing security node...';
  Timer? _progressTimer;
  String? errorMessage;
  static const _onboardingKey = 'has_completed_onboarding';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _loadingData();
  }

  void _loadingData() async {
    _animationController.forward();
    _startProgressLoader();
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    try {
      Response response = await splashProvider.verifyConnection();
      if (response.statusCode != 200) {
        throw Exception('Failed to verify connection: ${response.statusCode}');
      }
    } catch (e) {
      print('Continuing in offline demo mode: $e');
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool(_onboardingKey) ?? false;

    if (!hasCompletedOnboarding) {
      context.go('/onboarding');
      return;
    }

    final isTokenValid = await authProvider.verifyStoredToken();
    if (!mounted) return;

    if (isTokenValid) {
      context.go('/mainNavigation');
    } else {
      _navigateToLogin();
    }
  }

  void _startProgressLoader() {
    const totalDuration = Duration(milliseconds: 2400);
    const interval = Duration(milliseconds: 30);
    final totalSteps = totalDuration.inMilliseconds / interval.inMilliseconds;
    final increment = 1.0 / totalSteps;

    _progressTimer = Timer.periodic(interval, (timer) {
      if (!mounted) return;

      setState(() {
        _loadingProgress += increment;

        // Update status subtext dynamically based on progress
        if (_loadingProgress > 0.35 && _loadingProgress < 0.70) {
          _statusText = 'Connecting terminal gateway...';
        } else if (_loadingProgress >= 0.70 && _loadingProgress < 0.95) {
          _statusText = 'Decrypting merchant token...';
        } else if (_loadingProgress >= 1.0) {
          _loadingProgress = 1.0;
          _statusText = 'Terminal Authorized!';
          _progressTimer?.cancel();

          // 3. Route to Login/PIN Screen
        }
      });
    });
  }

  void _navigateToLogin() {
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),

              // Animated Logo & Title Area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: const NovaPOSLogo(),
                    ),
                    const SizedBox(height: 32),

                    // Brand Title
                    Text.rich(
                      TextSpan(
                        text: 'NOVA',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 6,
                        ),
                        children: [
                          TextSpan(
                            text: 'POS',
                            style: TextStyle(
                              color: AppThemes.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      errorMessage ?? 'Smart Business, Simplified Payments',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ColorResources.textSecondary, // Using ColorResources
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Progress Indicator Area (Custom Gradient Container)
                    errorMessage == null
                        ? Container(
                            width: 200,
                            height: 6,
                            decoration: BoxDecoration(
                              color: ColorResources.border, // Using ColorResources
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: _loadingProgress.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: const LinearGradient(
                                        colors: [
                                          ColorResources.primary,
                                          ColorResources.secondary,
                                          ColorResources.accent,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(),
                    const SizedBox(height: 12),
                    errorMessage == null
                        ? Text(
                            _statusText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ColorResources.textSecondary,
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),

              // Footer Security Badge
              Text(
                'PCI-DSS COMPLIANT • SECURE CONNECTION',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: ColorResources.textSecondary, // Using ColorResources
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// App logo
class NovaPOSLogo extends StatelessWidget {
  const NovaPOSLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorResources.primary.withOpacity(0.08), // Using ColorResources
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/image/logo/novapos.png',
          fit: BoxFit.contain,
          semanticLabel: 'NovaPOS logo',
        ),
      ),
    );
  }
}

