import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/local_store.dart';
import 'domain/app_models.dart';
import 'presentation/app_controller.dart';
import 'presentation/splash_screen.dart';
import 'services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  final preferences = await SharedPreferences.getInstance();
  final notificationService = LocalNotificationService.instance;
  final controller = AppController(
    AppRepository(PreferencesLocalStore(preferences)),
    notificationService,
  );
  await controller.load();
  runApp(RafeeqApp(controller: controller));
}

class RafeeqApp extends StatelessWidget {
  const RafeeqApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AppScope(
    controller: controller,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, child) => MaterialApp(
        title: 'الرفيق الصالح',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: switch (controller.settings.themeMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const SplashScreen(),
      ),
    ),
  );
  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const seed = Color(0xff063b30);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        primary: dark
            ? const Color(0xff26a69a)
            : seed, // Lighter primary for dark mode
        secondary: const Color(0xff80cbc4),
      ),
      fontFamily: 'NotoSerif',
      scaffoldBackgroundColor: dark
          ? const Color(0xff0a1a15)
          : const Color(0xfff4f9f8),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? const Color(0xff162b25) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(height: 72),
    );
  }
}
