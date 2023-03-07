// ignore_for_file: unnecessary_new, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/constants.dart';
import 'package:remote_gate_control_mobile/screens/login.dart';
import 'package:remote_gate_control_mobile/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import 'package:remote_gate_control_mobile/toast.dart';

import '../models/device.dart';
import '../models/site.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  List<Site> dataList = [];
  bool isSendRequest = false;
  bool isSendRequestToDevice = false;
  bool? isOpenGate;
  bool? isDataExist;
  Timer? _timer;
  String stepStatusText = "";
  var _data = null;
  var _usersSSId = null;
  var _usersBSSId = null;
  @override
  void initState() {
    super.initState();
    checkWifiState();
  }

  checkWifiState() {
    WiFiForIoTPlugin.isEnabled().then((val) {
      if (val) {
        navigateUser();
        setState(() {
          _sendNavigator = false;
        });
      }
    });
  }

  bool _isEWifinable = false;
  bool _sendNavigator = true;
  Widget getButtonWidgetsForAndroid() {
    WiFiForIoTPlugin.isEnabled().then((val) {
      setState(() {
        _isEWifinable = val;
        if (_isEWifinable && _sendNavigator) {
          Future.delayed(const Duration(seconds: 5), () {
            checkWifiState();
          });
          _sendNavigator = false;
        } else if (!_isEWifinable) {
          _sendNavigator = true;
        }
      });
    });
    return _isEWifinable
        ? const Text('')
        : Column(
            children: const [
              Text(
                'Lütfen wifi bağlantınızı açın',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ],
          );
  }

  continueFromLocalDB() async {
    stepStatusText = "Konum alınamadı bütün cihazlarda aranacak";
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.getString('sites') != null) {
      String? s = pref.getString('sites');
      prepareScreen(jsonDecode(s!));
    } else {
      setState(() {
        isDataExist = false;
        isSendRequestToDevice = false;
      });
    }
  }

  navigateUser() async {
    isSendRequestToDevice = true;
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.getString("token") == null ||
        pref.getString("token")?.isEmpty == true) {
      // ignore: use_build_context_synchronously
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login(null)));
    } else {
      getAllSiteFromLocal();
    }
  }

  checkUserData() async {
    print("===================");
    SharedPreferences pref = await SharedPreferences.getInstance();
    Apis apis = Apis();
    apis.sendOpenDoorRequest(0, 0).then((value) {
      if (pref.getString("token") == null ||
          pref.getString("token")?.isEmpty == true) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Login(null)));
      }
      pref.setString('sites', jsonEncode(value['sites']));
    }).onError((error, stackTrace) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login(null)));
    });
  }

  getAllSiteFromLocal() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.getString('sites') != null) {
      String? s = pref.getString('sites');
      prepareScreen(jsonDecode(s!));
    } else {
      setState(() {
        isDataExist = false;
      });
    }
  }

  prepareScreen(data) {
    if (data != null) {
      var records = (data as List).map((e) => Site.fromJson(e)).toList();
      if (records.length == 1 && records[0]?.Devices?.length == 1) {
        _data = records[0];
        sendRequestToDevice(_data.Devices[0]);
        setState(() {
          isDataExist = true;
        });
      } else if (records.length > 1 || records[0].Devices.length > 1) {
        dataList = records.toList();
        setState(() {
          isDataExist = true;
          isSendRequestToDevice = false;
        }); /* */
      } else {
        setState(() {
          isDataExist = false;
          isSendRequestToDevice = false;
        });
      }
    } else {
      setState(() {
        isDataExist = false;
        isSendRequestToDevice = false;
      });
    }
  }

  closeConnection() {
    checkUserData();
    setState(() {
      isSendRequest = false;
      isSendRequestToDevice = false;
      isOpenGate = false;
    });
  }

  sendRequestToDevice(Device data) async {
    try {
      stepStatusText = "Cihaza bağlanılıyor.";
      WiFiForIoTPlugin.findAndConnect(data.SSId,
              password: data.Password, joinOnce: false, withInternet: false)
          .then((value) async {
        isOpenGate = value;
        if (value) {
          stepStatusText = "Cihaza bağlandı.";
          await WiFiForIoTPlugin.forceWifiUsage(true);
          try {
            stepStatusText = "Kapı sinyali gönderiliyor.";
            await http.get(Uri.parse(data.Url)).timeout(
                const Duration(seconds: 5),
                onTimeout: () => closeConnection());
          } on Exception catch (ex) {
            checkUserData();
            setState(() {
              isSendRequest = true;
              isSendRequestToDevice = false;
            });
          }
          await WiFiForIoTPlugin.forceWifiUsage(false);
          await WiFiForIoTPlugin.disconnect();
          _timer = Timer(Duration(seconds: 1), () {
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            } else if (Platform.isIOS) {
              exit(0);
            }
          });
        } else {
          checkUserData();
        }
        stepStatusText = "Kapı sinyali gönderildi.";
        setState(() {
          isSendRequest = true;
          isSendRequestToDevice = false;
        });
      }).onError((error, stackTrace) {
        print("err 1");
        setState(() {
          isOpenGate = false;
          isSendRequest = false;
          isSendRequestToDevice = false;
        });
      });
    } on TimeoutException catch (e) {
      print("timeout 1");
      setState(() {
        isOpenGate = false;

        isSendRequest = false;
        isSendRequestToDevice = false;
      });
    } on Error catch (e) {
      print("err 2");
      setState(() {
        isDataExist = false;
        isSendRequest = true;
        isSendRequestToDevice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AE Smart Systems'),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: SingleChildScrollView(
              child: SafeArea(
                child: getButtonWidgetsForAndroid(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(15),
            child: Image.asset("assets/images/logo-big.PNG"),
          ),
          if (isSendRequestToDevice)
            Column(
              children: [
                const SpinKitCircle(
                  color: kPrimaryColor,
                  size: 50.0,
                ),
                // ignore: unnecessary_string_interpolations
                Text("$stepStatusText")
              ],
            ),
          if (!isSendRequestToDevice &&
              _isEWifinable &&
              isDataExist == true &&
              !isSendRequest)
            Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: dataList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Column(
                            children: [
                              Text(
                                dataList[index].BuildingName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: dataList[index].Devices.length,
                                itemBuilder: (BuildContext context, int j) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      backgroundColor: kPrimaryColor,
                                    ),
                                    onPressed: () {
                                      _timer?.cancel();
                                      _data = dataList[index];
                                      setState(() {
                                        isSendRequestToDevice = true;
                                      });
                                      sendRequestToDevice(
                                          dataList[index].Devices[j]);
                                    },
                                    child: Text(
                                      dataList[index].Devices[j].Name,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                            ],
                          );
                        }),
                    const SizedBox(
                      height: 120,
                    ),
                    if (dataList.length > 1)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor: Colors.grey,
                        ),
                        onPressed: () {
                          _timer?.cancel();
                          isSendRequest = false;
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: ((context) =>
                                          const ProfileScreen(null))))
                              .then((value) {
                            navigateUser();
                          });
                        },
                        child: const Text("Ayarlara git"),
                      ),
                  ],
                ))
          else if (!isSendRequestToDevice && _isEWifinable && isSendRequest)
            Padding(
              padding: const EdgeInsets.all(15),
              child: Center(
                child: Column(
                  children: [
                    if (isOpenGate == true)
                      Column(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 100.0,
                            color: Colors.green,
                          ),
                          Text(
                            "Kapı açma sinyali gönderildi.",
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Icon(
                            Icons.remove_circle_outline_sharp,
                            size: 100.0,
                            color: Colors.red,
                          ),
                          Text(
                            "Cihaz durumu kontrol edilmeli.",
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 50,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor:
                              kPrimaryColor // fromHeight use double.infinity as width and 40 is the height
                          ),
                      onPressed: () {
                        _timer?.cancel();
                        isSendRequest = false;
                        isSendRequestToDevice = true;
                        sendRequestToDevice(_data.Devices[0]);
                      },
                      child: const Text("Tekrar istek gönder"),
                    ),
                    const SizedBox(
                      height: 120,
                    ),
                    if (dataList.isNotEmpty)
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: kPrimaryColor,
                          ),
                          onPressed: () {
                            _timer?.cancel();
                            isSendRequest = false;
                          },
                          child: const Text("Listeye dön")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        _timer?.cancel();
                        isSendRequest = false;
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) =>
                                    const ProfileScreen(null)))).then((value) {
                          navigateUser();
                        });
                      },
                      child: const Text("Ayarlara git"),
                    ),
                  ],
                ),
              ),
            )
          else if (!isSendRequestToDevice &&
              _isEWifinable &&
              isDataExist == false)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  const Icon(
                    Icons.remove_circle_outline_sharp,
                    size: 100.0,
                    color: Colors.red,
                  ),
                  const Text("Bulunduğunuz yerde kapı bulunamadı"),
                  const SizedBox(
                    height: 40,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      _timer?.cancel();
                      navigateUser();
                    },
                    child: const Text("Tekrar dene"),
                  ),
                  const SizedBox(
                    height: 120,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: Colors.grey),
                    onPressed: () {
                      _timer?.cancel();
                      isSendRequest = false;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) =>
                                  const ProfileScreen(null))));
                    },
                    child: const Text("Ayarlara git"),
                  ),
                ],
              ),
            )),
          if (!isSendRequestToDevice)
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () async {
                const url = 'https://aesmartsystems.com'; //Twitter's URL
                await launch(url);
              },
              child: const Text(
                  'Hizmetlerimiz hakkında bilgi almak için tıklayın'),
            ),
        ],
      ),
    );
  }
}
