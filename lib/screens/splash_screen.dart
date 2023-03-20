// ignore_for_file: unnecessary_new, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
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
  Location location = new Location();
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
    if (Platform.isAndroid) {
      WiFiForIoTPlugin.isEnabled().then((val) {
        if (val) {
          navigateUser();
          setState(() {
            _sendNavigator = false;
          });
        }
      });
    } else {
      navigateUser();
      setState(() {
        _sendNavigator = false;
      });
    }
  }

  bool _isEWifinable = false;
  bool _sendNavigator = true;
  Widget getButtonWidgetsForAndroid() {
    if (Platform.isAndroid) {
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
    } else {
      setState(() {
        _isEWifinable = true;
        if (_isEWifinable && _sendNavigator) {
          Future.delayed(const Duration(seconds: 5), () {
            checkWifiState();
          });
          _sendNavigator = false;
        } else if (!_isEWifinable) {
          _sendNavigator = true;
        }
      });
    }
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
      try {
        if (pref.getString('sites') != null) {
          String? s = pref.getString('sites');
          prepareScreen(jsonDecode(s!));
          saveLocation();
        } else {
          setState(() {
            isDataExist = false;
          });
        }
      } on TimeoutException catch (e) {
        getAllSiteFromLocal();
      } on Error catch (e) {
        getAllSiteFromLocal();
      }
    }
  }

  getAllSiteFromLocal() async {
    setState(() {
      stepStatusText = "Lokasyon alınamadı";
      isDataExist = false;
      isSendRequestToDevice = false;
    });
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
    print("time out");
    setState(() {
      isSendRequest = false;
      isSendRequestToDevice = false;
      isOpenGate = false;
    });
  }

  int sendAgainTime = 0;
  sendAgain(Device data) {
    if (sendAgainTime < 3) {
      isSendRequestToDevice = true;
      sendRequestToDevice(data);
      sendAgainTime++;
      setState(() {
        stepStatusText = "$sendAgainTime. bağlanma denemesi";
      });
    } else {
      setState(() {
        //sendAgainTime = 0;
        isOpenGate = true;
        isSendRequest = true;
        isSendRequestToDevice = false;
      });
    }
  }

  saveLocation() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    LocationData locationData;
    locationData =
        await location.getLocation().timeout(const Duration(seconds: 5));
    Apis apis = Apis();
    apis
        .sendOpenDoorRequest(locationData.latitude, locationData.longitude)
        .then((value) {
      pref.setString('sites', jsonEncode(value['sites']));
    }).onError((error, stackTrace) {
      getAllSiteFromLocal();
    });
  }

  sendRequestToDevice(Device data) async {
    stepStatusText = "Cihaza bağlanılıyor.";
    print(data.SSId);
    // WiFiForIoTPlugin.forceWifiUsage(false);
    _usersBSSId = WiFiForIoTPlugin.getBSSID();
    _usersSSId = WiFiForIoTPlugin.getSSID();
    WiFiForIoTPlugin.connect(data.SSId,
            password: data.Password,
            joinOnce: true,
            withInternet: false,
            security: NetworkSecurity.WPA)
        .then((value) async {
      if (value) {
        setState(() {
          stepStatusText = "Cihaza bağlandı.";
        });
        print(value.toString() + " =====");
        await WiFiForIoTPlugin.forceWifiUsage(true);
        try {
          setState(() {
            stepStatusText = "Kapı sinyali gönderiliyor.";
          });
          print(data.Url);
          //await http.get(Uri.parse(data.Url));
          await launch(data.Url).whenComplete(() async => await closeWebView());
          setState(() {
            isOpenGate = true;
            isSendRequest = true;
            isSendRequestToDevice = true;
          });
        } on Exception catch (ex) {
          setState(() {
            isOpenGate = true;
            isSendRequest = true;
            isSendRequestToDevice = true;
          });
        }
        await WiFiForIoTPlugin.forceWifiUsage(false);
        await WiFiForIoTPlugin.disconnect();
        // WiFiForIoTPlugin.removeWifiNetwork(data.SSId);
        //await WiFiForIoTPlugin.connect(_usersSSId, bssid: _usersBSSId);
        _timer = Timer(const Duration(seconds: 1), () {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else if (Platform.isIOS) {
            //exit(0);
          }
        });
        stepStatusText = "Kapı sinyali gönderildi.";
        setState(() {
          isSendRequest = true;
          isSendRequestToDevice = false;
        });
      } else {
        print(value);
        sendAgain(data);
      }
    }).onError((error, stackTrace) {
      print(error);
      setState(() {
        // sendAgain(data);
        isOpenGate = false;
        isSendRequest = false;
        isSendRequestToDevice = true;
      });
    });
    saveLocation();
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
            padding: EdgeInsets.all(5),
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
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount: dataList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: dataList[index].Devices.length,
                              itemBuilder: (BuildContext context, int j) {
                                return Container(
                                  margin: new EdgeInsets.only(bottom: 5),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(60),
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
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }),
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
                                    const ProfileScreen(null)))).then((value) {
                          navigateUser();
                        });
                      },
                      child: const Text("Ayarlara git"),
                    ),
                ],
              ),
            )
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
                        children: const [
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
                        setState(() {
                          isSendRequest = false;
                          isSendRequestToDevice = true;
                        });
                        sendRequestToDevice(_data.Devices[0]);
                      },
                      child: const Text("Tekrar istek gönder"),
                    ),
                    const SizedBox(
                      height: 60,
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
                    color: kPrimaryColor,
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
                    height: 60,
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
