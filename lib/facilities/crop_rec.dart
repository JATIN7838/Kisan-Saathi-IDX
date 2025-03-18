import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';

class CropRecommendationPage extends StatefulWidget {
  const CropRecommendationPage({super.key});

  @override
  State<CropRecommendationPage> createState() => _CropRecommendationPageState();
}

class _CropRecommendationPageState extends State<CropRecommendationPage> {
  final translator = GoogleTranslator();
  bool isHindi = false; // Language toggle (false = English, true = Hindi)
  List<Map<String, dynamic>> crops = [];
  String timestamp = "";

  @override
  void initState() {
    super.initState();
    _fetchCropRecommendations();
  }

  // Fetch crop recommendations from Firestore
  Future<void> _fetchCropRecommendations() async {
    final firestore = FirebaseFirestore.instance;

    try {
      DocumentSnapshot cropDoc =
          await firestore.collection('IOT').doc('Crop Recommendation').get();

      if (cropDoc.exists) {
        final data = cropDoc.data() as Map<String, dynamic>;
        final fetchedCrops = <Map<String, dynamic>>[];

        // Extract crop fields and translate if necessary
        for (var key in data.keys) {
          if (key != "timestamp") {
            final cropData = data[key] as Map<String, dynamic>;
            final translatedCropName = isHindi
                ? (await translator.translate(key, to: 'hi')).text
                : key;

            final translatedLevels = {
              "Groundwater": isHindi
                  ? (await translator.translate(cropData['Groundwater'],
                          to: 'hi'))
                      .text
                  : cropData['Groundwater'],
              "Rainfall": isHindi
                  ? (await translator.translate(cropData['Rainfall'], to: 'hi'))
                      .text
                  : cropData['Rainfall'],
              "Water Quality": isHindi
                  ? (await translator.translate(cropData['Water Quality'],
                          to: 'hi'))
                      .text
                  : cropData['Water Quality'],
            };

            fetchedCrops.add({
              "Name": translatedCropName,
              "Cost": cropData['Cost'],
              "Income": cropData['Income'],
              ...translatedLevels
            });
          } else {
            timestamp = data['timestamp'];
          }
        }

        setState(() {
          crops = fetchedCrops;
        });
      } else {
        setState(() {
          crops = [];
          timestamp = "No timestamp available.";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
        ));
      }
    }
  }

  // Toggle language and refresh content
  void _toggleLanguage() async {
    setState(() {
      isHindi = !isHindi;
    });
    await _fetchCropRecommendations();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(isHindi ? 'फसल सहायक' : "Crop Advisor",
            style: const TextStyle(color: Colors.white)),
        actions: [
          Center(
              child: Text(isHindi ? 'हिन्दी  ' : 'English ',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Switch(
            activeColor: const Color.fromARGB(255, 15, 44, 41),
            activeTrackColor: const Color.fromARGB(255, 219, 191, 157),
            inactiveThumbColor: const Color.fromARGB(255, 15, 44, 41),
            inactiveTrackColor: Colors.white,
            trackOutlineWidth: WidgetStateProperty.all(2),
            value: isHindi,
            onChanged: (value) {
              _toggleLanguage();
            },
          ),
          const SizedBox(width: 20)
        ],
      ),
      body: crops.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !isHindi ? "Time: $timestamp" : 'समय: $timestamp',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(
                              label: Text(
                            isHindi ? 'फसल' : "Crop",
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataColumn(
                              label: Text(
                            isHindi ? 'लागत' : "Cost",
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataColumn(
                              label: Text(
                            isHindi ? 'कमाई' : "Income",
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataColumn(
                              label: Text(
                            isHindi ? 'भूजल' : "Groundwater",
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataColumn(
                              label: Text(
                            isHindi ? 'बारिश' : "Rainfall",
                            style: const TextStyle(color: Colors.white),
                          )),
                          DataColumn(
                              label: Text(
                                  isHindi ? 'पानी गुणवत्ता' : "Water Quality",
                                  style: const TextStyle(color: Colors.white))),
                        ],
                        rows: crops
                            .map((crop) => DataRow(cells: [
                                  DataCell(Text(
                                    crop["Name"],
                                    style: const TextStyle(color: Colors.white),
                                  )),
                                  DataCell(Text(
                                    crop["Cost"].toString(),
                                    style: const TextStyle(color: Colors.white),
                                  )),
                                  DataCell(Text(
                                    crop["Income"].toString(),
                                    style: const TextStyle(color: Colors.white),
                                  )),
                                  DataCell(Text(
                                    crop["Groundwater"],
                                    style: const TextStyle(color: Colors.white),
                                  )),
                                  DataCell(Text(
                                    crop["Rainfall"],
                                    style: const TextStyle(color: Colors.white),
                                  )),
                                  DataCell(Text(
                                    crop["Water Quality"],
                                    style: const TextStyle(color: Colors.white),
                                  )),
                                ]))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
