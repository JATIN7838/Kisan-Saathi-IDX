import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class PredictCrop extends StatefulWidget {
  const PredictCrop({super.key});

  @override
  State<PredictCrop> createState() => _PredictCropState();
}

class _PredictCropState extends State<PredictCrop> {
  // function to read csv
  Future<void> readCropData() async {
    String csvData = await rootBundle.loadString('assets/Time_Series Data.csv');
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);
    Map<String, List<double>> data = {};
    // Skip the first row (header)
    for (var i = 1; i < rows.length; i++) {
      List<dynamic> row = rows[i];
      // DOY as key, humidity and temp as values
      data[row[1].toString()] = [
        double.parse(row[3].toString()),
        double.parse(row[4].toString())
      ];
    }
    DateTime now = DateTime.now();
    int dayOfYear = int.parse(DateFormat('D').format(now));
    setState(() {
      historicalData = data;
      humidity.text = data[dayOfYear.toString()]![0].toString();
      temperature.text = data[dayOfYear.toString()]![1].toString();
      rainfall.text = rainfallData[now.month]!.toString();
    });
  }

  @override
  void initState() {
    readCropData();
    super.initState();
  }

  Map<int, double> rainfallData = {
    1: 14.404,
    2: 14.404,
    3: 53.796,
    4: 53.796,
    5: 53.796,
    6: 108.29,
    7: 108.29,
    8: 108.29,
    9: 108.29,
    10: 14.404,
    11: 14.404,
    12: 14.404,
  };

  Map<String, List<double>> historicalData = {};
  TextEditingController nitrogen = TextEditingController();
  TextEditingController phosphorus = TextEditingController();
  TextEditingController potassium = TextEditingController();
  TextEditingController temperature = TextEditingController();
  TextEditingController humidity = TextEditingController();
  TextEditingController ph = TextEditingController();
  TextEditingController rainfall = TextEditingController();
  bool btnPressed = false;
  String crop = '';
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              setState(() {
                //clear all the text fields
                nitrogen.clear();
                phosphorus.clear();
                potassium.clear();
                temperature.clear();
                humidity.clear();
                ph.clear();
                rainfall.clear();
                btnPressed = false;
              });
            },
          ),
          backgroundColor: const Color.fromARGB(255, 64, 65, 66),
          title: const Text('Crop Prediction'),
        ),
        backgroundColor: const Color.fromARGB(255, 29, 29, 29),
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      formField('Nitrogen', nitrogen),
                      formField('Potassium', potassium)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      formField('Phosphorus', phosphorus),
                      formField('PH', ph)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      formField('Temp (C)', temperature),
                      formField('Humidity', humidity)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [formField('Rainfall', rainfall), continueBtn()],
                  ),
                  if (btnPressed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Predicted Crop :  ',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        Text(
                          crop,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                ]),
          ),
        ));
  }

  ElevatedButton continueBtn() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          backgroundColor: const Color(0xFF4E60FF),
          elevation: 8,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () async {
          try {
            // show loading indicator
            showDialog(
                context: context,
                builder: (context) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                });
            var data = [
              int.parse(nitrogen.text),
              int.parse(phosphorus.text),
              int.parse(potassium.text),
              double.parse(temperature.text),
              double.parse(humidity.text),
              double.parse(ph.text),
              double.parse(rainfall.text),
            ];

            var response = await http.post(
              Uri.parse('https://predict-crop-pw66dfxg7a-el.a.run.app'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode({
                'features': data,
              }),
            );
            // hide loading indicator
            if (mounted) {
              Navigator.pop(context);
            }
            setState(() {
              crop = jsonDecode(response.body)['prediction']
                  .toString()
                  .toUpperCase();
              btnPressed = true;
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(e.toString()),
              ));
            }
          }
        },
        child: const SizedBox(
            width: 130,
            height: 25,
            child: Center(
                child: Text(
              'Predict',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ))));
  }

  Row formField(title, controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '$title :',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color.fromARGB(255, 112, 126, 255)),
        ),
        const SizedBox(
          width: 5,
        ),
        SizedBox(
          width: 65,
          height: 30,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                contentPadding: EdgeInsets.only(bottom: 0, left: 2.5),
                fillColor: Colors.white,
                filled: true),
            style: const TextStyle(
                fontSize: 17, color: Colors.black, fontWeight: FontWeight.bold),
            textAlignVertical: TextAlignVertical.center,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
