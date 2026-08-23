import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:mpos/provider/connectivity_provider.dart';
import 'package:mpos/provider/onboarding_provider.dart';
import 'package:mpos/provider/printing_provider.dart';
import 'package:mpos/provider/splash_provider/splash_provider.dart';
import 'package:mpos/provider/sync_provider.dart';
import 'package:mpos/provider/theme_provider/theme_provider.dart';
import 'package:mpos/provider/app_settings_provider.dart';
import 'package:mpos/route_checker/router_chekcer.dart';
import 'package:mpos/provider/language_provider.dart';
import 'package:mpos/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app_theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/notification_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Background notification: ${message.messageId}');
}

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler once
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // This handles permissions, foreground listeners, and local notifications
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PrintingProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
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
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) => MaterialApp.router(
        debugShowCheckedModeBanner:false,
        title: 'NovaPOS',
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: themeProvider.themeMode,
        locale: languageProvider.locale,
        supportedLocales: const [
          Locale('en'),
          Locale('si'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}
