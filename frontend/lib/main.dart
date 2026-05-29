import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_page.dart';
import 'screens/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service (load saved token)
  await ApiService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MonMon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: ApiService.isLoggedIn ? const MainPage() : const LoginPage(),
    );
  }
}
