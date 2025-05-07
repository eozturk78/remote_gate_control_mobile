// ignore_for_file: unnecessary_new, deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pultix_mobile/apis/apis.dart';
import 'package:pultix_mobile/constants.dart';
import 'package:pultix_mobile/models/site_user.dart';
import 'package:pultix_mobile/screens/login.dart';
import 'package:pultix_mobile/screens/profile.dart';
import 'package:pultix_mobile/screens/site_detail.dart';
import 'package:pultix_mobile/screens/user_detail.dart';
import 'package:pultix_mobile/toast.dart';
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
  TextEditingController search = new TextEditingController();
  @override
  void initState() {
    super.initState();
    getSiteUserList(null);
  }

  Timer? _debounce;

  @override
  void dispose() {
    search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  getSiteUserList(String? searchText) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    Apis apis = Apis();
    dataList.clear();
    await apis
        .getSiteUserList(pref.getString("siteId")!, searchText)
        .then((value) {
      setState(() {
        if (value['records'] != null)
          dataList = (value['records'] as List)
              .map((e) => SiteUser.fromJson(e))
              .toList();
      });
    });
  }

  onSearch(String searchText) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      // Trigger your search or API call here
      getSiteUserList(searchText);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              SharedPreferences pref = await SharedPreferences.getInstance();
              pref.remove("siteUserId");
              Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserDetail(null)))
                  .then((v) => {getSiteUserList(search.text)});
              ;
            },
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 15, bottom: 5, right: 15, top: 5),
        child: SingleChildScrollView(
            physics: ScrollPhysics(),
            child: Column(
              children: [
                TextFormField(
                  controller: search,
                  onChanged: onSearch,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Ara',
                  ),
                ),
                Column(
                  children: [
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: dataList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                            onTap: () async {
                              SharedPreferences pref =
                                  await SharedPreferences.getInstance();

                              pref.setString(
                                  "siteId", dataList[index].SiteId.toString());

                              pref.setString("siteUserId",
                                  dataList[index].SiteUserId.toString());

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => UserDetail(null)),
                              ).then((v) => {getSiteUserList(search.text)});
                            },
                            child: Container(
                              padding: EdgeInsets.all(15),
                              margin: const EdgeInsets.only(bottom: 5, top: 5),
                              decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 204, 204, 204),
                                  borderRadius: BorderRadius.circular(15)),
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
                            ));
                      },
                    ),
                  ],
                ),
              ],
            )),
      ),
    );
  }
}
