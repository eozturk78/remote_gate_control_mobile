class Device {
  final String? SiteId;
  final String DeviceId;
  final String Name;
  final String Url;
  final String SSId;
  final String Password;

  const Device(
      {required this.SiteId,
      required this.DeviceId,
      required this.Name,
      required this.Url,
      required this.SSId,
      required this.Password});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
        SiteId: json['SiteId'],
        DeviceId: json['DeviceId'],
        Name: json['Name'],
        Url: json['Url'],
        SSId: json['SSId'],
        Password: json['Password']);
  }
}
