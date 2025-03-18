import 'package:flutter/material.dart';
import './iframe.dart';

class GIS extends StatefulWidget {
  const GIS({super.key});

  @override
  State<GIS> createState() => _GISState();
}

class _GISState extends State<GIS> {
  bool isLoading = false;
  bool hindi = true;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 15, 44, 41),
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 36, 69, 66),
        title: Text(hindi ? 'GIS Analysis' : "जीआईएस विश्लेषण",
            style: const TextStyle(color: Colors.white)),
        actions: [
          Center(
              child: Text(!hindi ? 'हिन्दी  ' : 'English ',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Switch(
            activeColor: const Color.fromARGB(255, 15, 44, 41),
            activeTrackColor: const Color.fromARGB(255, 219, 191, 157),
            inactiveThumbColor: const Color.fromARGB(255, 15, 44, 41),
            inactiveTrackColor: Colors.white,
            trackOutlineWidth: WidgetStateProperty.all(2),
            value: !hindi,
            onChanged: (value) {
              setState(() {
                hindi = !value;
              });
            },
          ),
          const SizedBox(width: 20)
        ],
      ),
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
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          if (!isLoading)
            SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Land Cover (Haryana)',
                          'भूमि आवरण (हरियाणा)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/land-cover-classification-and-mapping-in-haryana'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Land Use Transformation (Gurgaon)',
                          'भूमि उपयोग परिवर्तन (गुडगाँव)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/land-use-change-analysis-in-gurgaon'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Temporal Crop Analysis (Canada)',
                          'समयांतर फसल विश्लेषण (कनाडा)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/crop-type-change-detection-in-canada'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Evaportranspiration (World)',
                          'वायुपात परिवहन (विश्व)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/evapotranspiration-in-world-and-thailand'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'SMAP Soil Moisture (World)',
                          'एसएमएपी मृदा नमी (विश्व)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/smap-soil-moiture-world-and-south-sudan'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'SMAP Soil Moisture (Haryana)',
                          'एसएमएपी मृदा नमी (हरियाणा)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/smap-soil-moisture-in-haryana-10-meter-resolution'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Mineral Exploration (Haryana)',
                          'खनिज अन्वेषण (हरियाणा)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/mineral-exploration-in-haryana'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Mineral Exploration (Gurgaon)',
                          'खनिज अन्वेषण (गुडगाँव)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/mineral-exploration-in-gurgaon'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'LST & UHI Effects (Gurgaon)',
                          'भूगर्भिक ताप द्वीपक असर (गुडगाँव)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/lst--urban-heat-island-effect-analysis-in-gurgaon'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Groundwater Recharge (Haryana)',
                          'भूजल पुनर्चार्ज (हरियाणा)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/groundwater-recharge-analysis-in-haryana'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Paddy Field Classification (Tamil Nadu)',
                          'धान क्षेत्र वर्गीकरण (तमिलनाडु)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/paddy-field-classification'),
                      const SizedBox(height: 20),
                      gisProject(
                          context,
                          size,
                          hindi,
                          'Soil Loss (Haryana)',
                          'मृदा हानि (हरियाणा)',
                          'https://ee-aryan21csu017.projects.earthengine.app/view/soil-loss-using-rusle-modelling-in-haryana'),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InkWell gisProject(BuildContext context, Size size, bool hindi, String title,
      String hindiTitle, String url) {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Frame(
                    title: hindi ? title : hindiTitle,
                    iframeUrl: url,
                  ))),
      child: Card(
        color: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black,
        child: Container(
            height: 50,
            width: size.width,
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 219, 191, 157),
                borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              const SizedBox(
                width: 20,
              ),
              Text(
                hindi ? title : hindiTitle,
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
    );
  }
}
