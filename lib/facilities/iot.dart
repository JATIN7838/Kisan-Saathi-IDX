import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';

import 'crop_rec.dart';

class IOT extends StatefulWidget {
  const IOT({super.key});

  @override
  IOTState createState() => IOTState();
}

class IOTState extends State<IOT> {
  final translator = GoogleTranslator();
  bool isHindi = false; // Language toggle (false = English, true = Hindi)
  String botResponse = "";
  String userQuery = "";
  String timestamp = "";

  @override
  void initState() {
    super.initState();
    _fetchFertilizerRecommendation();
  }

  // Fetch data from Firestore
  Future<void> _fetchFertilizerRecommendation() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Fetch Fertilizer Recommendation
      DocumentSnapshot fertilizerDoc = await firestore
          .collection('IOT')
          .doc('Fertilizer Recommendation')
          .get();

      if (fertilizerDoc.exists) {
        final data = fertilizerDoc.data() as Map<String, dynamic>;
        final botResponseText = data['bot_response'] ?? 'No data available';
        final userQueryText = data['user_query'] ?? 'No query provided';
        final timestampText = data['timestamp'] ?? 'No timestamp available';

        // Translate if needed
        final translatedBotResponse = isHindi
            ? (await translator.translate(botResponseText, to: 'hi')).text
            : botResponseText;

        final translatedUserQuery = isHindi
            ? (await translator.translate(userQueryText, to: 'hi')).text
            : userQueryText;

        setState(() {
          botResponse = translatedBotResponse;
          userQuery = translatedUserQuery;
          timestamp = timestampText;
        });
      } else {
        setState(() {
          botResponse = "No Fertilizer Recommendation found.";
          userQuery = "No query available.";
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
    await _fetchFertilizerRecommendation();
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
        title: Text(isHindi ? 'आईओटी डेटा' : "IOT Data",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                !isHindi ? "Fertilizer Recommendation" : "खाद सलाह",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                !isHindi ? "Time: $timestamp" : 'समय: $timestamp',
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                !isHindi ? "Response: $botResponse" : 'जवाब: $botResponse',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 10),
              // crop recommendations card
              InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CropRecommendationPage())),
                child: Card(
                  color: Colors.transparent,
                  elevation: 8,
                  shadowColor: Colors.black,
                  child: Container(
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 219, 191, 157),
                          borderRadius: BorderRadius.circular(12)),
                      height: 50,
                      width: size.width,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 20,
                            ),
                            const CircleAvatar(
                              backgroundImage:
                                  AssetImage('assets/registerCrop.png'),
                            ),
                            Text(
                              !isHindi ? '    Crop Advisor' : "    फसल सहायक",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right,
                              size: 30,
                              color: Colors.black,
                            )
                          ])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
