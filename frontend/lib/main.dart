import 'package:flutter/material.dart';
import 'package:frontend/screens/main_page.dart';
import 'screens/home_page.dart';
import 'data/app_data.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await loadData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainPage(),
    );
  }
}
