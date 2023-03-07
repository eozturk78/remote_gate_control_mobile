import 'device.dart';

class Site {
  final String? Id;
  final String BuildingName;
  final String Address;
  final List<Device> Devices;
  const Site(
      {required this.Id,
      required this.BuildingName,
      required this.Address,
      required this.Devices});

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      Id: json['Id'],
      BuildingName: json['BuildingName'],
      Address: json['Address'],
      Devices:
          (json['Devices'] as List).map((i) => Device.fromJson(i)).toList(),
    );
  }
}
