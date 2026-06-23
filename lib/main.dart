import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/rider_order_provider.dart';
import 'screens/active_order_screen.dart';
import 'screens/available_orders_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/rider_login_screen.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const RiderApp());

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RiderOrderProvider()),
      ],
      child: MaterialApp(
        title: 'Rider App',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: Routes.splash,
        // Named routes. ActiveOrderScreen reads its Order from
        // ModalRoute.of(context)!.settings.arguments.
        routes: {
          Routes.splash: (_) => const SplashScreen(),
          Routes.login: (_) => const RiderLoginScreen(),
          Routes.available: (_) => const AvailableOrdersScreen(),
          Routes.activeOrder: (_) => const ActiveOrderScreen(),
          Routes.history: (_) => const OrderHistoryScreen(),
        },
      ),
    );
  }
}
