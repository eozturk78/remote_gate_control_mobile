import 'device.dart';

class Site {
  final String? Id;
  final String BuildingName;
  final String Address;
  final List<Device> Devices;
  final int IsActiveDevice;
  const Site(
      {required this.Id,
      required this.BuildingName,
      required this.Address,
      required this.Devices,
      required this.IsActiveDevice});

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
        Id: json['Id'],
        BuildingName: json['BuildingName'],
        Address: json['Address'],
        Devices: json['Devices'] != null
            ? (json['Devices'] as List).map((i) => Device.fromJson(i)).toList()
            : [],
        IsActiveDevice: json['Devices'] != null
            ? (json['Devices'] as List).first['isSiteActive']
            : 0);
  }
}
