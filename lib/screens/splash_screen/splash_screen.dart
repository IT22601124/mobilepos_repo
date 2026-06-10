import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpos/app_theme/app_theme.dart';
import 'package:mpos/resources/color_resources.dart'; // Import color resources

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

  @override
  void initState() {
    super.initState();

    // 1. Logo Entry Animations (Fade & Scale)
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

    _animationController.forward();

    // 2. Linear Loading Progress Simulation
    _startProgressLoader();
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
          _navigateToLogin();
        }
      });
    });
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Routing Successful'),
            content: Text('Auto-redirecting to PIN Login Screen...'),
          ),
        );
      }
    });
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
      backgroundColor:Theme.of(context).colorScheme.background,
      body: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                      'Smart Business, Simplified Payments',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ColorResources.textSecondary, // Using ColorResources
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Progress Indicator Area (Custom Gradient Container)
                    Container(
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
                                    ColorResources.primary,     // Using ColorResources
                                    ColorResources.secondary,   // Using ColorResources
                                    ColorResources.accent,      // Using ColorResources
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ColorResources.textSecondary, // Using ColorResources
                      ),
                    ),
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

// Custom Painter Logo
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
      child: Center(
        child: SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(
            painter: _LogoPainter(),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint Outer Terminal Shell
    final shellPaint = Paint()
      ..color = ColorResources.primary // Using ColorResources
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeJoin = StrokeJoin.round;

    final shellRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(15, 8, 50, 64),
      const Radius.circular(10),
    );
    canvas.drawRRect(shellRect, shellPaint);

    // 2. Paint Card Slot
    final slotPaint = Paint()
      ..color = ColorResources.primary // Using ColorResources
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(22, 20), const Offset(58, 20), slotPaint);

    // 3. Paint Receipt Slot
    final receiptPaint = Paint()
      ..color = ColorResources.primary // Using ColorResources
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(30, 14), const Offset(50, 14), receiptPaint);

    // 4. Paint Lightning Bolt
    final boltPaint = Paint()
      ..color = ColorResources.secondary // Using ColorResources
      ..style = PaintingStyle.fill;

    final boltPath = Path()
      ..moveTo(40, 32)
      ..lineTo(48, 44)
      ..lineTo(38, 44)
      ..lineTo(42, 56)
      ..lineTo(32, 44)
      ..lineTo(42, 44)
      ..close();

    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}