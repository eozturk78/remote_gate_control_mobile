import 'device.dart';

class UserDetailRecord {
  final String? SiteUserId;
  final String SiteId;
  final String Email;
  final String UserTitle;
  final String PhoneNumber;
  const UserDetailRecord(
      {required this.SiteUserId,
      required this.SiteId,
      required this.Email,
      required this.UserTitle,
      required this.PhoneNumber});

  factory UserDetailRecord.fromJson(Map<String, dynamic> json) {
    return UserDetailRecord(
        SiteUserId: json['siteUserId'],
        SiteId: json['siteId'],
        Email: json['email'],
        UserTitle: json['userTitle'],
        PhoneNumber: json['phoneNumber']?.toString() ?? "");
  }
}
