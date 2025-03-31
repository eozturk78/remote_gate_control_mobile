// ignore_for_file: unnecessary_new, deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/constants.dart';
import 'package:remote_gate_control_mobile/screens/device_payment_information.dart';
import 'package:remote_gate_control_mobile/screens/login.dart';
import 'package:remote_gate_control_mobile/screens/payment_information.dart';
import 'package:remote_gate_control_mobile/screens/profile.dart';
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../models/device.dart';
import '../models/site.dart';

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
  bool isDevicePaymentRequired = false;
  bool? isDataExist;
  Timer? _timer;
  late String _deviceId;
  String stepStatusText = "";
  var _data = null;
  bool isConnected = true;
  bool needAPayment = true;
  @override
  void initState() {
    super.initState();
    checkInternet();
  }

  checkInternet() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.getBool("needAPayment") == true) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PaymentInformationScreen()));
    }
    bool result = await InternetConnectionChecker().hasConnection;
    isConnected = result;
    setState(() {});
    needAPayment = false;
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
  late Timer _timerGate;
  navigateUser() async {
    getGateList();
    int _start = 10;
    _timerGate = new Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_start == 0) {
          getGateList();
          _start = 10;
        } else {
          _start--;
        }
      },
    );

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

        dataList.sort((a, b) =>
            b.IsActiveDevice.toString().compareTo(a.IsActiveDevice.toString()));
        setState(() {
          isDataExist = true;
          isSendRequestToDevice = false;
        });
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

  saveLocation(String? siteId, String deviceId, bool isOpenedDoor) async {
    Apis apis = Apis();
    SharedPreferences pref = await SharedPreferences.getInstance();
    _deviceId = deviceId;
    apis
        .sendOpenDoorRequest(locationData?.latitude, locationData?.longitude,
            siteId, deviceId, isOpenedDoor, dist)
        .then((value) async {
      if (value['isPaymentRequired'] == 1) {
        //    pref.remove("token");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PaymentInformationScreen()));
      } else if (value['paymentCode'] != null) {
        isDevicePaymentRequired = true;
        setState(() {});
      } else if (value['sites'] != null) {
        pref.setString('sites', jsonEncode(value['sites']));
        if (isOpenedDoor)
          Future.delayed(Duration(seconds: 1), () {
            SystemNavigator.pop();
            if (Platform.isIOS) exit(0);
          });
      }
    }).catchError((err) {
      if (err is TimeoutException) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const Login(null)));
      }
    });
  }

  getGateList() async {
    Apis apis = Apis();
    SharedPreferences pref = await SharedPreferences.getInstance();
    apis.getGateList().then((value) async {
      if (value['isPaymentRequired'] == 1) {
        //    pref.remove("token");
        _timerGate.cancel();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PaymentInformationScreen()));
      } else if (value['paymentCode'] != null) {
        isDevicePaymentRequired = true;
        _timerGate.cancel();
        setState(() {});
      } else if (value['sites'] != null) {
        pref.setString('sites', jsonEncode(value['sites']));

        String? s = pref.getString('sites');
        prepareScreen(jsonDecode(s!));
      }
    }).catchError((err) {
      if (err is TimeoutException) {
        _timerGate.cancel();
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

  Position? locationData;
  dynamic dist = 0;
  sendRequestToDevice(Device data) async {
    setState(() {
      isSendRequestToDevice = true;
      stepStatusText = "Konum Alınıyor.";
    });
    try {
      locationData = await Geolocator.getCurrentPosition(
        timeLimit: Duration(seconds: 10),
        desiredAccuracy: LocationAccuracy.best,
      );
      dist = calculateDistance(
          locationData?.latitude, locationData?.longitude, data.lat, data.long);
    } catch (e) {
      /*setState(() {
        isOpenGate = false;
        isSendRequest = false;
        isSendRequestToDevice = false;
        isLocationFailed = true;
      });*/
      checkPermissionStatus(false);
      //showMessagePage("Konum alınamadı");
    }

    if (data.HexCode == null) {
      showMessagePage("Cihaz şuanda aktif değil");
    } else if (data.remoteControl == false && dist > 201) {
      showMessagePage("Cihazınıza uzaktasınız. ");
    } else if (dist < 201) {
      sendToBackend(data);
    } else if (data.remoteControl == true) {
      showDialog(context: context, builder: (context) => onOpenImage(context))
          .then((value) {
        if (value == 1) {
          sendToBackend(data);
        }
      });
    }
  }

  showMessagePage(String msg) {
    showToast(msg);
    setState(() {
      isOpenGate = false;
      isSendRequest = false;
      isSendRequestToDevice = false;
    });
  }

  bool isSendAgain = true;
  sendToBackend(Device data) async {
    setState(() {
      isSendRequestToDevice = true;
      stepStatusText = "Kapı açma sinyali gönderiliyor.";
    });
    try {
      Apis apis = Apis();
      await apis
          .sendRequestTeltonika(data.SerialNumber, data.HexCode!)
          .then((value) {
        saveLocation(data.SiteId, data.DeviceId, true);
        setState(() {
          isOpenGate = true;
          isSendRequest = true;
          isSendRequestToDevice = false;
          isLocationFailed = false;
        });
      }).timeout(Duration(seconds: 2));
    } on TimeoutException catch (_) {
      saveLocation(data.SiteId, data.DeviceId, false);
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

  bool isPermissionDenied = false;
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

  var isLocationFailed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('AE Smart Systems'),
          backgroundColor: kPrimaryColor,
          centerTitle: false,
          automaticallyImplyLeading: false,
          actions: [
            /* TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GuestTokenListScreen()));
              },
              child: Text(
                "Misafirim Var",
                style: TextStyle(color: Colors.white),
              ),
            )*/
          ]),
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
                    if (isPermissionDenied)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => checkPermissionStatus(true),
                        child: Ink(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20)),
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
                        if (Platform.isIOS) exit(0);
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
                                        backgroundColor: dataList[index]
                                                    .Devices[j]
                                                    .isSiteActive! ==
                                                1
                                            ? kPrimaryColor
                                            : const Color.fromARGB(
                                                179, 158, 158, 158),
                                      ),
                                      onPressed: () {
                                        _timer?.cancel();
                                        _data = dataList[index];
                                        sendRequestToDevice(
                                            dataList[index].Devices[j]);
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            dataList[index].Devices[j].Name,
                                          ),
                                          if (dataList[index]
                                                  .Devices[j]
                                                  .isSiteActive ==
                                              0)
                                            Text(
                                              "Bu kapı aktif değil",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red),
                                            )
                                        ],
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
                            if (isDevicePaymentRequired! == true)
                              Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Text(
                                      "Hizmetinizin aksamaması için kapınızda bağlı bulunan sim kartınızın yıllık veri iletim ücretinin ödenmesi gerekmektedir. Lütfen konu ile ilgili site yöneticinize başvurun",
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 15),
                                    ),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kPrimaryColor,
                                          ),
                                          onPressed: () async {
                                            SharedPreferences pref =
                                                await SharedPreferences
                                                    .getInstance();

                                            pref.setString(
                                                "deviceId", _deviceId);
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const DevicePaymentInformationScreen()));
                                          },
                                          child: const Text("Daha Fazla Bilgi"),
                                        ),
                                        Spacer(),
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
                                    ),
                                  ],
                                ),
                              )
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
                              "Kapı açılamadı.",
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
