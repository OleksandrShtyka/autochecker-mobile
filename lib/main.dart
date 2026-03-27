import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';
import 'services/ai_analysis_service.dart';
import 'services/api_service.dart';
import 'services/locale_service.dart';
import 'services/lock_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Workmanager().initialize(workmanagerCallback, isInDebugMode: false);
  await initNotifications();
  await LocaleService.instance.init();

  final hasSession = await ApiService.instance.checkSession();
  final hasPin = hasSession && await LockService.instance.hasPin();

  runApp(AutoCheckerApp(startAuthenticated: hasSession, showLock: hasPin));
}

class AutoCheckerApp extends StatelessWidget {
  final bool startAuthenticated;
  final bool showLock;

  const AutoCheckerApp({super.key, required this.startAuthenticated, required this.showLock});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!startAuthenticated) {
      home = const LoginScreen();
    } else if (showLock) {
      home = const LockScreen(destination: HomeScreen());
    } else {
      home = const HomeScreen();
    }

    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.instance.langCode,
      builder: (_, __, ___) => MaterialApp(
        title: 'AutoChecker',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: home,
      ),
    );
  }
}
