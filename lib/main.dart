import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remote_gate_control_mobile/screens/splash_screen.dart';

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
    return GetMaterialApp(
      home: SafeArea(child: SplashScreen()),
    );
  }
}
