import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:remote_gate_control_mobile/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Apis {
  String lang = 'tr-TR';
  String baseUrl = 'https://api.aesmartsystems.com', serviceName = 'User';
  Future login(String email, String password) async {
    String finalUrl = '$baseUrl/$serviceName/Login';
    var params = {'email': email.toString(), 'password': password.toString()};
    var result = await http.post(Uri.parse(finalUrl),
        body: jsonEncode(params),
        headers: {'Content-Type': 'application/json', 'lang': lang});
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        showToast(body['ErrorMessage']);
        throw Exception(body['ErrorMessage']);
      }
      return body['Response'];
    } else {
      showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }

  Future sendRequestTeltonika(String imei, String hexCode) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl =
        '$baseUrl/sendrequestteltonika?imei=$imei&hexCode=$hexCode';
    var result = await http.get(Uri.parse(finalUrl),
        headers: {'token': pref.getString('token').toString(), 'lang': lang});
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        showToast(body['ErrorMessage']);
        throw Exception(body['ErrorMessage']);
      }
      return body['Response'];
    } else {
      showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }

  Future getSiteUrlList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/$serviceName/GetSiteUrlList';
    var result = await http.post(Uri.parse(finalUrl), headers: {
      'Content-Type': 'application/json',
      'token': pref.getString('token').toString(),
      'lang': lang
    });
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        showToast(body['ErrorMessage']);
        throw Exception(body['ErrorMessage']);
      }
      return body['Response'];
    } else {
      showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }

  Future sendOpenDoorRequest(double? lat, double? long) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/$serviceName/SendOpenGateRequest';
    var params = {'lat': lat, 'long': long};
    var result = await http
        .post(Uri.parse(finalUrl), body: jsonEncode(params), headers: {
      'Content-Type': 'application/json',
      'token': pref.getString('token').toString(),
      'lang': lang
    });
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        if (body['ErrorCode'] == 106) {
          pref.clear();
          showToast(body['ErrorMessage']);
          throw TimeoutException(body['ErrorMessage']);
        } else {
          throw Exception(body['ErrorMessage']);
        }
      }
      return body['Response'];
    } else {
      // showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }

  Future forgotPassword(String email) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/$serviceName/ForgotPassword';
    var params = {'email': email.toString()};
    var result = await http.post(Uri.parse(finalUrl),
        body: jsonEncode(params),
        headers: {'Content-Type': 'application/json', 'lang': lang});
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        if (body['ErrorCode'] == 106) pref.clear();
        showToast(body['ErrorMessage']);
        throw Exception(body['ErrorMessage']);
      }
      return body['Response'];
    } else {
      showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }

  Future changePassword(String oldPassword, String newPassword) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/$serviceName/ChangePassword';
    var params = {
      'oldPassword': oldPassword.toString(),
      'newPassword': newPassword.toString()
    };
    var result = await http
        .post(Uri.parse(finalUrl), body: jsonEncode(params), headers: {
      'Content-Type': 'application/json',
      'token': pref.getString('token').toString(),
      'lang': lang
    });
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        if (body['ErrorCode'] == 106) pref.clear();
        showToast(body['ErrorMessage']);
        throw Exception(body['ErrorMessage']);
      }
      return body['Response'];
    } else {
      showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }

  Future getGateRequestCount() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/$serviceName/GetGateRequestCount';
    var result = await http.post(Uri.parse(finalUrl), headers: {
      'Content-Type': 'application/json',
      'token': pref.getString('token').toString(),
      'lang': lang
    });
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        if (body['ErrorCode'] == 106) pref.clear();
        showToast(body['ErrorMessage']);
        throw Exception(body['ErrorMessage']);
      }
      return body['Response'];
    } else {
      showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }

  Future deleteMyAccount() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/$serviceName/DeleteMyAccount';
    var result = await http.post(Uri.parse(finalUrl), headers: {
      'Content-Type': 'application/json',
      'token': pref.getString('token').toString(),
      'lang': lang
    });
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        if (body['ErrorCode'] == 106) pref.clear();
        showToast(body['ErrorMessage']);
        throw Exception(body['ErrorMessage']);
      }
      return body['Response'];
    } else {
      showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }

  Future saveErrorLog(String errorLog) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/$serviceName/ErrorLog';
    var result = await http.post(Uri.parse(finalUrl), body: errorLog, headers: {
      'Content-Type': 'application/json',
      'token': pref.getString('token').toString(),
      'lang': lang
    });
    var body = jsonDecode(result.body);
    if (result.statusCode == 200) {
      if (!body['IsSuccess']) {
        if (body['ErrorCode'] == 106) pref.clear();
        showToast(body['ErrorMessage']);
        throw Exception(body['ErrorMessage']);
      }
      return body['Response'];
    } else {
      showToast("something went wrong");
      throw Exception("Something went wrong");
    }
  }
}
