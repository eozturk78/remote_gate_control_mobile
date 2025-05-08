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

class SiteDetail extends StatefulWidget {
  const SiteDetail(Key? key) : super(key: key);
  @override
  _SiteDetailState createState() => _SiteDetailState();
}

class _SiteDetailState extends State<SiteDetail> {
  Apis apis = Apis();
  TextEditingController buildName = new TextEditingController();
  TextEditingController address = new TextEditingController();
  TextEditingController vehicleCapacity = new TextEditingController();
  TextEditingController description = new TextEditingController();
  bool isSiteDetailSuccess = false;
  SiteDetailRecord? siteDetail;
  List<Country>? countries;
  List<City>? cities;

  Country? _selectedCountry;
  City? _selectedCity;
  @override
  void initState() {
    super.initState();
    getSiteDetail();
  }

  getSiteDetail() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    Apis apis = Apis();
    await apis
        .getSiteManagerSiteDetails(pref.getString("siteId")!)
        .then((value) {
      setState(() {
        siteDetail = SiteDetailRecord.fromJson(value['records'][0]);

        countries = (value['countries'] as List)
            .map((e) => Country.fromJson(e))
            .toList();

        _selectedCountry = countries!
            .where((a) => a.CountryId == siteDetail?.CountryId)
            ?.first;

        cities =
            (value['cities'] as List).map((e) => City.fromJson(e)).toList();

        _selectedCity =
            cities!.where((a) => a.CityId == siteDetail?.CityId)?.first;
        buildName.text = siteDetail!.BuildingName;
        address.text = siteDetail!.Address;
        if (siteDetail!.VehicleCapacity != null) {
          vehicleCapacity.text = siteDetail!.VehicleCapacity.toString();
        }
        if (siteDetail!.Description != null) {
          description.text = siteDetail!.Description!;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Site Bilgileri"),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              TextFormField(
                controller: buildName,
                decoration: const InputDecoration(
                  labelText: 'Bina Adı',
                ),
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: description,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                ),
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: vehicleCapacity,
                decoration: const InputDecoration(
                  labelText: 'Araç Kapasitesi',
                ),
              ),
              SizedBox(
                height: 5,
              ),
              DropdownSearch<String>(
                showSearchBox: true,
                items: countries?.map((e) => e.CountryName).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = countries
                        ?.where((element) => element.CountryName == value)
                        .first;
                  });
                },
                label: "Ülke",
                selectedItem: _selectedCountry?.CountryName,
                dropdownSearchDecoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              DropdownSearch<String>(
                showSearchBox: true,
                items: cities?.map((e) => e.CityName).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = cities
                        ?.where((element) => element.CityName == value)
                        .first;
                  });
                },
                label: "Şehir",
                selectedItem: _selectedCity?.CityName,
                dropdownSearchDecoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              TextFormField(
                controller: address,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                ),
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
                      .setSiteManagerSite(
                          siteDetail?.SiteId,
                          buildName.text,
                          _selectedCountry?.CountryId,
                          _selectedCity?.CityId,
                          address.text,
                          vehicleCapacity.text,
                          description.text)
                      .then((resp) {
                    if (resp != null && resp['records'] != null) {
                      showToast("Başarıyla kaydedildi");
                    }
                    Navigator.pop(context);
                  })
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
