import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'report_generated.dart';

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
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
  String crop = 'rice';
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
                crop = 'rice';
              });
            },
          ),
          backgroundColor: const Color.fromARGB(255, 64, 65, 66),
          title: const Text('Report Generation'),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      formField('Nitrogen', nitrogen),
                      formField('Potassium', potassium)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      formField('Phosphorus', phosphorus),
                      formField('PH', ph)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      formField('Temp (C)', temperature),
                      formField('Humidity', humidity)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      formField('Rainfall', rainfall),
                      dropDown(context)
                    ],
                  ),
                  continueBtn()
                ]),
          ),
        ));
  }

  Theme dropDown(BuildContext context) {
    return Theme(
      data: Theme.of(context)
          .copyWith(canvasColor: const Color.fromARGB(255, 2, 2, 2)),
      child: DropdownButton<String>(
        value: crop,
        onChanged: (value) {
          setState(() {
            crop = value!;
          });
        },
        underline: Card(
          elevation: 12,
          color: Colors.transparent,
          child: Container(
            height: 2,
            color: Colors.white,
          ),
        ),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: Colors.white,
        ),
        style: const TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(
              value: 'rice',
              child: Text('RICE', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'maize',
              child: Text('MAIZE', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'banana',
              child: Text('BANANA', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'mango',
              child: Text('MANGO', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'grapes',
              child: Text('GRAPES', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'coffee',
              child: Text('COFFEE', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
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
          // post request with the data
          try {
            // show loading indicator
            showDialog(
                context: context,
                builder: (context) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                });
            var data = {
              'N': int.parse(nitrogen.text),
              'P': int.parse(phosphorus.text),
              'K': int.parse(potassium.text),
              'temperature': double.parse(temperature.text),
              'humidity': double.parse(humidity.text),
              'ph': double.parse(ph.text),
              'rainfall': double.parse(rainfall.text),
              'crop_type': crop
            };

            var response = await http.post(
              Uri.parse('https://generate-report-pw66dfxg7a-el.a.run.app'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(data),
            );
            // hide loading indicator
            if (mounted) {
              Navigator.pop(context);
            }
            Map<String, dynamic> report = jsonDecode(response.body);
            report['crop'] = crop;
            var snap = await FirebaseFirestore.instance
                .collection('Irrigation System')
                .doc('Optimal Range')
                .get();
            report['range'] = snap.data()![crop];
            if (mounted) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GeneratedReport(data: report)));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(e.toString()),
              ));
            }
          }
        },
        child: const SizedBox(
            width: 150,
            height: 25,
            child: Center(
                child: Text(
              'Generate Report',
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
