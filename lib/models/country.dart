class Country {
  final int CountryId;
  final String CountryName;

  Country({required this.CountryId, required this.CountryName});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
        CountryId: json['countryId'], CountryName: json['countryName']);
  }
}
