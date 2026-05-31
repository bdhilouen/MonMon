import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/app_data.dart';
import 'services/api_service.dart';
import 'screens/login_page.dart';
import 'screens/main_page.dart';
import 'screens/web_main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadData();
  await updateLoginStreak();
  await ApiService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: const AuthGate(),

      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const ResponsiveRoot(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (ApiService.isLoggedIn) {
      return const ResponsiveRoot();
    }

    return const LoginPage();
  }
}

class ResponsiveRoot extends StatelessWidget {
  const ResponsiveRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktopWeb =
            kIsWeb && constraints.maxWidth >= 900;

        if (isDesktopWeb) {
          return const WebMainPage();
        }

        return const MainPage();
      },
    );
  }
}