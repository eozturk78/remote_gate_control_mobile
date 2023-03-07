import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../apis/apis.dart';
import '../constants.dart';

class ForgotPasswordPage extends StatefulWidget {
  ForgotPasswordPage(Key? key) : super(key: key);
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPasswordPage> {
  Apis apis = Apis();
  TextEditingController email = new TextEditingController();
  bool isForgotPasswordSuccess = false;
  onForgotPassword() async {
    await apis.forgotPassword(email.text).then((value) {
      setState(() {
        isForgotPasswordSuccess = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şifremi Unuttum"),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            if (!isForgotPasswordSuccess)
              Column(
                children: [
                  const SizedBox(
                    height: 130,
                  ),
                  TextFormField(
                    controller: email,
                    obscureText: false,
                    decoration: const InputDecoration(
                      hintText: 'E-Posta',
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: kPrimaryColor,
                    ),
                    onPressed: () {
                      onForgotPassword();
                    },
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
              )
            else
              Column(
                children: const [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100.0,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Text(
                      "Yeni şifreniz e-posta adresinize gönderildi.",
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
