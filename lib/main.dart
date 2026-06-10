import 'package:flutter/material.dart';
import 'package:mpos/provider/theme_provider/theme_provider.dart';
import 'package:mpos/screens/auth_screens/login_screen.dart';
import 'package:mpos/screens/navigation_menu/navigation_bar.dart';
import 'package:mpos/screens/splash_screen/splash_screen.dart';
import 'package:provider/provider.dart';
import 'app_theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
      MaterialApp(
        debugShowCheckedModeBanner:false,
        title: 'NovaPOS',
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: _themeProvider.isDarkMode == false  ? ThemeMode.light : ThemeMode.dark, // Controlled by state
        home: MyHomePage(title: 's',)
      ),
    );
  }
}