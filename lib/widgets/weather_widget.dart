import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';
import '../services/city_database_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  final CityDatabaseService _cityService = CityDatabaseService();
  
  WeatherInfo? _weatherInfo;
  City? _selectedCity;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 获取选中的城市
      _selectedCity = await _weatherService.getSelectedCity();
      
      // 如果没有选中城市，使用默认城市（北京）
      if (_selectedCity == null) {
        final defaultCity = await _cityService.getCityById('101010100');
        if (defaultCity != null) {
          _selectedCity = defaultCity;
          await _weatherService.saveSelectedCity(defaultCity);
        }
      }

      if (_selectedCity != null) {
        // 获取天气信息
        final weatherInfo = await _weatherService.getWeatherInfo(_selectedCity!.cityNum);
        
        setState(() {
          _weatherInfo = weatherInfo;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '无法获取城市信息';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '获取天气信息失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshWeather() async {
    await _weatherService.clearWeatherCache();
    await _loadWeatherData();
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CitySelectionSheet(
        onCitySelected: (city) async {
          await _weatherService.saveSelectedCity(city);
          await _loadWeatherData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildWeatherContent(),
    );
  }

  Widget _buildWeatherContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeatherData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_weatherInfo == null || _selectedCity == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              '暂无天气信息',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击选择城市',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCitySelector,
              icon: const Icon(Icons.location_city),
              label: const Text('选择城市'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 城市和刷新按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _showCitySelector,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCity!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refreshWeather,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                tooltip: '刷新天气',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 当前天气信息
          if (_weatherInfo!.forecast != null)
            Row(
              children: [
                // 天气图标和温度
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _weatherService.getWeatherIcon(
                              _weatherInfo!.forecast!.weather1,
                            ),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_weatherInfo!.currentTemp}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weatherInfo!.forecast!.weather1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 详细信息
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildWeatherDetail(
                        '最高',
                        _weatherInfo!.forecast!.temp1.split('~').last.replaceAll('℃', ''),
                      ),
                      _buildWeatherDetail(
                        '最低',
                        _weatherInfo!.forecast!.temp1.split('~').first.replaceAll('℃', ''),
                      ),
                      if (_weatherInfo!.forecast!.weather1.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '健康提醒',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          
          // 未来几天预报
          if (_weatherInfo!.forecast != null) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white30),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  if (index == 0) return const SizedBox.shrink();
                  
                  final dayWeather = _weatherInfo!.forecast!.getDayWeather(index + 1);
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text(
                          '第${index + 1}天',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _weatherService.getWeatherIcon(dayWeather.weather),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayWeather.weather,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayWeather.temp,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('日');
      if (parts.isNotEmpty) {
        final dayMonth = parts[0];
        final monthDay = dayMonth.split('月');
        if (monthDay.length == 2) {
          return '${monthDay[0]}/${monthDay[1]}';
        }
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }
}

// 城市选择弹窗
class CitySelectionSheet extends StatefulWidget {
  final Function(City) onCitySelected;

  const CitySelectionSheet({
    Key? key,
    required this.onCitySelected,
  }) : super(key: key);

  @override
  State<CitySelectionSheet> createState() => _CitySelectionSheetState();
}

class _CitySelectionSheetState extends State<CitySelectionSheet> {
  final CityDatabaseService _cityService = CityDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  List<City> _searchResults = [];
  List<City> _popularCities = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPopularCities();
  }

  Future<void> _loadPopularCities() async {
    setState(() => _isLoading = true);
    
    try {
      final cities = await _cityService.getPopularCities();
      setState(() {
        _popularCities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchCities(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final results = await _cityService.searchCitiesByName(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text(
                  '选择城市',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索城市名称',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _searchCities,
            ),
          ),
          
          // 城市列表
          Expanded(
            child: _buildCityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCityList() {
    if (_isLoading || _isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final cities = _searchController.text.trim().isNotEmpty 
        ? _searchResults 
        : _popularCities;

    if (cities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.trim().isNotEmpty 
                  ? '未找到相关城市' 
                  : '暂无城市数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        return ListTile(
          leading: const Icon(Icons.location_city),
          title: Text(city.name),
          subtitle: Text('城市代码: ${city.cityNum}'),
          onTap: () {
            widget.onCitySelected(city);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}