import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/screens/delete_my_account.dart';
import 'package:remote_gate_control_mobile/screens/login.dart';
import 'package:remote_gate_control_mobile/screens/site_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'change_password.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen(Key? key) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? email = "";
  int? requestCount = 0;
  bool? isSiteManager = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getOpenGateRequestCount();
    getEmail();
  }

  getEmail() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      email = pref.getString("email");
      isSiteManager = pref.getBool("isSiteManager");
    });
  }

  getOpenGateRequestCount() async {
    Apis apis = Apis();
    await apis.getGateRequestCount().then((value) {
      setState(() {
        requestCount = value['RequestCount'];
      });
    });
  }

  @override
  Widget build(BuildContext contect) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Profil"),
          backgroundColor: kPrimaryColor,
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(15),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.person,
                  size: 100,
                ),
                Text(
                  email!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 20,
                ),
                Text('Kapı açma sayısı $requestCount'),
                SizedBox(
                  height: 150,
                ),
                if (isSiteManager == true)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: kPrimaryColor,
                    ),
                    onPressed: () => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SiteListScreen()))
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 24,
                        ),
                        Text("Kullanıcıları Yönet")
                      ],
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: kPrimaryColor,
                  ),
                  child: Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.password_outlined,
                          size: 24,
                        ),
                        Text("Şifremi Değiştir"),
                      ],
                    ),
                  ),
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePassword(null),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.lock,
                          size: 24,
                        ),
                        Text("Oturumu Kapat"),
                      ],
                    ),
                  ),
                  onPressed: () async {
                    SharedPreferences pref =
                        await SharedPreferences.getInstance();

                    await pref.clear();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => const Login(null))));
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () async {
                    Apis apis = Apis();
                    await apis.deleteMyAccount().then((value) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: ((context) =>
                                  const DeleteMyAcccountScreen(null))));
                    });
                  },
                  child: const Text('Hesabımı Sil'),
                ),
              ],
            ),
          ),
        ));
  }
}
