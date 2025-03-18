import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'details.dart';

class Schemes extends StatefulWidget {
  const Schemes({super.key});

  @override
  State<Schemes> createState() => _SchemesState();
}

class _SchemesState extends State<Schemes> {
  @override
  void initState() {
    initAssistant();
    super.initState();
  }

  @override
  void dispose() {
    if (recorder.isRecording) {
      recorder.stopRecorder();
    }
    recorder.closeRecorder();
    if (audioFile != null) {
      audioFile!.delete();
    }
    // deleteThread();
    super.dispose();
  }

  Future<void> initAssistant() async {
    await initRecorder();
    // await initThread();
    await fetchFirestoreSchemes();
  }

  Future<void> fetchFirestoreSchemes() async {
    final schemes = await FirebaseFirestore.instance
        .collection('Irrigation System')
        .doc('schemes')
        .get();
    final data = schemes.data() as Map<String, dynamic>;
    setState(() {
      govSchemes = data['schemes'];
      govSchemesHindi = data['schemes_hindi'];
      translate = data['translate'];
      translate = translate.replaceAll("'", '"');
    });
  }

  Future<dynamic> uploadAudioFile(String filePath) async {
    var uri = Uri.parse('https://api.openai.com/v1/audio/translations');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${dotenv.env['key']}'
      ..files.add(await http.MultipartFile.fromPath('file', filePath))
      ..fields['model'] = 'whisper-1'
      ..fields['response_format'] = 'text';

    try {
      setState(() {
        text = 'Translating voice...';
      });
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.body;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> initRecorder() async {
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      await recorder.openRecorder();
      setState(() {
        isRecorderReady = true;
        isLoading = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please give the required permissions.')));
      }
    }
  }

  Future<void> startRecording() async {
    if (!isRecorderReady) {
      return;
    }
    await recorder.startRecorder(toFile: 'audio.mp4', codec: Codec.aacMP4);
  }

  Future<File> stopRecording() async {
    final path = await recorder.stopRecorder();
    File audioFile = File(path!);
    return audioFile;
  }

  Future<void> fetchSchemes(String text) async {
    var response = await http.post(
        Uri.parse('https://fetch-government-schemes-pw66dfxg7a-el.a.run.app'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'text': text}));
    if (response.statusCode == 200) {
      List schemesList = jsonDecode(response.body)['schemes'];
      for (var scheme in govSchemes.keys.toList()) {
        if (schemesList.contains(scheme)) {
          schemes.add(scheme);
        }
      }
      return;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching schemes: ${response.body}'),
        ));
      }
    }
  }

  final recorder = FlutterSoundRecorder();
  bool isRecorderReady = false;
  bool isRecording = false;
  bool isLoading = true;
  bool hindi = false;
  late String translate;
  late Map<String, dynamic> govSchemes;
  late Map<String, dynamic> govSchemesHindi;

  late String threadId;
  List schemes = [];
  File? audioFile;
  String? text;

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
        title: Text(hindi ? 'योजनाएं' : 'Schemes',
            style: const TextStyle(color: Colors.white)),
        actions: [
          Center(
              child: Text(hindi ? 'हिन्दी  ' : 'English ',
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
                text = text != null
                    ? hindi
                        ? 'नीचे कुछ योजनाएँ दी गई हैं:'
                        : 'Below are some schemes:'
                    : null;
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
          SizedBox(
              height: size.height * 0.9,
              width: size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  !isLoading ? btn() : const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  text != null
                      ? Text(
                          text!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        )
                      : const SizedBox(),
                  const SizedBox(height: 20),
                  schemeList(size)
                ],
              )),
        ],
      ),
    );
  }

  Expanded schemeList(Size size) {
    return Expanded(
      child: ListView.builder(
          itemCount: schemes.length,
          itemBuilder: (context, index) {
            final scheme = schemes[index];
            final hindiScheme = jsonDecode(translate)[scheme];
            return Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
              child: Card(
                color: Colors.transparent,
                elevation: 8,
                shadowColor: Colors.black,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SchemeDetails(
                                scheme: scheme,
                                hindi: hindi,
                                details: hindi
                                    ? govSchemesHindi[scheme]
                                    : govSchemes[scheme])));
                  },
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 219, 191, 157),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: size.width * 0.75,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    hindi ? hindiScheme : scheme,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  ElevatedButton btn() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, shape: const CircleBorder()),
        onPressed: () async {
          if (isRecording && mounted) {
            setState(() {
              isLoading = true;
              text = null;
              schemes = [];
            });
            audioFile = await stopRecording();
            final response = await uploadAudioFile(audioFile!.path);
            if (audioFile != null) {
              audioFile!.delete();
              audioFile = null;
            }
            if (response != null) {
              setState(() {
                text = 'Fetching schemes...';
              });
              // await createMessageInThread(response);
              await fetchSchemes(response);
              text = hindi
                  ? 'नीचे कुछ योजनाएँ दी गई हैं:'
                  : 'Below are some schemes:';
            } else {
              text = 'Error in translating voice.';
            }
            if (mounted) {
              setState(() {
                isRecording = false;
                isLoading = false;
              });
            }
          } else {
            await startRecording();
            if (mounted) {
              setState(() {
                isRecording = true;
              });
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            isRecording ? Icons.stop : Icons.mic,
            size: 60,
            color: Colors.white,
          ),
        ));
  }
}


  // Future<void> initThread() async {
  //   String apiUrl = "https://api.openai.com/v1/threads";

  //   Map<String, String> headers = {
  //     "Content-Type": "application/json",
  //     "Authorization": "Bearer ${dotenv.env['key']}",
  //     "OpenAI-Beta": "assistants=v1",
  //   };

  //   final response = await http.post(Uri.parse(apiUrl), headers: headers);
  //   if (response.statusCode == 200) {
  //     setState(() {
  //       threadId = jsonDecode(response.body)['id'];
  //       isLoading = false;
  //     });
  //   }
  // }

  // Future<void> deleteThread() async {
  //   final String apiUrl = "https://api.openai.com/v1/threads/$threadId";
  //   final Map<String, String> headers = {
  //     "Content-Type": "application/json",
  //     "Authorization": "Bearer ${dotenv.env['key']}",
  //     "OpenAI-Beta": "assistants=v1",
  //   };
  //   await http.delete(Uri.parse(apiUrl), headers: headers);
  // }

  // Future<void> createMessageInThread(String messageContent) async {
  //   final String apiUrl =
  //       "https://api.openai.com/v1/threads/$threadId/messages";

  //   final Map<String, String> headers = {
  //     "Content-Type": "application/json",
  //     "Authorization": "Bearer ${dotenv.env['key']}",
  //     "OpenAI-Beta": "assistants=v1",
  //   };

  //   final Map<String, dynamic> body = {
  //     "role": "user",
  //     "content": messageContent,
  //   };
  //   setState(() {
  //     text = 'Creating querry...';
  //   });
  //   final response = await http.post(Uri.parse(apiUrl),
  //       headers: headers, body: jsonEncode(body));

  //   if (response.statusCode == 200) {
  //     setState(() {
  //       text = 'Starting assistant...';
  //     });
  //     final resp = await createRunInThread();
  //     if (resp != 'success') {
  //       if (mounted) {
  //         text = 'Error starting assistant.';
  //         ScaffoldMessenger.of(context)
  //             .showSnackBar(SnackBar(content: Text(resp)));
  //       }
  //     } else {
  //       setState(() {
  //         text = 'Waiting for response...';
  //       });
  //       await getMessagesInThread();
  //     }
  //   } else {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //           content: Text('Error creating message: ${response.body}')));
  //     }
  //   }
  // }

  // Future<String> createRunInThread() async {
  //   final String apiUrl =
  //       "https://api.openai.com/v1/threads/$threadId/runs"; // Replace with your OpenAI API key

  //   final Map<String, String> headers = {
  //     "Content-Type": "application/json",
  //     "Authorization": "Bearer ${dotenv.env['key']}",
  //     "OpenAI-Beta": "assistants=v1",
  //   };

  //   final Map<String, dynamic> body = {
  //     "assistant_id": "${dotenv.env['id']}",
  //   };

  //   final response = await http.post(Uri.parse(apiUrl),
  //       headers: headers, body: jsonEncode(body));
  //   if (response.statusCode == 200) {
  //     return 'success';
  //   } else {
  //     return 'Error creating run : ${response.body}';
  //   }
  // }

  // Future<void> getMessagesInThread() async {
  //   final String apiUrl =
  //       "https://api.openai.com/v1/threads/$threadId/messages";

  //   final Map<String, String> headers = {
  //     "Content-Type": "application/json",
  //     "Authorization": "Bearer  ${dotenv.env['key']}",
  //     "OpenAI-Beta": "assistants=v1",
  //   };

  //   final resp = await http.get(Uri.parse(apiUrl), headers: headers);
  //   if (resp.statusCode == 200) {
  //     final data = jsonDecode(resp.body)['data'][0];
  //     if (data['content'][0]['text']['value'] != '' &&
  //         data['role'] == 'assistant') {
  //       for (var scheme in govSchemes.keys.toList()) {
  //         if (data['content'][0]['text']['value'].contains(scheme)) {
  //           schemes.add(scheme);
  //         }
  //       }
  //       text = 'Below are some schemes:';
  //       return;
  //     } else {
  //       await Future.delayed(const Duration(seconds: 1));
  //       await getMessagesInThread();
  //     }
  //   } else {
  //     text = 'error getting messages: ${resp.body}';
  //     return;
  //   }
  // }