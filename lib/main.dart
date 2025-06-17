import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remote_gate_control_mobile/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await MobileAds.instance.initialize(); // ÖNEMLİ
  //MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
  //  testDeviceIds: ['38400000-8cf0-11bd-b23e-10b96e40000d']));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
