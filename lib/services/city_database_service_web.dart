class CityDatabaseService {
  CityDatabaseService();

  Future<List<Province>> getAllProvinces() async => [];
  Future<Province?> getProvinceByName(String provinceName) async => null;
  Future<List<City>> getCitiesByProvinceId(int provinceId) async => [];
  Future<List<City>> getAllCities() async => [];
  Future<List<City>> getPopularCities() async => [];
  Future<List<City>> searchCitiesByName(String cityName) async => [];
  Future<City?> getCityById(String cityId) async => null;
  Future<void> close() async {}
  Future<Map<String, int>> getDatabaseStats() async => {'provinces': 0, 'cities': 0};
}

class Province {
  final int id;
  final String name;
  Province({required this.id, required this.name});
}

class City {
  final int id;
  final int provinceId;
  final String name;
  final String cityNum;
  City({required this.id, required this.provinceId, required this.name, required this.cityNum});
}