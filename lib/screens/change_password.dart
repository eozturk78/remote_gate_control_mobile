import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/screens/forgot_password.dart';
import 'package:remote_gate_control_mobile/screens/main.dart';
import 'package:remote_gate_control_mobile/screens/splash_screen%20-%20ios.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword(Key? key) : super(key: key);
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  Apis apis = Apis();
  TextEditingController oldPassword = new TextEditingController();
  TextEditingController password = new TextEditingController();
  bool isChangePasswordSuccess = false;

  onChangePassword() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await apis.changePassword(oldPassword.text, password.text).then((value) {
      setState(() {
        isChangePasswordSuccess = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Şifremi Değiştir"),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            children: [
              if (!isChangePasswordSuccess)
                Column(
                  children: [
                    const SizedBox(
                      height: 130,
                    ),
                    TextFormField(
                      controller: oldPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Mevcut Şifre',
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Yeni Şifre'),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: kPrimaryColor,
                      ),
                      onPressed: () => this.onChangePassword(),
                      child: Ink(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          width: 200,
                          alignment: Alignment.center,
                          child: const Text(
                            'Gönder',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              if (isChangePasswordSuccess)
                Center(
                  child: Column(
                    children: const [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 100.0,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Şifre Başarıyla Değiştirildi",
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
            ],
          )),
    );
  }
}
