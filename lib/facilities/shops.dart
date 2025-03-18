import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class Shops extends StatefulWidget {
  const Shops({super.key});

  @override
  State<Shops> createState() => _ShopsState();
}

class _ShopsState extends State<Shops> {
  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')));
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<List> getNearbyShops(String product, double lat, double lon) async {
    var url = Uri.parse('https://fetch-nearest-shops-pw66dfxg7a-el.a.run.app');

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'product': product, 'lat': lat, 'lon': lon}),
      );
      var fixedJson = response.body.replaceAll('NaN', 'null');

      var data = jsonDecode(fixedJson);
      for (var shop in data) {
        var phone = shop['phone'];
        if (phone != 'null' && phone != null && phone.runtimeType == double) {
          shop['phone'] = phone.toInt();
        } else {
          shop['phone'] = '-';
        }
      }

      return data;
    } catch (e) {
      return [e.toString()];
    }
  }

  List shops = [];
  String product = 'Fertilizers';
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 15, 44, 41),
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        backgroundColor: const Color.fromARGB(255, 36, 69, 66),
        title: const Text(
          'Nearby Shops',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SizedBox(
          height: size.height * 0.9,
          width: size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 15),
                  dropDown(),
                  const SizedBox(width: 15),
                  searchBtn(context),
                ],
              ),
              const SizedBox(height: 10),
              shopList(size),
            ],
          )),
    );
  }

  Expanded shopList(Size size) {
    return Expanded(
      child: ListView.builder(
          itemCount: shops.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
              child: Card(
                color: Colors.transparent,
                elevation: 8,
                shadowColor: Colors.black,
                child: Container(
                    height: 120,
                    width: size.width,
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 219, 191, 157),
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Name:  ',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    shops[index]['company'],
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 20, 121, 110),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                const Text('Website:  ',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      if (await canLaunchUrl(
                                          Uri.parse(shops[index]['Website']))) {
                                        await launchUrl(
                                            Uri.parse(shops[index]['Website']));
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Could not launch Website')));
                                        }
                                      }
                                    },
                                    child: Text(
                                      shops[index]['Website'],
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 34, 156,
                                            255), // Make the text blue
                                        decoration: TextDecoration
                                            .underline, // Underline the text
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                const Text('Address:  ',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    shops[index]['short_address'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                const Text('Phone:  ',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    shops[index]['phone'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                    )),
              ),
            );
          }),
    );
  }

  Container dropDown() {
    return Container(
      height: 40,
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 203, 203, 203),
      ),
      child: Center(
        child: DropdownButton<String>(
          value: product,
          icon: const Icon(Icons.arrow_downward),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(color: Colors.black),
          onChanged: (val) {
            setState(() {
              product = val!;
            });
          },
          items: <String>[
            'Fertilizers',
            'Pesticides',
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            );
          }).toList(),
        ),
      ),
    );
  }

  SizedBox searchBtn(BuildContext context) {
    return SizedBox(
      height: 45,
      width: 45,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.blue,
            elevation: 8,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () async {
            if (await requestLocationPermission()) {
              final position = await getCurrentLocation();
              setState(() {
                shops = [];
              });
              if (context.mounted) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    });
              }
              final data = await getNearbyShops(
                  product.toLowerCase(), position.latitude, position.longitude);
              if (context.mounted) {
                Navigator.pop(context);
              }
              if (data[0].runtimeType == String) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(data[0])));
                }
              }
              setState(() {
                shops = data;
              });
            }
          },
          child: const Icon(
            Icons.search,
            color: Colors.white,
            size: 25,
          )),
    );
  }
}
