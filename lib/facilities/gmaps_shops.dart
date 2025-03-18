// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class GMapShops extends StatefulWidget {
  const GMapShops({super.key});

  @override
  GMapShopsState createState() => GMapShopsState();
}

class GMapShopsState extends State<GMapShops> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  String _selectedProduct = 'Select';
  final List<String> _productList = [
    'Select',
    'Fertilizer',
    'Pesticide',
    'Soil Testing'
  ];
  bool _isLoading = true;
  int _radius = 5000;
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> reset() async {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    setState(() {});
    _adjustCameraBounds();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _isLoading = false;
    });
  }

  void _launchMaps(double lat, double lng) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch maps'),
          ),
        );
      }
    }
  }

  Future<void> _getNearbyShops(double lat, double lng) async {
    if (_selectedProduct == 'Select') {
      await reset();
      return;
    }
    String apiKey = dotenv.env['gmap']!;
    String type = _selectedProduct.toLowerCase();
    if (type == 'soil testing') {
      type = 'soil testing service';
    }
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=$_radius&type=store&keyword=$type&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] != 'OK') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(json['status'] == 'ZERO_RESULTS'
                  ? 'No Results Found'
                  : 'Error : ${json['error_message']}'),
            ),
          );
        }
        await reset();
        return;
      }
      final results = json['results'] as List;
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(lat, lng),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        for (var place in results) {
          final marker = Marker(
            markerId: MarkerId(place['place_id']),
            position: LatLng(place['geometry']['location']['lat'],
                place['geometry']['location']['lng']),
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: '${place['vicinity']}',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(place['name']),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          place['photos'] != null && place['photos'].isNotEmpty
                              ? Image.network(
                                  'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${place['photos'][0]['photo_reference']}&key=$apiKey')
                              : Container(),
                          Text('Rating: ${place['rating'] ?? 'N/A'}'),
                          Text(place['vicinity']),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                        TextButton(
                          onPressed: () {
                            _launchMaps(
                              place['geometry']['location']['lat'],
                              place['geometry']['location']['lng'],
                            );
                          },
                          child: const Text('Get Directions'),
                        ),
                        TextButton(
                          onPressed: () {
                            final lat = place['geometry']['location']['lat'];
                            final lng = place['geometry']['location']['lng'];
                            final url =
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                            _launchURL(url);
                          },
                          child: const Text('Open in Maps'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
          _markers.add(marker);
        }
      });
      _adjustCameraBounds();
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _adjustCameraBounds() {
    if (_markers.isEmpty || _currentPosition == null) return;

    if (_markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    } else {
      LatLngBounds bounds;
      var southwestLat = _currentPosition!.latitude;
      var southwestLng = _currentPosition!.longitude;
      var northeastLat = _currentPosition!.latitude;
      var northeastLng = _currentPosition!.longitude;

      for (var marker in _markers) {
        var markerLat = marker.position.latitude;
        var markerLng = marker.position.longitude;

        if (markerLat < southwestLat) southwestLat = markerLat;
        if (markerLng < southwestLng) southwestLng = markerLng;
        if (markerLat > northeastLat) northeastLat = markerLat;
        if (markerLng > northeastLng) northeastLng = markerLng;
      }

      bounds = LatLngBounds(
        southwest: LatLng(southwestLat, southwestLng),
        northeast: LatLng(northeastLat, northeastLng),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

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
      body: Stack(children: [
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
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 10),
                  inputArea(),
                  const SizedBox(height: 10),
                  mapsArea(),
                  const SizedBox(
                    height: 10,
                  )
                ],
              )
      ]),
    );
  }

  Expanded mapsArea() {
    return Expanded(
      child: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
          setState(() {
            _markers.add(
              Marker(
                markerId: const MarkerId('user_location'),
                position: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                infoWindow: const InfoWindow(title: 'Your Location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
              ),
            );
          });
        },
        initialCameraPosition: _currentPosition != null
            ? CameraPosition(
                target: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 14.0,
              )
            : const CameraPosition(
                target: LatLng(0.0, 0.0),
                zoom: 2.0,
              ),
        markers: _markers,
      ),
    );
  }

  Row inputArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 219, 191, 157),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButton<String>(
              underline: const SizedBox(),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.black,
              ),
              value: _selectedProduct,
              items: _productList.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedProduct = newValue!;
                  if (_selectedProduct == 'Soil Testing') {
                    _radius = 15000;
                  }
                });
                if (_currentPosition != null) {
                  _getNearbyShops(
                      _currentPosition!.latitude, _currentPosition!.longitude);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 20),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 219, 191, 157),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.black),
                onPressed: () {
                  setState(() {
                    if (_radius > 1000) _radius -= 1000;
                  });
                  if (_currentPosition != null) {
                    _getNearbyShops(_currentPosition!.latitude,
                        _currentPosition!.longitude);
                  }
                },
              ),
              Text('${_radius / 1000} Km',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _radius += 1000;
                  });
                  if (_currentPosition != null) {
                    _getNearbyShops(_currentPosition!.latitude,
                        _currentPosition!.longitude);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
