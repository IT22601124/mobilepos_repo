import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:mpos/provider/splash_provider/splash_provider.dart';
import 'package:mpos/provider/theme_provider/theme_provider.dart';
import 'package:mpos/route_checker/router_chekcer.dart';
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
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SplashProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: NovaPOSApp(),
    )
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
    return  Consumer<ThemeProvider>(
      builder:(context,_themeProvider,child)=>
      MaterialApp.router(
        debugShowCheckedModeBanner:false,
        title: 'NovaPOS',
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: _themeProvider.isDarkMode == false  ? ThemeMode.light : ThemeMode.dark, // Controlled by state
        routerConfig: router,
      ),
    );
  }
}
