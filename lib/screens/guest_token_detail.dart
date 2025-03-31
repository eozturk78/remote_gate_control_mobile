import 'package:dropdown_search2/dropdown_search2.dart';
import 'package:flutter/material.dart';
import 'package:remote_gate_control_mobile/apis/apis.dart';
import 'package:remote_gate_control_mobile/models/device.dart';
import 'package:remote_gate_control_mobile/models/guest_token_detail.dart';
import 'package:remote_gate_control_mobile/models/site.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class GuestTokenDetailScreen extends StatefulWidget {
  const GuestTokenDetailScreen(Key? key) : super(key: key);
  @override
  _GuestTokenDetailState createState() => _GuestTokenDetailState();
}

class _GuestTokenDetailState extends State<GuestTokenDetailScreen> {
  Apis apis = Apis();

  TextEditingController address = new TextEditingController();
  TextEditingController vehicleCapacity = new TextEditingController();
  TextEditingController description = new TextEditingController();
  bool isGuestTokenDetailSuccess = false;
  GuestTokenDetailRecord? guestTokenDetail;
  List<Device>? devices = [];
  List<Site>? sites;
  bool isOneTimeUsedToken = false;
  Device? _selectedDevice;
  String? _selectedDuration;
  List<String>? durationList = [];
  @override
  void initState() {
    super.initState();
    getGuestTokenDetail();
  }

  getGuestTokenDetail() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    Apis apis = Apis();
    var guestTokenId = pref.getString("guestTokenId");

    await apis.getGuestTokenDetails(guestTokenId).then((value) {
      setState(() {
        if (value['records'] != null) {
          guestTokenDetail =
              GuestTokenDetailRecord.fromJson(value['records'][0]);
        }

        sites = (value['sites'] as List).map((e) => Site.fromJson(e)).toList();

        for (var e in (value['durationDays'] as List)) {
          durationList?.add(e['value']);
        }

        sites?.forEach((site) {
          site.Devices?.forEach((d) {
            setState(() {
              devices?.add(d);
            });
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Misafir Anahtarı"),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownSearch<String>(
                showSearchBox: true,
                items: devices?.map((e) => e.Name).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDevice = devices
                        ?.where((element) => element.Name == value)
                        .first;
                  });
                },
                label: "Site",
                selectedItem: _selectedDevice?.Name,
                dropdownSearchDecoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              DropdownSearch<String>(
                showSearchBox: false,
                items: durationList,
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value;
                  });
                },
                label: 'Süre (Geçerli Gün)',
                selectedItem: _selectedDuration,
                dropdownSearchDecoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text("Tek Seferlik Anahtar"),
              Switch(
                // This bool value toggles the switch.
                value: isOneTimeUsedToken,
                activeColor: Colors.red,
                onChanged: (bool value) {
                  // This is called when the user toggles the switch.
                  setState(() {
                    isOneTimeUsedToken = value;
                  });
                },
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: kPrimaryColor,
                ),
                onPressed: () => {
                  if (_selectedDevice != null && _selectedDuration != null)
                    {
                      apis
                          .setGuestToken(_selectedDevice!.DeviceId,
                              _selectedDuration!, isOneTimeUsedToken)
                          .then((resp) {
                        print(resp);
                      })
                    }
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
