import 'package:flutter/material.dart';
import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:mpos/provider/splash_provider/splash_provider.dart';
import 'package:mpos/provider/theme_provider/theme_provider.dart';
import 'package:mpos/route_checker/router_chekcer.dart';
import 'package:provider/provider.dart';
import 'app_theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const NovaPOSApp(),
    ),
  );
}

class NovaPOSApp extends StatefulWidget {
  const NovaPOSApp({super.key});

  @override
  State<NovaPOSApp> createState() => _NovaPOSAppState();
}

class _NovaPOSAppState extends State<NovaPOSApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => MaterialApp.router(
        debugShowCheckedModeBanner:false,
        title: 'NovaPOS',
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: themeProvider.themeMode,
        routerConfig: router,
      ),
    );
  }
}
