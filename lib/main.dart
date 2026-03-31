import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'screens/splash_screen.dart';
import 'services/achievements_service.dart';
import 'services/ai_analysis_service.dart';
import 'services/connectivity_service.dart';
import 'services/exp_service.dart';
import 'services/locale_service.dart';
import 'services/nutrition_service.dart';
import 'services/theme_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Workmanager().initialize(workmanagerCallback, isInDebugMode: false);
  await initNotifications();
  await LocaleService.instance.init();
  await ThemeService.instance.init();
  await ExpService.instance.init();
  await AchievementsService.instance.init();
  await NutritionService.instance.init();
  ConnectivityService.instance.startMonitoring();

  runApp(const GymTrackerApp());
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.instance.langCode,
      builder: (_, __, ___) => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.instance.mode,
        builder: (_, themeMode, ___) => MaterialApp(
          title: 'GYM Tracker',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
