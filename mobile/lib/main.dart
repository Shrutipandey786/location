import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "providers/auth_provider.dart";
import "providers/conversation_provider.dart";
import "providers/dashboard_provider.dart";
import "screens/splash_screen.dart";
import "theme/app_theme.dart";

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
      ],
      child: const LocationTrackerApp(),
    ),
  );
}

class LocationTrackerApp extends StatefulWidget {
  const LocationTrackerApp({super.key});

  @override
  State<LocationTrackerApp> createState() => _LocationTrackerAppState();
}

class _LocationTrackerAppState extends State<LocationTrackerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Location Service Tracker",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const SplashScreen(),
    );
  }
}
