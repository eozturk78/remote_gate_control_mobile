// ignore_for_file: unnecessary_new, deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:location/location.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/constants.dart';
import 'package:remote_gate_control_mobile/screens/login.dart';
import 'package:remote_gate_control_mobile/screens/profile.dart';
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/device.dart';
import '../models/site.dart';

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
  bool isConnected = true;
  @override
  void initState() {
    super.initState();
    checkInternet();
  }

  checkInternet() async {
    bool result = await InternetConnectionChecker().hasConnection;
    isConnected = result;
    setState(() {});
    if (isConnected) {
      navigateUser();
    }
    _listener = InternetConnectionChecker()
        .onStatusChange
        .listen((InternetConnectionStatus status) {
      if (!isConnected) {
        if (status == InternetConnectionStatus.connected) {
          isConnected = true;
          navigateUser();
        } else {
          isConnected = false;
        }
      }
      setState(() {});
    });
  }

  late final StreamSubscription<InternetConnectionStatus> _listener;
  InternetConnectionStatus? _internetStatus;
  navigateUser() async {
    isSendRequestToDevice = true;
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.getString("token") == null ||
        pref.getString("token")?.isEmpty == true) {
      // ignore: use_build_context_synchronously
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Login(null)));
    } else {
      if (pref.getString('sites') != null) {
        String? s = pref.getString('sites');
        prepareScreen(jsonDecode(s!));
      } else {
        setState(() {
          isDataExist = false;
        });
      }
    }
  }

  prepareScreen(data) {
    if (data != null) {
      var records = (data as List).map((e) => Site.fromJson(e)).toList();
      if (records.isNotEmpty || records[0].Devices.length > 1) {
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

  completeSave() async {
    saveLocation();
  }

  LocationData? locationData;
  saveLocation() async {
    Apis apis = Apis();
    SharedPreferences pref = await SharedPreferences.getInstance();
    apis
        .sendOpenDoorRequest(locationData?.latitude, locationData?.longitude)
        .then((value) async {
      if (value['sites'] != null) {
        pref.setString('sites', jsonEncode(value['sites']));
      }

      Future.delayed(Duration(seconds: 1), () {
        SystemNavigator.pop();
      });
    }).catchError((err) {
      if (err is TimeoutException) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Login(null)));
      }
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p =
        0.017453292519943295; //conversion factor from radians to decimal degrees, exactly math.pi/180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    var radiusOfEarth = 6371;
    return radiusOfEarth * 2 * asin(sqrt(a)) * 1000;
  }

  sendRequestToDevice(Device data) async {
    setState(() {
      isSendRequestToDevice = true;
      stepStatusText = "Konum Alınıyor.";
    });
    locationData = await Future.any([
      location.getLocation(),
      Future.delayed(Duration(seconds: 5), () {
        if (locationData == null) {
          isLocationFailed = true;
          isOpenGate = false;
          isSendRequest = false;
          isSendRequestToDevice = false;
        }
        setState(() {});
      }),
    ]);
    if (locationData == null) {
      setState(() {
        isOpenGate = false;
        isSendRequest = false;
        isSendRequestToDevice = false;
        isLocationFailed = true;
      });
      showToast("Konum alınamadı");
      return;
    }
    setState(() {
      stepStatusText = "Konum Alındı.";
    });
    var dist = calculateDistance(
        locationData?.latitude, locationData?.longitude, data.lat, data.long);
    if (dist < 51) {
      if (data.HexCode == null) {
        showToast("Bir hata oluştu");
        setState(() {
          isOpenGate = false;
          isSendRequest = false;
          isSendRequestToDevice = false;
        });
        return;
      }
      sendToBackend(data);
    } else if (data.remoteControl == true) {
      showDialog(context: context, builder: (context) => onOpenImage(context))
          .then((value) {
        if (value == 1) {
          sendToBackend(data);
        } else {}
      });
    } else {
      showToast("Cihazınıza uzaktasınız. ");
    }
  }

  sendToBackend(Device data) async {
    setState(() {
      isSendRequestToDevice = true;
      stepStatusText = "Kapı açma sinyali gönderiliyor.";
    });
    try {
      Apis apis = Apis();
      var resp = await apis
          .sendRequestTeltonika(data.SerialNumber, data.HexCode!)
          .then((value) {
        completeSave();
        setState(() {
          isOpenGate = true;
          isSendRequest = true;
          isSendRequestToDevice = false;
          isLocationFailed = false;
        });
      }).timeout(Duration(seconds: 5));
    } on TimeoutException catch (_) {
      setState(() {
        isOpenGate = false;
        isSendRequest = true;
        isSendRequestToDevice = false;
        isLocationFailed = false;
      });
    }
  }

  Widget onOpenImage(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ),
      content: StatefulBuilder(
        builder: (BuildContext context, setState) {
          return SizedBox(
            height: 150,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                      "Kapınıza uzak mesafedesiniz, yine de açmak istediğinizden emin misiniz?"),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(1);
                        },
                        child: Text("Eminim Kapıyı Aç"),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        child: const Text("Uygulamayı Kapat"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  var isLocationFailed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AE Smart Systems'),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                children: [Image.asset("assets/images/logo-big.PNG")],
              ),
            ),
            if (!isConnected)
              const Padding(
                padding: EdgeInsets.all(10),
                child: Center(
                  child: Text(
                    "Uygulamak kullanmak için internet bağlantısına ihtiyacınız var",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            if (isLocationFailed)
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text("Konumunuz alınamadı"),
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
                          isLocationFailed = false;
                        });
                        sendRequestToDevice(_data.Devices[0]);
                      },
                      child: const Text("Tekrar istek gönder"),
                    ),
                    if (isDataExist == true)
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: kPrimaryColor,
                          ),
                          onPressed: () {
                            _timer?.cancel();
                            setState(() {
                              isSendRequest = false;
                              isLocationFailed = false;
                            });
                          },
                          child: const Text("Listeye dön")),
                    SizedBox(
                      height: 40,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        SystemNavigator.pop();
                      },
                      child: const Text("Uygulamayı Kapat"),
                    ),
                  ],
                ),
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
                isDataExist == true &&
                !isSendRequest &&
                isConnected &&
                !isLocationFailed)
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
                  ],
                ),
              )
            else if (!isSendRequestToDevice && isSendRequest)
              Padding(
                padding: const EdgeInsets.all(15),
                child: Center(
                  child: Column(
                    children: [
                      if (isOpenGate == true)
                        Column(
                          children: [
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
                              "Lütfen internet bağlantınızı kontrol edin.",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                  backgroundColor: kPrimaryColor,
                                ),
                                onPressed: () {
                                  _timer?.cancel();
                                  setState(() {
                                    isSendRequest = false;
                                    isLocationFailed = false;
                                  });
                                },
                                child: const Text("Listeye dön")),
                          ],
                        ),
                      const SizedBox(
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ),
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
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.settings),
        backgroundColor: kPrimaryColor,
        onPressed: () {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: ((context) => const ProfileScreen(null))))
              .then((value) {
            navigateUser();
          });
        },
      ),
    );
  }
}
