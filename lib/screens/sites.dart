import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:remote_gate_control_mobile/constants.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen(Key? key) : super(key: key);
  _SitesState createState() => _SitesState();
}

class _SitesState extends State<SitesScreen> {
  @override
  Widget build(BuildContext contect) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kayıtlı Olduğum Siteler'),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: Center(
        child: Text("siteler"),
      ),
    );
  }
}
