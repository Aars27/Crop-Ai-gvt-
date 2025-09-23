class WeatherData {
  final double temperature;
  final double soilTemperature;
  final int humidity;
  final double windSpeed;
  final int precipitation;
  final String sunrise;
  final String sunset;
  final String location;
  final String weatherCondition;

  WeatherData({
    required this.temperature,
    required this.soilTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.sunrise,
    required this.sunset,
    required this.location,
    required this.weatherCondition,
  });

  factory WeatherData.fromOpenWeatherMap(Map<String, dynamic> json) {
    // Extract main weather data
    final mainData = json['main'] ?? {};
    final weatherArray = json['weather'] ?? [];
    final windData = json['wind'] ?? {};
    final sysData = json['sys'] ?? {};
    final name = json['name'] ?? 'Lucknow';

    // Get weather condition from the first weather item in array
    String condition = 'clear';
    if (weatherArray.isNotEmpty) {
      condition = weatherArray[0]['main']?.toString().toLowerCase() ?? 'clear';
    }

    // Convert unix timestamps to readable time strings
    String formatTimeFromUnix(int timestamp) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final period = date.hour >= 12 ? 'pm' : 'am';
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    }

    // Sunrise and sunset times
    String sunrise = '7:00 am';
    String sunset = '6:00 pm';
    if (sysData['sunrise'] != null) {
      sunrise = formatTimeFromUnix(sysData['sunrise']);
    }
    if (sysData['sunset'] != null) {
      sunset = formatTimeFromUnix(sysData['sunset']);
    }

    // Calculate precipitation chance (not directly available in current weather)
    // Using clouds percentage as an approximation
    final clouds = json['clouds']?['all'] ?? 0;

    return WeatherData(
      // Convert temperature from Kelvin to Celsius
      temperature: (mainData['temp']?.toDouble() ?? 273.15) - 273.15,
      // Soil temperature is not available in this API, approximate it
      soilTemperature: ((mainData['temp']?.toDouble() ?? 273.15) - 273.15) - 2, // Typically a few degrees cooler than air
      humidity: mainData['humidity']?.toInt() ?? 0,
      windSpeed: windData['speed']?.toDouble() ?? 0.0,
      precipitation: clouds, // Using cloud coverage as proxy for precipitation chance
      sunrise: sunrise,
      sunset: sunset,
      location: name,
      weatherCondition: condition,
    );
  }
}