import 'dart:async';

import 'package:clima/Const.dart';
import 'package:clima/pages/ClimateForNexDay.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart'; // Asegúrate de usar la ruta correcta

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedLanguage = LANGUAGES[0]; // Idioma por defecto
  String _selectedCountry = COUNTRIES[0]; // País por defecto

  WeatherFactory? _wf;
  StreamController<Weather?> _weatherStreamController = StreamController<Weather?>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
  }

  Future<void> _fetchLocationAndWeather() async {
    Position position = await _determinePosition();
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    String countryName = placemarks.first.country ?? 'Unknown Country';

    setState(() {
      _selectedCountry = countryName;
    });

    _fetchWeather();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return Future.error('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  void _fetchWeather() {
    setState(() {
      _isLoading = true;
    });

    _wf = WeatherFactory(
      OPENWEATHER_API_KEY,
      language: _selectedLanguage == 'es' ? Language.SPANISH : Language.ENGLISH,
    );

    _wf!.currentWeatherByCityName(_selectedCountry).then((weather) {
      _weatherStreamController.add(weather);
    }).catchError((error) {
      _weatherStreamController.addError(error);
    }).whenComplete(() {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _refreshWeather() {
    _fetchWeather();
  }

  @override
  void dispose() {
    _weatherStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.06),
              _buildDropdowns(),
              Expanded(
                child: StreamBuilder<Weather?>(
                  stream: _weatherStreamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData) {
                      return const Center(child: Text('No weather data available.'));
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _locationHeader(snapshot.data!),
                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.002),
                        _dateTimeInfo(snapshot.data!),
                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.03),
                        _weatherIcon(snapshot.data!),
                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
                        _currentTiemp(snapshot.data!),
                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.001),
                        _extraInfo(snapshot.data!),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: MediaQuery.sizeOf(context).width * 0.15,
            right: MediaQuery.sizeOf(context).width * 0.15,
            child: _refreshButton(),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdowns() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonFormField<String>(
                value: _selectedLanguage,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                    _fetchWeather();
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: Colors.blueAccent,
                style: const TextStyle(color: Colors.white),
                items: LANGUAGES.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value == 'es' ? 'Español' : 'English'),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonFormField<String>(
                value: _selectedCountry,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCountry = newValue!;
                    _fetchWeather();
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: Colors.blueAccent,
                style: const TextStyle(color: Colors.white),
                items: COUNTRIES.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _refreshButton() {
  return ElevatedButton(
    onPressed: _refreshWeather,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 3, 119, 61), // Color de fondo del botón
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      textStyle: const TextStyle(
        fontSize: 18,
        color: Color.fromARGB(255, 255, 255, 255), // Color del texto
      ),
    ),
    child: const Text("Actualizar"),
  );
}


  Widget _extraInfo(Weather weather) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.15,
      width: MediaQuery.sizeOf(context).width * 0.80,
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClimateForNexday(selectedCountry: _selectedCountry, selectedLanguage: _selectedLanguage)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: const TextStyle(fontSize: 18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Max: ${weather.tempMax?.celsius?.toStringAsFixed(0)}° C",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Min: ${weather.tempMin?.celsius?.toStringAsFixed(0)}° C",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "VelMax: ${weather.windSpeed?.toStringAsFixed(0)} m/s",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Humedad: ${weather.humidity?.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentTiemp(Weather weather) {
    return Text(
      "${weather.tempFeelsLike?.celsius?.toStringAsFixed(0)}° C",
      style: const TextStyle(
        color: Colors.black,
        fontSize: 90,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _weatherIcon(Weather weather) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: MediaQuery.sizeOf(context).height * 0.20,
          width: MediaQuery.sizeOf(context).height * 0.20,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                  "http://openweathermap.org/img/wn/${weather.weatherIcon}@4x.png"),
            ),
            color: const Color.fromARGB(255, 231, 122, 19).withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Text(
          weather.weatherDescription ?? "",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _dateTimeInfo(Weather weather) {
    DateTime now = weather.date!;
    
    return Column(
      children: [
        Text(
          DateFormat("h:mm a").format(now),
          style: const TextStyle(fontSize: 35),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat("EEEE").format(now),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              " ${DateFormat("d MMMM y").format(now)}",
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _locationHeader(Weather weather) {
    return Text(
      weather.areaName ?? "",
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
