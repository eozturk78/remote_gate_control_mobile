// ignore_for_file: unnecessary_new, deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pultix_mobile/apis/apis.dart';
import 'package:pultix_mobile/constants.dart';
import 'package:pultix_mobile/screens/login.dart';
import 'package:pultix_mobile/screens/profile.dart';
import 'package:pultix_mobile/screens/splash_screen.dart';
import 'package:pultix_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../models/device.dart';
import '../models/site.dart';

class PaymentInformationScreen extends StatefulWidget {
  const PaymentInformationScreen({Key? key}) : super(key: key);
  @override
  _PaymentInformationScreenState createState() =>
      _PaymentInformationScreenState();
}

class _PaymentInformationScreenState extends State<PaymentInformationScreen> {
  bool? paymentInfoIsReceived = false;
  bool isConnected = true;
  String? bank1, bankHolder1, iban1;
  String? bank2, bankHolder2, iban2;
  String? bank3, bankHolder3, iban3, paymentCode;
  String? price, maxOpenGateCount;
  @override
  void initState() {
    super.initState();
    getPaymentInformation();
  }

  getPaymentInformation() {
    Apis apis = Apis();

    apis.getPaymentInformation().then((value) {
      setState(() {
        print(value);
        paymentCode = value['paymentCode'];
        print(value['maxOpenGateCount']);
        maxOpenGateCount = value['maxOpenGateCount'];
        if (paymentCode == null) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const SplashScreen()));
        } else {
          bank1 = value['bank1'];
          bankHolder1 = value['bankHolder1'];
          iban1 = value['iban1'];
          bank2 = value['bank2'];
          bankHolder2 = value['bankHolder2'];
          iban2 = value['iban2'];
          bank3 = value['bank3'];
          bankHolder3 = value['bankHolder3'];
          iban3 = value['iban3'];
          price = value['price'];
          checkStatusOfPayment();
        }
      });
    }).catchError((err) async {
      if (err is TimeoutException) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const Login(null)));
      } else if (err is ArgumentError) {
        SharedPreferences pref = await SharedPreferences.getInstance();
        pref.setBool("needAPayment", false);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const SplashScreen()));
      }
    });
  }

  checkStatusOfPayment() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (paymentCode != null) {
      pref.setBool("needAPayment", true);
    } else {
      pref.setBool("needAPayment", false);
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SplashScreen()));
    }
  }

  var isLocationFailed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Bilgileri'),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: paymentCode != null
          ? SingleChildScrollView(
              child: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(25),
                      child: Column(
                        children: [Image.asset("assets/images/logo-big.PNG")],
                      ),
                    ),
                    Column(
                      children: [
                        if (paymentInfoIsReceived == true)
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
                                  "Ödeme bildiriminiz alındı çok yakın bir zamanda sizinle iletişime geçilecektir.",
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        if (paymentInfoIsReceived == false)
                          Column(
                            children: [
                              Text(
                                  "Uygulamamızın ücretsiz paketi kapsamında ${maxOpenGateCount} defa kapı açma limitini aştınız, kullanmaya devam etmek için aşağıdaki banka hesaplarından birine ödeme yapınız"),
                              SizedBox(
                                height: 15,
                              ),
                              if (iban1 != null &&
                                  bankHolder1 != null &&
                                  bank1 != null)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          iban1.toString(),
                                          style: labelText,
                                        ),
                                        TextButton(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: iban1.toString()));
                                              showToast("IBAN kopyalandı");
                                            },
                                            style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              padding: EdgeInsets.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Icon(
                                              Icons.copy,
                                              color: Colors.black,
                                              size: 15,
                                            ))
                                      ],
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      bank1.toString(),
                                      style: labelText,
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      bankHolder1.toString(),
                                      style: labelText,
                                    ),
                                    SizedBox(
                                      height: 1,
                                    ),
                                  ],
                                ),
                              SizedBox(
                                height: 15,
                              ),
                              if (iban2 != null &&
                                  bankHolder2 != null &&
                                  bank2 != null)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          iban2.toString(),
                                          style: labelText,
                                        ),
                                        SizedBox(
                                          width: 2,
                                        ),
                                        TextButton(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: iban2.toString()));
                                              showToast("IBAN kopyalandı");
                                            },
                                            style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              padding: EdgeInsets.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Icon(
                                              Icons.copy,
                                              color: Colors.black,
                                              size: 15,
                                            ))
                                      ],
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      bank2.toString(),
                                      style: labelText,
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      bankHolder2.toString(),
                                      style: labelText,
                                    ),
                                    SizedBox(
                                      height: 1,
                                    ),
                                  ],
                                ),
                              SizedBox(
                                height: 15,
                              ),
                              if (iban3 != null &&
                                  bankHolder3 != null &&
                                  bank3 != null)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          iban3.toString(),
                                          style: labelText,
                                        ),
                                        SizedBox(
                                          width: 2,
                                        ),
                                        TextButton(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: iban3.toString()));
                                              showToast("IBAN kopyalandı");
                                            },
                                            style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              padding: EdgeInsets.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Icon(
                                              Icons.copy,
                                              color: Colors.black,
                                              size: 15,
                                            ))
                                      ],
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      bank3.toString(),
                                      style: labelText,
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      bankHolder3.toString(),
                                      style: labelText,
                                    ),
                                    SizedBox(
                                      height: 1,
                                    ),
                                  ],
                                ),
                              SizedBox(
                                height: 50,
                              ),
                              Text(
                                "${price.toString()} TL ödeme beklenmektedir",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 20),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "Önemli Not",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 20),
                              ),
                              Text(
                                paymentCode.toString(),
                                style:
                                    TextStyle(color: Colors.red, fontSize: 20),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "Lütfen yaptığınız ödemelerde açıklamaya mutlaka  yukarıdaki kodu yazın",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Apis apis = Apis();

                                  apis
                                      .setPaymentInfo(paymentCode)
                                      .then((value) {
                                    paymentInfoIsReceived = true;
                                    setState(() {});
                                  });
                                },
                                child: Text("Ödeme Bildir"),
                                style: ElevatedButton.styleFrom(
                                    maximumSize: Size.fromHeight(40),
                                    backgroundColor: kPrimaryColor),
                              ),
                            ],
                          ),
                      ],
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        const url =
                            'https://aesmartsystems.com'; //Twitter's URL
                        await launch(url);
                      },
                      child: const Text(
                          'Hizmetlerimiz hakkında bilgi almak için tıklayın'),
                    ),
                  ],
                ),
              ),
            )
          : Text(""),
    );
  }
}
