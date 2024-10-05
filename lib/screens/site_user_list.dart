// ignore_for_file: unnecessary_new, deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/constants.dart';
import 'package:remote_gate_control_mobile/models/site_user.dart';
import 'package:remote_gate_control_mobile/screens/login.dart';
import 'package:remote_gate_control_mobile/screens/profile.dart';
import 'package:remote_gate_control_mobile/screens/site_detail.dart';
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../models/device.dart';
import '../models/site.dart';
import '../models/site_list.dart';

class SiteUserListScreen extends StatefulWidget {
  const SiteUserListScreen({Key? key}) : super(key: key);
  @override
  _SiteUserListScreenState createState() => _SiteUserListScreenState();
}

class _SiteUserListScreenState extends State<SiteUserListScreen> {
  List<SiteUser> dataList = [];
  @override
  void initState() {
    super.initState();
    getSiteUserList();
  }

  getSiteUserList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    Apis apis = Apis();
    await apis.getSiteUserList(pref.getString("siteId")!).then((value) {
      setState(() {
        print(value['records']);
        dataList = (value['records'] as List)
            .map((e) => SiteUser.fromJson(e))
            .toList();
      });
    });
  }

  var isLocationFailed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: ListView.builder(
        shrinkWrap: true,
        itemCount: dataList.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 204, 204, 204),
                borderRadius: BorderRadius.circular(15)),
            margin:
                const EdgeInsets.only(left: 15, bottom: 5, right: 15, top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dataList[index].UserTitle),
                SizedBox(
                  height: 5,
                ),
                Text(dataList[index].PhoneNumber ?? ""),
                SizedBox(
                  height: 5,
                ),
                Text(dataList[index].Email ?? ""),
                SizedBox(
                  height: 5,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
