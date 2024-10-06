import 'dart:ui';

import 'package:dropdown_search2/dropdown_search2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/screens/forgot_password.dart';
import 'package:remote_gate_control_mobile/screens/main.dart';
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../models/site_detail.dart';
import '../models/user_detail.dart';

class UserDetail extends StatefulWidget {
  const UserDetail(Key? key) : super(key: key);
  @override
  _UserDetailState createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  Apis apis = Apis();
  TextEditingController userTitle = new TextEditingController();
  TextEditingController email = new TextEditingController();
  TextEditingController phoneNumber = new TextEditingController();
  bool isUserDetailSuccess = false;
  UserDetailRecord? userDetail;
  String siteId = "";
  String siteUserId = "";
  @override
  void initState() {
    super.initState();
    getUserDetail();
  }

  getUserDetail() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    siteId = pref.getString("siteId")!;
    if (pref.getString("siteUserId") != null) {
      siteUserId = pref.getString("siteUserId")!;
      Apis apis = Apis();
      await apis
          .getSiteUserDetails(pref.getString("siteUserId")!)
          .then((value) {
        setState(() {
          if (value['records'] != null) {
            userDetail = UserDetailRecord.fromJson(value['records'][0]);
            userTitle.text = userDetail!.UserTitle;
            email.text = userDetail!.Email;
            phoneNumber.text = userDetail!.PhoneNumber;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kullanıcı Bilgileri"),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              TextFormField(
                controller: userTitle,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                ),
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: phoneNumber,
                decoration: const InputDecoration(
                  labelText: 'Telefon No',
                ),
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              SizedBox(
                height: 5,
              ),
              SizedBox(
                height: 30,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: kPrimaryColor,
                ),
                onPressed: () => {
                  apis
                      .setSiteUser(
                    siteId,
                    userDetail?.SiteUserId ?? null,
                    userTitle.text,
                    phoneNumber.text,
                    email.text,
                  )
                      .then((resp) {
                    print(resp);
                    if (resp != null) {
                      showToast("Başarıyla kaydedildi");
                    }
                    print(siteUserId);
                    Navigator.pop(context);
                  }) /**/
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text("Kaydet")],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
