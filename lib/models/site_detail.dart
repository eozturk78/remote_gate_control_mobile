import 'device.dart';

class SiteDetailRecord {
  final String? SiteId;
  final String BuildingName;
  final String Address;
  final int CityId;
  final int CountryId;
  final String? Description;
  final int? VehicleCapacity;
  const SiteDetailRecord({
    required this.SiteId,
    required this.BuildingName,
    required this.Address,
    required this.CityId,
    required this.CountryId,
    required this.Description,
    required this.VehicleCapacity,
  });

  factory SiteDetailRecord.fromJson(Map<String, dynamic> json) {
    return SiteDetailRecord(
      SiteId: json['siteId'],
      BuildingName: json['buildingName'],
      Address: json['address'],
      CityId: json['cityId'],
      CountryId: json['countryId'],
      Description: json['description'],
      VehicleCapacity: json['vehicleCapacity'],
    );
  }
}
