class City {
  final int CityId;
  final int CountryId;
  final String CityName;

  City({required this.CityId, required this.CityName, required this.CountryId});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
        CityId: json['cityId'],
        CityName: json['cityName'],
        CountryId: json['countryId']);
  }
}
