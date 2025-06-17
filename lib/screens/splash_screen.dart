// ignore_for_file: unnecessary_new, deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/constants.dart';
import 'package:remote_gate_control_mobile/screens/device_payment_information.dart';
import 'package:remote_gate_control_mobile/screens/login.dart';
import 'package:remote_gate_control_mobile/screens/payment_information.dart';
import 'package:remote_gate_control_mobile/screens/profile.dart';
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../models/device.dart';
import '../models/site.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:remote_gate_control_mobile/firebase_options.dart'; // flutterfire CLI ile oluşturulacak

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  List<Site> dataList = [];
  bool isSendRequest = false;
  bool isSendRequestToDevice = false;
  bool? isOpenGate = false;
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

  String localVersion = "";
  checkInternet() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    localVersion = packageInfo.version;
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (pref.getString("token") == null ||
        pref.getString("token") == 'null' ||
        pref.getString("token") == "") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Login(null)));
    } else {
      if (pref.getBool("needAPayment") == true) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PaymentInformationScreen()));
      } else {
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
    }
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

  Future<void> _playSound() async {
    final player = AudioPlayer();
    await player.setAsset('assets/images/success.mp3');
    await player.play();
  }

  saveLocation(Device data, bool isOpenedDoor) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    SharedPreferences pref = await SharedPreferences.getInstance();

    String? token;
    if (pref.getString("deviceToken") == null ||
        pref.getString("deviceToken") == "") {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        token = await FirebaseMessaging.instance.getToken();
        if (token != null) pref.setString("deviceToken", token);
      } else {
        print('❌ User declined or has not accepted permission');
      }
    } else {
      token = pref.getString("deviceToken");
    }

    Apis apis = Apis();
    dynamic lat, long;
    try {
      locationData = await Geolocator.getCurrentPosition(
        timeLimit: Duration(seconds: 10),
        desiredAccuracy: LocationAccuracy.best,
      );
      lat = locationData?.latitude;
      long = locationData?.longitude;
      dist = calculateDistance(
          locationData?.latitude, locationData?.longitude, data.lat, data.long);
    } catch (e) {
      lat = 0.0;
      long = 0.0;
    }

    print(token);

    apis
        .sendOpenDoorRequest(
            lat, long, data.SiteId, data.DeviceId, isOpenedDoor, dist, token)
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
          Future.delayed(Duration(seconds: 2), () {
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

  String version = "";
  getGateList() async {
    Apis apis = Apis();
    SharedPreferences pref = await SharedPreferences.getInstance();
    apis.getGateList().then((value) async {
      pref.setBool('isSiteManager', value['isSiteManager'] == 1 ? true : false);
      version = value['version'];
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
  dynamic dist = 0.0;
  sendRequestToDevice(Device data) async {
    sendToBackend(data);
  }

  showMessagePage(String msg) {
    showToast(msg);
    setState(() {
      isOpenGate = false;
      isSendRequest = false;
      isSendRequestToDevice = false;
    });
  }

  /* showAdverdisement() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3506128953915434/4612948259'
          : 'ca-app-pub-3506128953915434/9991427706', // gerçek reklam ID ile değiştir
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
          print(_);
        },
        onAdFailedToLoad: (ad, error) {
          print(error);
          ad.dispose();
        },
      ),
    )..load();

    _bannerAd.load();
  }*/

  bool isSendAgain = true;
  // late BannerAd _bannerAd;
  bool _isAdLoaded = false;
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
        saveLocation(data, true);
        //  showAdverdisement();
        setState(() {
          isOpenGate = true;
          isSendRequest = true;
          isSendRequestToDevice = false;
          isLocationFailed = false;
        });
      }).timeout(Duration(seconds: 5));
    } on TimeoutException catch (_) {
      saveLocation(data, false);
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
          title: const Text('Kapılarım'),
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
                children: [
                  Image.asset(
                    "assets/images/app-logo.png",
                  )
                ],
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
                                  return Column(
                                    children: [
                                      dataList[index].Devices[j].isSiteActive ==
                                              1
                                          ? SlideAction(
                                              // ignore: sort_child_properties_last
                                              child: Container(
                                                margin:
                                                    EdgeInsets.only(left: 90),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    dataList[index]
                                                        .Devices[j]
                                                        .Name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              onSubmit: () {
                                                _playSound();
                                                _timer?.cancel();
                                                _data = dataList[index];
                                                setState(() {
                                                  isSendRequest = false;
                                                  isSendRequestToDevice = true;
                                                  isLocationFailed = false;
                                                });
                                                sendRequestToDevice(
                                                    _data.Devices[0]);
                                              },
                                              elevation: 2,
                                              borderRadius: 12,
                                              innerColor: Colors.white,
                                              outerColor: dataList[index]
                                                          .Devices[j]
                                                          .isSiteActive ==
                                                      1
                                                  ? kPrimaryColor
                                                  : Color.fromARGB(
                                                      255, 73, 3, 15),
                                              sliderButtonIcon: dataList[index]
                                                          .Devices[j]
                                                          .isSiteActive ==
                                                      1
                                                  ? const Icon(
                                                      Icons.arrow_forward)
                                                  : const Icon(Icons.power_off),
                                              submittedIcon: const Icon(
                                                Icons.check,
                                                color: Color.fromARGB(
                                                    255, 207, 204, 204),
                                              ),
                                              sliderRotate: false,
                                              alignment: Alignment.centerLeft,
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Color.fromARGB(
                                                    255, 73, 3, 15),
                                              ),
                                              height: 70,
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .only(left: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          color: Colors.white,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(15),
                                                        child: Icon(
                                                          Icons.power_off,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            left: 25),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              dataList[index]
                                                                  .Devices[j]
                                                                  .Name,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 15,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            Text(
                                                              "Elektrik kesintisi",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                    ],
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
                            const Icon(
                              Icons.check_circle,
                              size: 100.0,
                              color: Colors.green,
                            ),
                            const Text(
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
                                    const Text(
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
                                        const Spacer(),
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
                            const Icon(
                              Icons.remove_circle_outline_sharp,
                              size: 100.0,
                              color: Colors.red,
                            ),
                            const Text(
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
                      /* if (version != localVersion)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                "Hizmetlerimizden yararlanmak için lütfen yeni versiyonumuzu indirin."),
                            ElevatedButton(
                                onPressed: () async {
                                  if (Platform.isIOS) {
                                    const url =
                                        'https://apps.apple.com/us/app/ae-smart-systems/id6446314960'; //Twitter's URL
                                    await launch(url);
                                  } else {
                                    const url =
                                        'https://play.google.com/store/apps/details?id=com.mobile.remote_gate_control_mobile'; //Twitter's URL
                                    await launch(url);
                                  }
                                },
                                child: Text("Hemen İndir"))
                          ],
                        ),*/
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
            /* if (_isAdLoaded)
              Container(
                height: _bannerAd.size.height.toDouble(),
                width: _bannerAd.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd),
              ),*/
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
            if (_timer != null) _timer?.cancel();
            navigateUser();
          });
        },
      ),
    );
  }
}
