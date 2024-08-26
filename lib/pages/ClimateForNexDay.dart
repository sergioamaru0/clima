import 'package:clima/Const.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';

class ClimateForNexday extends StatefulWidget {
  final String selectedCountry;
  final String selectedLanguage;

  const ClimateForNexday({
    super.key,
    required this.selectedCountry,
    required this.selectedLanguage,
  });

  @override
  State<ClimateForNexday> createState() => _ClimateNextDayState();
}

class _ClimateNextDayState extends State<ClimateForNexday> {
  late Future<List<Weather>> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _forecastFuture = _fetchForecast();
  }

  Future<List<Weather>> _fetchForecast() async {
    final wf = WeatherFactory(
      OPENWEATHER_API_KEY,
      language: widget.selectedLanguage == 'es' ? Language.SPANISH : Language.ENGLISH,
    );

    final forecast = await wf.fiveDayForecastByCityName(widget.selectedCountry);
    return forecast;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiempo 3 dias siguientes'),
      ),
      body: FutureBuilder<List<Weather>>(
        future: _forecastFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No forecast data available.'));
          }

          // Filtrar el pronóstico para los próximos tres días
          final threeDayForecast = snapshot.data!.take(3).toList();

          return ListView.builder(
            itemCount: threeDayForecast.length,
            itemBuilder: (context, index) {
              final weather = threeDayForecast[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                color: const Color.fromARGB(255, 29, 199, 241).withOpacity(0.5),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: Image.network(
                    "http://openweathermap.org/img/wn/${weather.weatherIcon}@2x.png",
                    height: MediaQuery.sizeOf(context).height * 0.15,
                    width: MediaQuery.sizeOf(context).width * 0.15,
                    fit: BoxFit.cover,
                  ),
                  title: Text(DateFormat('yyyy-MM-dd').format(weather.date!)),
                  subtitle: Text(weather.weatherDescription ?? ""),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Max: ${weather.tempMax?.celsius?.toStringAsFixed(0)}° C",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Min: ${weather.tempMin?.celsius?.toStringAsFixed(0)}° C",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
