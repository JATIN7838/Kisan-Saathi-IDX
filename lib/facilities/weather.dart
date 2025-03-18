import 'package:flutter/material.dart';
import './api.dart';

class Weather extends StatefulWidget {
  const Weather({super.key});

  @override
  State<Weather> createState() => _WeatherState();
}

class _WeatherState extends State<Weather> {
  Future fetchWeather() async {
    API api = API(location: 'Gurgaon');
    var data = await api.getForecastWeather(location: api.location);
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                )),
            backgroundColor: const Color.fromARGB(255, 36, 69, 66),
            title: const Text(
              'Weather Forecast',
              style: TextStyle(color: Colors.white),
            )),
        backgroundColor: const Color.fromARGB(255, 15, 44, 41),
        body: Stack(
          children: [
            Container(
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            FutureBuilder(
              future: fetchWeather(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // While waiting for data, you can show a placeholder or loading indicator
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No Data'));
                }
                var data = snapshot.data;
                var forecast = data['forecast']['forecastday'][0]['day'];
                return Center(
                  child: SizedBox(
                    width: size.width * 0.85,
                    height: size.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: size.height * 0.05,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Location :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    data['location']['name'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Condition :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    data['current']['condition']['text']
                                        .toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Wind Speed (km/h) :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    data['current']['wind_kph'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Humidity :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    data['current']['humidity'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AQI(pm2.5|pm10): ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    '${data['current']['air_quality']['pm2_5']}  |  ${data['current']['air_quality']['pm10']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Precipitation (mm) :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    forecast['totalprecip_mm'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'snow (cm) :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    forecast['totalsnow_cm'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chance of Rain  :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    forecast['daily_chance_of_rain'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chance of Snow :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    forecast['daily_chance_of_snow'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Probable Condition :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    forecast['condition']['text'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Max Temp (C):  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    forecast['maxtemp_c'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Min Temp (C) :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    forecast['mintemp_c'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Max Wind Speed (km/h) :  ',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 18),
                                  ),
                                  Text(
                                    forecast['maxwind_kph'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.05,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ));
  }
}
