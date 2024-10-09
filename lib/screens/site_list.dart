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
import 'package:remote_gate_control_mobile/screens/login.dart';
import 'package:remote_gate_control_mobile/screens/profile.dart';
import 'package:remote_gate_control_mobile/screens/site_detail.dart';
import 'package:remote_gate_control_mobile/screens/site_user_list.dart';
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../models/device.dart';
import '../models/site.dart';
import '../models/site_list.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({Key? key}) : super(key: key);
  @override
  _SiteListScreenState createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  List<SiteList> dataList = [];
  @override
  void initState() {
    super.initState();
    getSiteManagerSiteList();
  }

  getSiteManagerSiteList() async {
    Apis apis = Apis();
    await apis.getSiteManagerSiteList().then((value) {
      setState(() {
        dataList = (value['records'] as List)
            .map((e) => SiteList.fromJson(e))
            .toList();
        print(dataList[0].BuildingName);
      });
    });
  }

  var isLocationFailed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Yönetimi'),
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
            margin: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dataList[index].BuildingName),
                SizedBox(
                  height: 5,
                ),
                Text(dataList[index].Address),
                SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Icon(Icons.person),
                    Text(dataList[index].SiteUserCount.toString()),
                    Spacer(),
                    SizedBox(
                      width: 5,
                    ),
                    GestureDetector(
                        onTap: () async {
                          SharedPreferences pref =
                              await SharedPreferences.getInstance();
                          pref.setString(
                              "siteId", dataList[index].SiteId.toString());
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SiteDetail(null)),
                          ).then((onValue) => getSiteManagerSiteList());
                        },
                        child: Text("Bilgileri Güncelle"))
                  ],
                ),
                GestureDetector(
                    onTap: () async {
                      SharedPreferences pref =
                          await SharedPreferences.getInstance();
                      pref.setString(
                          "siteId", dataList[index].SiteId.toString());
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SiteUserListScreen()),
                      );
                    },
                    child: Text("Kullanıcılara Git"))
              ],
            ),
          );
        },
      ),
    );
  }
}
