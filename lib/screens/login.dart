import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/screens/forgot_password.dart';
import 'package:remote_gate_control_mobile/screens/main.dart';
import 'package:remote_gate_control_mobile/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class Login extends StatefulWidget {
  const Login(Key? key) : super(key: key);
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Location location = new Location();
  Apis apis = Apis();
  TextEditingController email = new TextEditingController();
  TextEditingController password = new TextEditingController();
  onLogin() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await apis.login(email.text, password.text).then((value) {
      pref.setString('token', value['token']);
      pref.setString('email', email.text);
      pref.setString('sites', jsonEncode(value['sites']));

      print(pref.getString('sites'));
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SplashScreen()));
    });
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
        body: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Image.asset("assets/images/logo-big.PNG"),
              TextFormField(
                controller: email,
                obscureText: false,
                decoration: const InputDecoration(
                  hintText: 'E-Posta',
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Şifre'),
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
              const SizedBox(
                height: 40,
              ),
              const Text('Uygulamamızın verimli çalışabilmesi için;'),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("1. Wifi bağlantınızın"),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("2. GPS konum hizmetleri"),
              ),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Center(
                    child: Text(
                        "3. İnternet erişimizin bulunması gerekmektedir.")),
              )
            ],
          ),
        ));
  }
}
