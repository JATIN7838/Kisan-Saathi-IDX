import 'package:flutter/material.dart';
import './gis.dart';
import 'loss.dart';
import 'register.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
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
        title: Text(hindi ? 'Admin Panel' : "प्रशासक पैनल",
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Loss())),
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
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        AssetImage('assets/loss.png'),
                                  ),
                                  Text(
                                    hindi
                                        ? '    Crop Loss Requests'
                                        : "    फसल हानि अनुरोध",
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
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Register())),
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
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        AssetImage('assets/registerCrop.png'),
                                  ),
                                  Text(
                                    hindi
                                        ? '    Registerd Crops'
                                        : "    पंजीकृत फसलें",
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
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const GIS())),
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
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        AssetImage('assets/satellite.png'),
                                  ),
                                  Text(
                                    hindi
                                        ? '    GIS Analysis'
                                        : "    जीआईएस विश्लेषण",
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
