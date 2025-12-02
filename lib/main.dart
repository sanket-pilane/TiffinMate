import 'package:flutter/material.dart';
import 'package:tiffin_mate/core/theme/app_theme.dart';
import 'package:tiffin_mate/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const TiffinApp());
}

class TiffinApp extends StatelessWidget {
  const TiffinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TiffinMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
