import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/ai_assistant_controller.dart';
import 'controllers/network_connectivity_controller.dart';
import 'controllers/weather_forecast_controller.dart';
import 'controllers/weather_map_controller.dart';
import 'controllers/theme_controller.dart';
import 'views/welcome/welcome_view.dart';
import 'views/home/home_view.dart';
import 'views/weather_forecast/weather_forecast_view.dart';
import 'views/ai_assistant/ai_assistant_view.dart';
import 'views/settings/settings_view.dart';
import 'components/navigation/app_bottom_nav_bar.dart';

void main() {
  runApp(const RiceWatchApp());
}

class RiceWatchApp extends StatelessWidget {
  const RiceWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => AiAssistantController()),
        ChangeNotifierProvider(create: (_) =>
            NetworkConnectivityController()..startListening()),
        ChangeNotifierProvider(create: (_) => WeatherForecastController()),
        ChangeNotifierProvider(create: (_) => WeatherMapController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'RiceWatch',
          debugShowCheckedModeBanner: false,
          theme:      AppTheme.light,
          darkTheme:  AppTheme.dark,
          themeMode:  theme.mode,
          home: const AppRouter(),
        ),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, nav, _) {
        if (!nav.onboardingComplete) return const WelcomeView();
        return const _MainShell();
      },
    );
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, nav, _) {
        switch (nav.bottomNavIndex) {
          case AppBottomNavBar.homeIndex:
            return const HomeView();
          case AppBottomNavBar.weatherIndex:
            return const WeatherForecastView();
          case AppBottomNavBar.aiAssistantIndex:
            return const AiAssistantView();
          case AppBottomNavBar.settingsIndex:
            return const SettingsView();
          case AppBottomNavBar.addImageIndex:
          default:
            return const HomeView();
        }
      },
    );
  }
}
