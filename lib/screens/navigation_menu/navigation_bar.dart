import 'dart:async';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:circular_reveal_animation/circular_reveal_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:mpos/provider/theme_provider/theme_provider.dart';
import 'package:mpos/screens/overview/dashboard_screen.dart';
import 'package:mpos/utils/app_back_scope.dart';
import 'package:provider/provider.dart';

import '../pos_management_screen/pos_management_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final autoSizeGroup = AutoSizeGroup();
  var _bottomNavIndex = 0; //default index of a first screen

  late AnimationController _fabAnimationController;
  late AnimationController _borderRadiusAnimationController;
  late Animation<double> fabAnimation;
  late Animation<double> borderRadiusAnimation;
  late CurvedAnimation fabCurve;
  late CurvedAnimation borderRadiusCurve;
  late AnimationController _hideBottomBarAnimationController;

  final iconList = <IconData>[
    Icons.dashboard_rounded,
    Icons.inventory_2_rounded,
    Icons.settings_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _borderRadiusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    fabCurve = CurvedAnimation(
      parent: _fabAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );
    borderRadiusCurve = CurvedAnimation(
      parent: _borderRadiusAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
    );

    fabAnimation = Tween<double>(begin: 0, end: 1).animate(fabCurve);
    borderRadiusAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(borderRadiusCurve);

    _hideBottomBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    Future.delayed(
      const Duration(seconds: 1),
      () => _fabAnimationController.forward(),
    );
    Future.delayed(
      const Duration(seconds: 1),
      () => _borderRadiusAnimationController.forward(),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _borderRadiusAnimationController.dispose();
    _hideBottomBarAnimationController.dispose();
    super.dispose();
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.metrics.axis == Axis.vertical) {
      switch (notification.direction) {
        case ScrollDirection.forward:
          _hideBottomBarAnimationController.reverse();
          _fabAnimationController.forward(from: 0);
          break;
        case ScrollDirection.reverse:
          _hideBottomBarAnimationController.forward();
          _fabAnimationController.reverse(from: 1);
          break;
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Custom logic: Dark bar for Light Mode, Light bar for Dark Mode
    final navBarBgColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final navActiveColor = isDark ? colors.primary : colors.secondary;
    final navInactiveColor = isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.5);

    return AppBackScope(
      allowSystemPop: true,
      onBack: () {
        if (_bottomNavIndex != 0) {
          setState(() => _bottomNavIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBody: true,
        body: NotificationListener<ScrollNotification>(
          onNotification: onScrollNotification,
          child: _buildBodyScreen(_bottomNavIndex),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: colors.primary,
          shape: const CircleBorder(),
          child: Icon(Icons.point_of_sale, color: colors.onPrimary),
          onPressed: () {
            context.go('/pos_terminal');
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        height: 54,
        itemCount: iconList.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? navActiveColor : navInactiveColor;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconList[index],
                size: 22,
                color: color,
              ),
              const SizedBox(height: 3),
              Text(
                index == 0
                    ? 'Dashboard'
                    : index == 1
                        ? 'Management'
                        : index == 2
                            ? 'Settings'
                            : 'Profile',
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );
        },
        backgroundColor: navBarBgColor,
        activeIndex: _bottomNavIndex,
        splashColor: navActiveColor.withValues(alpha: 0.3),
        notchAndCornersAnimation: borderRadiusAnimation,
        splashSpeedInMilliseconds: 300,
        notchSmoothness: NotchSmoothness.softEdge,
        gapLocation: GapLocation.center,
        leftCornerRadius: 24,
        rightCornerRadius: 24,
        onTap: (index) {
          setState(() => _bottomNavIndex = index);
        },
        hideAnimationController: _hideBottomBarAnimationController,
      ),
      ),
    );
  }

  Widget _buildBodyScreen(int index) {
    switch (index) {
      case 0:
        return const DashBaordScrren();
      case 1:
        return const PosManagementScreen();
      case 2:
        return const SettingsScreen();
      case 3:
        return const ProfileScreen();

      default:
        return NavigationScreen(iconList[index]);
    }
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AppearanceSettingsCard(themeProvider: themeProvider),
            const _SettingsTile(
              icon: Icons.receipt_long,
              title: 'Receipt footer',
              subtitle: 'Thank you for shopping with NOVA POS',
              trailing: Icon(Icons.chevron_right),
            ),
            _SettingsTile(
              icon: Icons.print_outlined,
              title: 'Printing options',
              subtitle: 'Paper size, copies and automatic printing',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/printing-options'),
            ),
            const _SettingsTile(
              icon: Icons.payments_outlined,
              title: 'Payment methods',
              subtitle: 'Cash, card, credit and wallet enabled',
              trailing: Icon(Icons.chevron_right),
            ),
            const _SettingsTile(
              icon: Icons.security_outlined,
              title: 'Security',
              subtitle: 'Demo mode with local protected session',
              trailing: Icon(Icons.chevron_right),
            ),
            _SettingsTile(
              icon: Icons.storefront,
              title: 'Store Management',
              subtitle: 'Profile, receipt identity and logo',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/store-management'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName =
        context.watch<AuthProvider>().currentUserName ?? 'Super Admin';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _settingsDecoration(context),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF2F80ED),
                    child: Text(
                      userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Merchant administrator',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.storefront,
              title: 'Store',
              subtitle: 'Profile, receipt identity and logo',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/store-management'),
            ),
            const _SettingsTile(
              icon: Icons.phone_android,
              title: 'Terminal',
              subtitle: 'Mobile POS terminal active',
              trailing: Icon(Icons.verified, color: Color(0xFF23C16B)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSettingsCard extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _AppearanceSettingsCard({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _settingsDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.dark_mode_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appearance',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Use system, light, or dark mode',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined, size: 18),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (selection) {
                themeProvider.setThemeMode(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _settingsDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Theme.of(context).dividerColor),
  );
}

class NavigationScreen extends StatefulWidget {
  final IconData iconData;

  const NavigationScreen(this.iconData, {super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> animation;

  @override
  void didUpdateWidget(NavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconData != widget.iconData) {
      _startAnimation();
    }
  }

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    super.initState();
  }

  void _startAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        children: [
          const SizedBox(height: 64),
          Center(
            child: CircularRevealAnimation(
              animation: animation,
              centerOffset: Offset(80, 80),
              maxRadius: MediaQuery.of(context).size.longestSide * 1.1,
              child: Icon(widget.iconData, color: Colors.amber, size: 160),
            ),
          ),
        ],
      ),
    );
  }
}
