import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp(null));
}

class MyApp extends StatefulWidget {
  const MyApp(Key? key) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      home: SafeArea(child: SplashScreen()),
    );
  }
}
