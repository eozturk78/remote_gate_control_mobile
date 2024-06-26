import 'dart:ffi';

class Device {
  final String? SiteId;
  final String DeviceId;
  final String SerialNumber;
  final String Name;
  final String Url;
  final String SSId;
  final String Password;
  final double? lat;
  final double? long;
  final bool? remoteControl;
  final bool? IsTeltonika;
  final String? HexCode;

  const Device(
      {required this.SiteId,
      required this.DeviceId,
      required this.SerialNumber,
      required this.Name,
      required this.Url,
      required this.SSId,
      required this.Password,
      this.lat,
      this.long,
      this.remoteControl,
      required this.IsTeltonika,
      required this.HexCode});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      SiteId: json['SiteId'],
      DeviceId: json['DeviceId'],
      SerialNumber: json['SerialNumber'] ?? "",
      Name: json['Name'],
      Url: json['Url'],
      SSId: json['SSId'],
      Password: json['Password'],
      lat: json['Lat'],
      long: json['Long'],
      remoteControl: json['RemoteControl'],
      IsTeltonika: json['IsTeltonika'],
      HexCode: json['HexCode'],
    );
  }
}
