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

  Future sendOpenDoorRequest(double? lat, double? long, String? siteId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/$serviceName/SendOpenGateRequest';
    var params = {'lat': lat, 'long': long, 'SiteId': siteId};
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

  Future getSiteManagerSiteList() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/Site/GetSiteManagerSiteList';
    var result = await http.get(Uri.parse(finalUrl), headers: {
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

  Future getSiteManagerSiteDetails(String siteId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl =
        '$baseUrl/Site/GetSiteManagerSiteDetails?siteId=${siteId}';
    var result = await http.get(Uri.parse(finalUrl), headers: {
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

  Future getSiteUserList(String siteId, String? searchText) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/Site/GetSiteUserList?siteId=${siteId}';
    if (searchText != null) finalUrl += '&searchText=${searchText}';
    var result = await http.get(Uri.parse(finalUrl), headers: {
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

  Future getSiteUserDetails(String siteUserId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl =
        '$baseUrl/Site/GetSiteUserDetails?siteUserId=${siteUserId}';
    var result = await http.get(Uri.parse(finalUrl), headers: {
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

  Future setSiteUser(String? siteId, String? siteUserId, String userTitle,
      String phoneNumber, String email) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/Site/SetSiteUser';
    var params = {
      'siteId': siteId.toString(),
      'siteUserId': siteUserId ?? null,
      'userTitle': userTitle.toString(),
      'phoneNumber': phoneNumber.toString(),
      'email': email.toString(),
    };
    print(params);
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

  Future setSiteManagerSite(
      String? siteId,
      String buildingName,
      int? countryId,
      int? cityId,
      String address,
      String vehicleCapacity,
      String description) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String finalUrl = '$baseUrl/Site/SetSiteManagerSite';
    var params = {
      'siteId': siteId.toString(),
      'buildingName': buildingName.toString(),
      'countryId': countryId,
      'cityId': cityId.toString(),
      'address': address.toString(),
      'vehicleCapacity': vehicleCapacity,
      'description': description,
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
