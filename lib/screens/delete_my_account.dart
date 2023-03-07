import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DeleteMyAcccountScreen extends StatefulWidget {
  const DeleteMyAcccountScreen(Key? key) : super(key: key);

  @override
  _DeleteMyAccountState createState() => _DeleteMyAccountState();
}

class _DeleteMyAccountState extends State<DeleteMyAcccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hesap Sil"),
        centerTitle: true,
      ),
      body: Column(
        children: const [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 100.0,
          ),
          SizedBox(
            height: 20,
          ),
          Center(
            child: Text(
              "Hesap silme isteğiniz alındı.",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
