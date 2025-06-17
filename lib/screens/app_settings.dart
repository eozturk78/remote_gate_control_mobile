import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/screens/delete_my_account.dart';
import 'package:remote_gate_control_mobile/screens/login.dart';
import 'package:remote_gate_control_mobile/screens/site_list.dart';
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'change_password.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen(Key? key) : super(key: key);

  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool notificationState = false;
  bool closeAppAfterOpenGate = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCheckStates();
  }

  getCheckStates() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    notificationState = pref.getBool("notificationState") ?? true;
    closeAppAfterOpenGate = pref.getBool("closeAppAfterOpenGate") ?? true;
    setState(() {});
  }

  updatCloseAppAfterOpenGate(bool closeAppAfterOpenGate) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool("closeAppAfterOpenGate", closeAppAfterOpenGate);
    showToast("Başarıyla kaydedildi");
  }

  updateUserNtfState(bool notificationState) async {
    Apis apis = Apis();
    SharedPreferences pref = await SharedPreferences.getInstance();
    await apis.updateNotificationState(notificationState).then((value) {
      pref.setBool("notificationState", notificationState);
      showToast("Başarıyla kaydedildi");
    });
  }

  @override
  Widget build(BuildContext contect) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Uygılama Ayarları"),
          backgroundColor: kPrimaryColor,
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(15),
          child: Center(
            child: Column(
              children: [
                Row(
                  children: [
                    Text("Kapı Açıldıktan Sonra Uygulamayı Kapat"),
                    Spacer(),
                    CupertinoSwitch(
                      value: closeAppAfterOpenGate,
                      onChanged: (value) {
                        setState(() {
                          closeAppAfterOpenGate = value;
                          updatCloseAppAfterOpenGate(value);
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Text("Bildirimler"),
                    Spacer(),
                    CupertinoSwitch(
                      value: notificationState,
                      onChanged: (value) {
                        setState(() {
                          notificationState = value;
                          updateUserNtfState(value);
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
