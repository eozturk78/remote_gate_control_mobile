import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/screens/forgot_password.dart';
import 'package:remote_gate_control_mobile/screens/main.dart';
import 'package:remote_gate_control_mobile/screens/payment_information.dart';
import 'package:remote_gate_control_mobile/screens/splash_screen.dart';
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../constants.dart';

class Login extends StatefulWidget {
  const Login(Key? key) : super(key: key);
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  void initState() {
    super.initState();
    checkPermissionStatus(false);
  }

  Apis apis = Apis();
  TextEditingController email = new TextEditingController();
  TextEditingController password = new TextEditingController();
  bool isPermissionDenied = false;
  onLogin() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await apis.login(email.text, password.text).then((value) {
      pref.setBool('isSiteManager', value['isSiteManager'] == 1 ? true : false);
      pref.setString('token', value['token']);
      pref.setString('email', email.text);
      pref.setString('sites', jsonEncode(value['sites']));
      if (value['isPaymentRequired'] == 1) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PaymentInformationScreen()));
      } else {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SplashScreen()));
      }
    });
  }

  checkPermissionStatus(bool isButton) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        isPermissionDenied = false;
        setState(() {});
      } else if (permission == LocationPermission.deniedForever && isButton) {
        await openAppSettings();
        checkLocationPermitted();
      } else {
        isPermissionDenied = true;

        setState(() {});
      }
    }
  }

  Timer? _timer;
  checkLocationPermitted() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (Platform.isAndroid) {
          PermissionStatus
              permissionStatus; // note do not use PermissionStatus? permissionStatus;
          permissionStatus = await Permission.locationWhenInUse.request();
          if (permissionStatus != PermissionStatus.granted) {
            isPermissionDenied = true;
            setState(() {});
            _timer?.cancel();
          }
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            isPermissionDenied = false;
            setState(() {});
            _timer?.cancel();
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Oturum Aç"),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Image.asset(
              "assets/images/logo-big.PNG",
              height: 120,
            ),
            TextFormField(
              controller: email,
              obscureText: false,
              decoration: const InputDecoration(
                labelText: 'E-Posta',
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordPage(null),
                    ));
              },
              child: const Text('Şifremi unuttum'),
            ),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor: kPrimaryColor,
              ),
              onPressed: () => this.onLogin(),
              child: Ink(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 200,
                  alignment: Alignment.center,
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (isPermissionDenied)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: Colors.red,
                ),
                onPressed: () => checkPermissionStatus(true),
                child: Ink(
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    width: 200,
                    alignment: Alignment.center,
                    child: Text(
                      'Konum izni veriniz.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(
              height: 40,
            ),
            const Text('Uygulamamızın verimli çalışabilmesi için;'),
            const Padding(
                padding: EdgeInsets.all(15),
                child: Text("1. İnternet erişimizin bulunması gerekmektedir.")),
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                  "2. Uygulama açıldıktan sonra konum verisine izin vermeniz gerekmektedir."),
            ),
          ],
        ),
      )),
    );
  }
}
