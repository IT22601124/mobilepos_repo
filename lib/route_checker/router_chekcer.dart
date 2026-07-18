import 'package:go_router/go_router.dart';
import 'package:mpos/screens/auth_screens/login_screen.dart';
import 'package:mpos/screens/auth_screens/register_screen.dart';
import 'package:mpos/screens/onboarding_screen/onboarding_screen.dart';
import 'package:mpos/screens/splash_screen/splash_screen.dart';
import 'package:mpos/screens/overview/dashboard_screen.dart';

import '../screens/navigation_menu/navigation_bar.dart';
import '../screens/pos_management_screen/pos_management_screen.dart';
import '../screens/pos_screen/pos_payment_screen.dart';
import '../screens/pos_screen/pos_payment_success_screen.dart';
import '../screens/pos_screen/pos_terminal_screen.dart';
// import '../screens/settings/printing_options_screen.dart';
import '../screens/store_management/store_management_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const NovaSplashSelector(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const NovaLoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const NovaCreateAccountScreen(),
    ),
    GoRoute(
      path: '/mainNavigation',
      builder: (context, state) => const MyHomePage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashBaordScrren(),
    ),
    GoRoute(
      path: '/pos_terminal',
      builder: (context, state) => const PosTerminalScreen(),
    ),
    GoRoute(
      path: '/pos_payment',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        final cartData = (data['cart'] as List?) ?? const [];

        return PosPaymentScreen(
          subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
          discount: (data['discount'] as num?)?.toDouble() ?? 0,
          tax: (data['tax'] as num?)?.toDouble() ?? 0,
          total: (data['total'] as num?)?.toDouble() ?? 0,
          paymentMethod: data['paymentMethod']?.toString() ?? 'Cash',
          cart: List<Map<String, dynamic>>.from(cartData),
        );
      },
    ),
    GoRoute(
      path: '/pos-management',
      builder: (context, state) => const PosManagementScreen(),
    ),
    // GoRoute(
    //   path: '/printing-options',
    //   builder: (context, state) => const PrintingOptionsScreen(),
    // ),
    GoRoute(
      path: '/pos-payment-success',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        final cartData = (data['cart'] as List?) ?? const [];
        final storeProfile =
            data['storeProfile'] as Map<String, dynamic>? ?? {};

        return PosPaymentSuccessScreen(
          saleNo: data['saleNo']?.toString() ?? 'POS-DEMO',
          paymentMethod: data['paymentMethod']?.toString() ?? 'Cash',
          subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
          discount: (data['discount'] as num?)?.toDouble() ?? 0,
          tax: (data['tax'] as num?)?.toDouble() ?? 0,
          total: (data['total'] as num?)?.toDouble() ?? 0,
          paid: (data['paid'] as num?)?.toDouble() ?? 0,
          change: (data['change'] as num?)?.toDouble() ?? 0,
          creditAmount: (data['creditAmount'] as num?)?.toDouble() ?? 0,
          customerName: data['customerName']?.toString() ?? 'Walk-in customer',
          cart: List<Map<String, dynamic>>.from(cartData),
          storeName: storeProfile['store_name']?.toString() ?? 'NOVA POS',
          receiptFooter:
              storeProfile['receipt_footer']?.toString() ?? 'Thank you!',
          currencyCode: storeProfile['currency_code']?.toString() ?? 'LKR',
          logoUrl: _logoUrl(storeProfile),
        );
      },
    ),
    GoRoute(
      path: '/store-management',
      builder: (context, state) => const StoreManagementScreen(),
    ),
  ],
);

String _logoUrl(Map<String, dynamic> profile) {
  final logoUrl = profile['logo_url']?.toString() ?? '';
  final logo = profile['logo']?.toString() ?? '';

  if (logoUrl.isNotEmpty) {
    return logoUrl.replaceFirst(
      'http://localhost:5000',
      'http://10.0.2.2:5000',
    );
  }
  if (logo.startsWith('http')) {
    return logo.replaceFirst('http://localhost:5000', 'http://10.0.2.2:5000');
  }
  if (logo.startsWith('/uploads')) return 'http://10.0.2.2:5000$logo';

  return '';
}
