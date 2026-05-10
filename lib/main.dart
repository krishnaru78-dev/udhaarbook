import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/app_theme.dart';
import 'utils/language_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AdMob
  await MobileAds.instance.initialize();
  
  // Check first launch
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
  final language = prefs.getString('language') ?? 'en';
  
  runApp(UdhaarBookApp(
    isFirstLaunch: isFirstLaunch,
    language: language,
  ));
}

class UdhaarBookApp extends StatefulWidget {
  final bool isFirstLaunch;
  final String language;
  
  const UdhaarBookApp({
    super.key,
    required this.isFirstLaunch,
    required this.language,
  });

  @override
  State<UdhaarBookApp> createState() => _UdhaarBookAppState();
}

class _UdhaarBookAppState extends State<UdhaarBookApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UdhaarBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(isFirstLaunch: widget.isFirstLaunch),
    );
  }
}