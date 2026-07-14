import 'package:flutter_test/flutter_test.dart';
import 'package:mpos/main.dart';
import 'package:mpos/provider/auth_provider/auth_provider.dart';
import 'package:mpos/provider/splash_provider/splash_provider.dart';
import 'package:mpos/provider/theme_provider/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App renders splash shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SplashProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const NovaPOSApp(),
      ),
    );

    expect(find.textContaining('NOVA'), findsWidgets);
  });
}
