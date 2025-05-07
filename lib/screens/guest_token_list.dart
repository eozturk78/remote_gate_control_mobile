// ignore_for_file: unnecessary_new, deprecated_member_use, avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pultix_mobile/apis/apis.dart';
import 'package:pultix_mobile/constants.dart';
import 'package:pultix_mobile/models/guest_token_detail.dart';
import 'package:pultix_mobile/models/site_user.dart';
import 'package:pultix_mobile/screens/guest_token_detail.dart';
import 'package:pultix_mobile/screens/user_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestTokenListScreen extends StatefulWidget {
  const GuestTokenListScreen({Key? key}) : super(key: key);
  @override
  _GuestTokenListScreenState createState() => _GuestTokenListScreenState();
}

class _GuestTokenListScreenState extends State<GuestTokenListScreen> {
  List<GuestTokenDetailRecord> dataList = [];
  TextEditingController search = new TextEditingController();
  @override
  void initState() {
    super.initState();
    getGuestTokenList(null);
  }

  Timer? _debounce;

  @override
  void dispose() {
    search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  getGuestTokenList(String? searchText) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    Apis apis = Apis();
    dataList.clear();
    await apis.getGuestTokenList().then((value) {
      setState(() {
        print(value);
        if (value['records'] != null) {
          dataList = (value['records'] as List)
              .map((e) => GuestTokenDetailRecord.fromJson(e))
              .toList();
        }
      });
    });
  }

  var isLocationFailed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Misafir Anahtarları'),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              SharedPreferences pref = await SharedPreferences.getInstance();
              pref.remove("GuestTokenId");
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GuestTokenDetailScreen(null)))
                  .then((v) => {getGuestTokenList(search.text)});
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
                if (dataList.length > 0)
                  Column(
                    children: [
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: dataList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                              onTap: () async {},
                              child: Container(
                                padding: EdgeInsets.all(15),
                                margin:
                                    const EdgeInsets.only(bottom: 5, top: 5),
                                decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 204, 204, 204),
                                    borderRadius: BorderRadius.circular(15)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (dataList[index].ExpirationDate != null)
                                      Text(
                                          '${dataList[index].ExpirationDate!.day.toString()}.${dataList[index].ExpirationDate!.month.toString()}.${dataList[index].ExpirationDate!.year.toString()}'),
                                    Text(dataList[index].Duration.toString()),
                                    SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ),
                              ));
                        },
                      ),
                    ],
                  )
                else
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text("Eklenmiş bir misafir anahtarı yok")])
              ],
            )),
      ),
    );
  }
}
