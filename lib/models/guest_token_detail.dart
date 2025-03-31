import 'device.dart';

class GuestTokenDetailRecord {
  final String? GuestTokenId;
  final String? SiteId;
  final String? GuestToken;
  final DateTime? ExpirationDate;
  final String? Url;
  final int? Duration;
  final bool? IsExpired;

  const GuestTokenDetailRecord(
      {required this.GuestTokenId,
      required this.SiteId,
      required this.GuestToken,
      required this.ExpirationDate,
      required this.Url,
      required this.Duration,
      required this.IsExpired});

  factory GuestTokenDetailRecord.fromJson(Map<String, dynamic> json) {
    return GuestTokenDetailRecord(
      GuestTokenId: json['guestTokenId'],
      GuestToken: json['gateToken'],
      ExpirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
      SiteId: json['siteId'],
      Url: json['url'],
      Duration: json['duration'],
      IsExpired: json['isExpired'],
    );
  }
}
