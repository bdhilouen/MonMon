import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/app_data.dart';
import 'screens/main_page.dart';
import 'screens/web_main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadData();
  await updateLoginStreak();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ResponsiveRoot(),
    );
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