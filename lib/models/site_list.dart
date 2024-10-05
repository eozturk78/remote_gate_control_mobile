import 'device.dart';

class SiteList {
  final String? SiteId;
  final String BuildingName;
  final String Address;
  final int SiteUserCount;
  const SiteList({
    required this.SiteId,
    required this.BuildingName,
    required this.Address,
    required this.SiteUserCount,
  });

  factory SiteList.fromJson(Map<String, dynamic> json) {
    return SiteList(
      SiteId: json['siteId'],
      BuildingName: json['buildingName'],
      Address: json['address'],
      SiteUserCount: json['siteUserCount'],
    );
  }
}
