import 'device.dart';

class SiteUser {
  final String? SiteUserId;
  final String UserTitle;
  final String Email;
  final String PhoneNumber;
  final String Description;
  const SiteUser({
    required this.SiteUserId,
    required this.UserTitle,
    required this.Email,
    required this.PhoneNumber,
    required this.Description,
  });

  factory SiteUser.fromJson(Map<String, dynamic> json) {
    return SiteUser(
        SiteUserId: json['siteUserId'],
        UserTitle: json['userTitle'],
        Email: json['email'],
        PhoneNumber: json['phoneNumber'].toString() ?? "",
        Description: json['description'] ?? "");
  }
}
