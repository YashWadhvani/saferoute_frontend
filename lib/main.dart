// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/route_provider.dart';
import 'providers/sos_provider.dart';
import 'providers/report_provider.dart';
import 'providers/safety_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/heatmap/heatmap_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize API client
  ApiClient.initialize();

  // Initialize auth and check if user is logged in
  runApp(const SafeRouteApp());
}

class SafeRouteApp extends StatelessWidget {
  const SafeRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, auth, user) => user ?? UserProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RouteProvider>(
          create: (_) => RouteProvider(),
          update: (_, auth, route) => route ?? RouteProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SOSProvider>(
          create: (_) => SOSProvider(),
          update: (_, auth, sos) => sos ?? SOSProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReportProvider>(
          create: (_) => ReportProvider(),
          update: (_, auth, report) => report ?? ReportProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SafetyProvider>(
          create: (_) => SafetyProvider(),
          update: (_, auth, safety) => safety ?? SafetyProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'SafeRoute',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/heatmap': (_) => const HeatmapScreen(),
          '/reports': (_) => const ReportsScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
