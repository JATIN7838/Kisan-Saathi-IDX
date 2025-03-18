import 'package:flutter/material.dart';

class ROI extends StatefulWidget {
  final bool english;
  const ROI({super.key, required this.english});

  @override
  State<ROI> createState() => _ROIState();
}

class _ROIState extends State<ROI> {
  late bool english = widget.english;
  bool selected = false;
  late String areaUnit = english ? 'Hectare' : 'हेक्टेयर';
  late String crop = english ? 'Rice' : 'चावल';
  late String season = english ? 'Kharif' : 'खरीफ';
  late String village = english ? 'Nasirpu' : 'नसीरपुर';
  late String district = english ? 'Ambala' : 'अंबाला';
  late String farming = english ? 'Commercial' : 'वाणिज्यिक';

  TextEditingController waterQuality = TextEditingController();
  TextEditingController area = TextEditingController();
  late List<String> areaUnitList = english
      ? [
          'Hectare',
          'Acre',
          'Bigha',
          'Gaj',
          'Sq. Feet',
          'Sq. Meter',
        ]
      : [
          'हेक्टेयर',
          'एकड़',
          'बीघा',
          'गज',
          'वर्ग फीट',
          'वर्ग मीटर',
        ];
  late List<String> cropList = english
      ? [
          'Rice',
          'Jowar',
          'Bajra',
          'Maize',
          'Wheat',
          'Barley',
          'Gram',
          'Cotton',
        ]
      : [
          'चावल',
          'ज्वार',
          'बाजरा',
          'मक्का',
          'गेहूं',
          'जौ',
          'चना',
          'कपास',
        ];
  late Map<String, double> cropYieldData = english
      ? {
          'Rice': 3435.6,
          'Jowar': 525.2,
          'Maize': 2967.4,
          'Bajra': 2118.4,
          'Wheat': 4765,
          'Gram': 1156,
          'Barley': 3590.4,
          'Cotton': 449.4,
        }
      : {
          'चावल': 3435.6,
          'ज्वार': 525.2,
          'मक्का': 2967.4,
          'बाजरा': 2118.4,
          'गेहूं': 4765,
          'चना': 1156,
          'जौ': 3590.4,
          'कपास': 449.4,
        };
  double convertToHectare(double value, String unit) {
    switch (unit) {
      case 'Hectare':
        return value;
      case 'Acre':
        return value * 0.404686; // 1 acre = 0.404686 hectares
      case 'Bigha':
        return value * 0.677966; // 1 bigha = 0.677966 hectares
      case 'Gaj':
        return value * 0.000009305; // 1 gaj = 0.000009305 hectares
      case 'Sq. Feet':
        return value * 0.00000929; // 1 sq. feet = 0.00000929 hectares
      case 'Sq. Meter':
        return value * 0.0001; // 1 sq. meter = 0.0001 hectares
      //hindi
      case 'हेक्टेयर':
        return value;
      case 'एकड़':
        return value * 0.404686; // 1 acre = 0.404686 hectares
      case 'बीघा':
        return value * 0.677966; // 1 bigha = 0.677966 hectares
      case 'गज':
        return value * 0.000009305; // 1 gaj = 0.000009305 hectares
      case 'वर्ग फीट':
        return value * 0.00000929; // 1 sq. feet = 0.00000929 hectares
      case 'वर्ग मीटर':
        return value * 0.0001; // 1 sq. meter = 0.0001 hectares
      default:
        throw ArgumentError('Invalid unit');
    }
  }

  late Map<String, int> cropMsp = english
      ? {
          'Rice': 2183,
          'Jowar': 3180,
          'Bajra': 2500,
          'Maize': 2090,
          'Wheat': 2275,
          'Barley': 1850,
          'Gram': 5440,
          'Cotton': 6620
        }
      : {
          'चावल': 2183,
          'ज्वार': 3180,
          'बाजरा': 2500,
          'मक्का': 2090,
          'गेहूं': 2275,
          'जौ': 1850,
          'चना': 5440,
          'कपास': 6620
        };
  late Map<String, int> cropCostList = english
      ? {
          'Rice': 1360,
          'Jowar': 1977,
          'Bajra': 1268,
          'Cotton': 4053,
          'Wheat': 1065,
          'Barley': 1082,
          'Gram': 3206,
          'Maize': 1308,
        }
      : {
          'चावल': 1360,
          'ज्वार': 1977,
          'बाजरा': 1268,
          'कपास': 4053,
          'गेहूं': 1065,
          'जौ': 1082,
          'चना': 3206,
          'मक्का': 1308,
        };
  late Map<String, int> villageWaterQty = english
      ? {
          'Nasirpur': 450,
          'Bhurangpur': 2250,
          'Bound Kalan': 5300,
          'Birhi Kalan': 2400,
          'Naraungabad': 6200
        }
      : {
          'नसीरपुर': 450,
          'भुरंगपुर': 2250,
          'बाउंड कलां': 5300,
          'बिरही कलां': 2400,
          'नरौंगाबाद': 6200
        };
  double cropYield = 0;
  double cropCost = 0;
  double cropReturn = 0;
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
        title: Text(english ? 'ROI' : 'आय कैलकुलेटर',
            style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
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
          SizedBox(
            height: size.height * 0.95,
            width: size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  toggleItem(),
                  fieldSections(size),
                  ouputSection(size),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Column ouputSection(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          width: size.width * 0.9,
          color: const Color.fromARGB(255, 219, 191, 157),
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            const SizedBox(
              width: 15,
            ),
            Text(
              selected
                  ? (english ? 'Expected Return' : 'अपेक्षित आय')
                  : (english ? 'Expected Investment' : 'अपेक्षित निवेश'),
              style: const TextStyle(
                  color: Color.fromARGB(255, 219, 191, 157),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              ' :  ₹ ${selected ? cropReturn.toStringAsFixed(2) : cropCost.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Color.fromARGB(255, 113, 255, 118),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            const SizedBox(
              width: 15,
            ),
            Text(
              english ? 'Expected Yield : ' : 'अपेक्षित उत्पादन : ',
              style: const TextStyle(
                  color: Color.fromARGB(255, 219, 191, 157),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '${(cropYield * 100).toStringAsFixed(2)}${english ? ' Kg' : ' किलो'}',
              style: const TextStyle(
                  color: Color.fromARGB(255, 113, 255, 118),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
      ],
    );
  }

  Column fieldSections(Size size) {
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Container(
          height: 1,
          width: size.width * 0.9,
          color: const Color.fromARGB(255, 219, 191, 157),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          english ? 'Mandatory Fields' : 'अनिवार्य फील्ड्स',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            formField(english ? 'Area' : 'भूमि आवरण', area),
            const Text(
              'in',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color.fromARGB(255, 219, 191, 157)),
            ),
            dropDown('area', areaUnitList, 110)
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              english ? 'Crop :  ' : 'फसल :  ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color.fromARGB(255, 219, 191, 157)),
            ),
            dropDown('crop', cropList, 90),
            const SizedBox(
              width: 20,
            ),
            Text(
              english ? 'Season :  ' : 'मौसम :  ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color.fromARGB(255, 219, 191, 157)),
            ),
            dropDown(
                'season',
                english ? ['Kharif', 'Rabi', 'Zaid'] : ['खरीफ', 'रबी', 'ज़ैद'],
                80)
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 10,
            ),
            dropDown('district',
                english ? ['Ambala', 'Bhiwani'] : ['अंबाला', 'भिवानी'], 120),
            const SizedBox(
              width: 10,
            ),
            dropDown(
                'village',
                english
                    ? [
                        'Nasirpur',
                        'Bhurangpur',
                        'Bound Kalan',
                        'Birhi Kalan',
                        'Naraungabad'
                      ]
                    : [
                        'नसीरपुर',
                        'भुरंगपुर',
                        'बाउंड कलां',
                        'बिरही कलां',
                        'नरौंगाबाद'
                      ],
                130),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Container(
          height: 1,
          width: size.width * 0.9,
          color: const Color.fromARGB(255, 219, 191, 157),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          english ? 'Optional Fields' : 'वैकल्पिक फील्ड्स',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
                '    ${english ? 'Soil Health Card :' : 'मृदा स्वास्थ्य कार्ड :'}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color.fromARGB(255, 219, 191, 157))),
            const SizedBox(width: 10),
            const Text('N/A',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white))
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('    ${english ? 'Farming Type :' : 'खेती का प्रकार'}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color.fromARGB(255, 219, 191, 157))),
            const SizedBox(width: 10),
            dropDown(
                'farming',
                english
                    ? [
                        'Commercial',
                        'Organic',
                        'Plantation',
                        'Extensive',
                        'Other'
                      ]
                    : ['वाणिज्यिक', 'कार्बनिक', 'बागवानी', 'व्यापक', 'अन्य'],
                120)
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            formField('     ${english ? 'Water Quality' : 'पानी की गुणवत्ता'}',
                waterQuality),
            const SizedBox(
              width: 10,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  double val = double.parse(waterQuality.text);
                  double fact = 1.0;
                  if (val >= 2000 && val < 4000) {
                    fact = 0.9;
                  } else if (val >= 4000 && val < 6000) {
                    fact = 0.8;
                  } else if (val >= 6000) {
                    fact = 0.5;
                  }
                  setState(() {
                    cropYield = cropYield * fact;
                    cropReturn = cropReturn * fact;
                  });
                },
                child: Text(
                  english ? "Update" : 'अपडेट',
                  style: const TextStyle(color: Colors.white),
                ))
          ],
        ),
        const SizedBox(
          height: 10,
        )
      ],
    );
  }

  Row toggleItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () {
            if (mounted) setState(() => selected = false);
          },
          child: Container(
            height: 40,
            width: 120,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: !selected
                    ? const Color.fromARGB(255, 219, 191, 157)
                    : Colors.transparent,
                border: Border.all(
                    color: const Color.fromARGB(255, 219, 191, 157))),
            child: Center(
              child: Text(
                english ? 'Investment' : 'निवेश',
                style: TextStyle(
                    color: !selected
                        ? Colors.black
                        : const Color.fromARGB(255, 219, 191, 157),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            if (mounted) setState(() => selected = true);
          },
          child: Container(
            height: 40,
            width: 120,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: selected
                    ? const Color.fromARGB(255, 219, 191, 157)
                    : Colors.transparent,
                border: Border.all(
                    color: const Color.fromARGB(255, 219, 191, 157))),
            child: Center(
              child: Text(
                english ? 'Return' : 'आय',
                style: TextStyle(
                    color: selected
                        ? Colors.black
                        : const Color.fromARGB(255, 219, 191, 157),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        )
      ],
    );
  }

  Container dropDown(String value, List<String> items, double width) {
    Map<String, String> map = {
      'area': areaUnit,
      'crop': crop,
      'season': season,
      'village': village,
      'district': district,
      'farming': farming
    };
    if (!items.contains(map[value])) {
      // If not, assign a default valid value based on the language
      map[value] = items[0];
    }

    return Container(
      height: 40,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 203, 203, 203),
      ),
      child: Center(
        child: DropdownButton<String>(
          value: map[value],
          icon: const Icon(Icons.arrow_downward),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(color: Colors.white),
          onChanged: (val) {
            setState(() {
              if (value == 'area') {
                areaUnit = val!;
              } else if (value == 'crop') {
                crop = val!;
              } else if (value == 'season') {
                season = val!;
              } else if (value == 'village') {
                village = val!;
                if (villageWaterQty[village]! > 6000) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Ground Water unfit for use!!!')));
                  }
                }
                setState(() {
                  waterQuality.text = villageWaterQty[village]!.toString();
                });
              } else if (value == 'district') {
                district = val!;
              } else if (value == 'farming') {
                farming = val!;
              }
              if (area.text.isNotEmpty) {
                double val = double.parse(area.text);
                double areaInHectare = convertToHectare(val, areaUnit);
                cropYield = areaInHectare * cropYieldData[crop]! / 100;
                cropCost = cropYield * cropCostList[crop]!;
                cropReturn = cropYield * cropMsp[crop]!;
              }
            });
          },
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text('  $value',
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

  Row formField(title, controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '$title :',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color.fromARGB(255, 219, 191, 157)),
        ),
        const SizedBox(
          width: 5,
        ),
        SizedBox(
          width: 80,
          height: 35,
          child: TextFormField(
            onChanged: (value) {
              if (value.isNotEmpty) {
                double val = double.parse(area.text);
                double areaInHectare = convertToHectare(val, areaUnit);
                setState(() {
                  cropYield = areaInHectare * cropYieldData[crop]! / 100;
                  cropCost = cropYield * cropCostList[crop]!;
                  cropReturn = cropYield * cropMsp[crop]!;
                });
              }
            },
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                contentPadding: EdgeInsets.only(bottom: 0, left: 2.5),
                fillColor: Colors.white,
                filled: true),
            style: const TextStyle(
                fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
            textAlignVertical: TextAlignVertical.center,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
