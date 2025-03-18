import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  Future<List> fetchData() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('RegisteredCrops').get();
      final userSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final userData = userSnap.docs;
      List data = [];
      for (var element in snapshot.docs) {
        var elementData = element.data() as Map<String, dynamic>;
        var uid = elementData['UID'];
        for (var user in userData) {
          if (user.id == uid) {
            var phone = user.data()['phone'];
            elementData['phone'] = phone;
            data.add(elementData);
          }
        }
      }
      data.sort((a, b) {
        var aDate = a['date'];
        var bDate = b['date'];
        return bDate.compareTo(aDate);
      });

      return data;
    } catch (e) {
      return [
        {'error': e.toString()}
      ];
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url.trim()))) {
        await launchUrl(Uri.parse(url.trim()));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch Website')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch Website')));
      }
    }
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
          title: const Text(
            'Registered Crops',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: FutureBuilder(
          future: fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // check if there is an error
            if (snapshot.hasError) {
              return Center(
                child: Text('An error occurred ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            }
            //check if data is empty
            if (snapshot.data![0]['error'] != null) {
              return Center(
                child: Text('An error occurred ${snapshot.data![0]['error']}',
                    style: const TextStyle(color: Colors.red)),
              );
            }
            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            // return the list of data having date,phone,crop and loss
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () => _launchURL(snapshot.data![index]['image']),
                    child: Card(
                      color: const Color.fromARGB(255, 219, 191, 157),
                      child: ListTile(
                        title: Text(
                          // remove any text after decimal point
                          'Date: ${snapshot.data![index]['date']}',
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone: ${snapshot.data![index]['phone']}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Crop: ${snapshot.data![index]['crop']}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Irrigation: ${snapshot.data![index]['sourceOfIrrigation']}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Sowing Date: ${snapshot.data![index]['sowingDate']}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}
