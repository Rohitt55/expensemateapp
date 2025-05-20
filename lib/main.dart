import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_preview/device_preview.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: false, // false in release mode
      builder: (context) => const ExpenseApp(),
    ),
  );
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => MaterialApp(
        title: 'ExpenseMate',
        theme: ThemeData(
          fontFamily: 'NotoSans',
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFFDF7F0),
        ),
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        home: const EntryPoint(),
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/transactions': (context) => const TransactionScreen(),
          '/add': (context) => const AddTransactionScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  @override
  void initState() {
    super.initState();
    // Directly navigate to welcome screen every time app restarts
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
