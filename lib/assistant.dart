import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import './facilities/api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';

class Assistant extends StatefulWidget {
  final bool hindi;
  const Assistant({super.key, required this.hindi});

  @override
  State<Assistant> createState() => _AssistantState();
}

class _AssistantState extends State<Assistant> {
  PredictionService pd = PredictionService();

  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')));
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<String> translateText(String text) async {
    final GoogleTranslator translator = GoogleTranslator();
    try {
      var translation = await translator.translate(text, to: 'hi');
      return translation.text;
    } catch (e) {
      return 'Error: $e';
    }
  }

  final recorder = FlutterSoundRecorder();
  bool pic = false;
  File? imageFile;
  bool gps = true;
  bool isRecorderReady = false;
  bool isRecording = false;
  bool isLoading = false;
  Map<String, dynamic> data = {};
  String currentFunction = '';
  List messages = [
    {
      'role': 'system',
      'content': 'Answer in 30 tokens max and english language.'
    },
  ];

  File? audioFile;
  String? text;
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

  Future<void> initRecorder() async {
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      await recorder.openRecorder();
      setState(() {
        isRecorderReady = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please give the required permissions.')));
      }
    }
  }

  Future<String> identifyPestDisease() async {
    if (imageFile == null) {
      return '';
    }

    // Show Loading Indicator
    setState(() {
      isLoading = true;
      text = "Processing Image...";
    });

    // Convert Image to Base64
    String base64Image = base64Encode(await imageFile!.readAsBytes());

    // OpenAI API Headers
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${dotenv.env['key']}"
    };

    // OpenAI API Payload
    Map<String, dynamic> payload = {
      "model": "gpt-4o-mini",
      "max_tokens": 100,
      "messages": [
        {
          "role": "system",
          "content": [
            {
              "type": "text",
              "text":
                  "Your task is to name the plant disease and provide 3 pesticides or herbicides. Keep it short and crisp in 100 tokens. Answer in Hindi language."
            }
          ]
        },
        {
          "role": "user",
          "content": [
            {
              "type": "image_url",
              "image_url": {"url": "data:image/png;base64,$base64Image"}
            }
          ]
        }
      ],
    };

    try {
      // Make API Call
      var response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: headers,
        body: jsonEncode(payload),
      );

      var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      String diseaseResponse = jsonResponse['choices'][0]['message']
              ['content'] ??
          'Unable to identify disease.';

      return diseaseResponse;
    } catch (e) {
      return "Error: $e";
    }
  }

  @override
  void initState() {
    super.initState();
    initRecorder();
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
    super.dispose();
  }

  Future<dynamic> uploadAudioFile(String filePath) async {
    var uri = Uri.parse('https://api.openai.com/v1/audio/translations');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${dotenv.env['key']}'
      ..files.add(await http.MultipartFile.fromPath('file', filePath))
      ..fields['model'] = 'whisper-1'
      ..fields['response_format'] = 'text';

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.body;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> callFunctions(List choices) async {
    API api = API(location: 'Gurgaon');
    final function = choices[0]['message']['tool_calls'][0]['function'];
    final location = jsonDecode(function['arguments'])['location'];
    bool isTool = false;
    if (function['name'] == 'getCurrentWeather') {
      var output = await api.getCurrentWeather(location: location);
      messages.add(
        {'role': 'system', 'content': 'Take reference from the below data'},
      );
      messages.add({'role': 'user', 'content': jsonEncode(output)});
    } else if (function['name'] == 'getForecastWeather') {
      var output = await api.getForecastWeather(location: location);
      output = output['forecast']['forecastday'][0]['day'];
      messages.add(
        {'role': 'system', 'content': 'Take reference from the below data'},
      );
      messages.add({'role': 'user', 'content': jsonEncode(output)});
    } else if (function['name'] == 'whatToGrow') {
      if (gps) {
        final position = await getCurrentLocation();
        var url = 'https://recommend-crops-pw66dfxg7a-el.a.run.app';
        var body = jsonEncode({
          'lat': position.latitude,
          'long': position.longitude,
        });

        var response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
        var crops = jsonDecode(response.body);
        if (crops is Map) {
          return crops['error'];
        }
        crops = crops.join(', ');
        return 'You can grow $crops';
      } else {
        var district = jsonDecode(function['arguments'])['district'];
        var village = jsonDecode(function['arguments'])['village'];
        if (district == 'null' || district == null || district == 'Haryana') {
          messages.add(
            {
              'role': 'system',
              'content': 'Ask the user for district and village name'
            },
          );
          isTool = true;
        } else if (village == 'null' ||
            village == null ||
            village == 'Haryana') {
          messages.add(
            {'role': 'system', 'content': 'Ask the user for village name.'},
          );
          isTool = true;
        } else {
          var url = 'https://recommend-crops-pw66dfxg7a-el.a.run.app';
          var body = jsonEncode({
            'district': district,
            'village': village,
          });
          var response = await http.post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: body,
          );
          var crops = jsonDecode(response.body);
          if (crops is Map) {
            return crops['error'];
          }
          crops = crops.join(', ');
          return 'you can grow $crops';
        }
      }
    } else if (function['name'] == 'canGrow') {
      var crop = jsonDecode(function['arguments'])['crop'];
      if (location == 'null' || location == null) {
        messages.add({'role': 'system', 'content': 'Ask for location'});
        isTool = true;
      } else if (crop == 'null' || crop == null) {
        messages.add({
          'role': 'system',
          'content': 'Ask what crop the farmer wants to grow?'
        });
        isTool = true;
      } else {
        var output = api.canGrow(crop, location);
        messages.add(
          {
            'role': 'system',
            'content': 'Answer the output in 15 tokens max: $output'
          },
        );
      }
    } else if (function['name'] == 'PestDiseaseRemedy') {
      currentFunction = 'PestDiseaseRemedy';
      setState(() {
        pic = true;
      });
      return 'Please provide a picture of the crop to identify the disease or pest. It may take some time to process the image.';
    } else if (function['name'] == 'RecordCropLoss') {
      currentFunction = 'RecordCropLoss';
      var crop = jsonDecode(function['arguments'])['crop'];
      var loss = jsonDecode(function['arguments'])['loss'];
      final position = await getCurrentLocation();
      double latitude = position.latitude;
      double longitude = position.longitude;
      if (crop == 'null' || crop == null || crop == '') {
        messages.add(
          {'role': 'system', 'content': 'Ask the user for crop name.'},
        );
        isTool = true;
      } else if (loss == 'null' || loss == null || loss == '') {
        messages.add(
          {'role': 'system', 'content': 'Ask the user for loss percentage.'},
        );
        isTool = true;
      } else {
        setState(() {
          pic = true;
        });
        data = {
          'crop': crop,
          'loss': loss,
          'date': DateTime.now().toString(),
          'latitude': latitude,
          'longitude': longitude,
        };
        return 'To register your loss, provide a picture of the crop just the way it is shown below.';
      }
    } else if (function['name'] == "CropRegistration") {
      currentFunction = 'CropRegistration';
      var snap = await FirebaseFirestore.instance
          .collection('RegisteredCrops')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (!snap.exists) {
        final args = jsonDecode(function['arguments']);
        final crop = args['crop'];
        final date = args['sowingDate'];
        final source = args['SourceOfIrrigation'];
        String msg = '';
        if (crop == null || crop == '' || crop == 'null') {
          msg += 'Crop name, ';
        }
        if (date == null || date == '' || date == 'null') {
          msg += 'Sowing date, ';
        }
        if (source == null || source == '' || source == 'null') {
          msg += 'Source of irrigation';
        }
        if (msg != '') {
          messages.add(
            {'role': 'assistant', 'content': 'please provide $msg'},
          );
          isTool = true;
          return 'please provide $msg';
        } else {
          setState(() {
            pic = true;
          });
          final todaysDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
          final position = await getCurrentLocation();
          data = {
            'crop': crop,
            'sowingDate': date,
            'sourceOfIrrigation': source,
            'date': todaysDate,
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
          return 'To register your crop, provide a picture of the crop just the way it is shown below.';
        }
      } else {
        return 'I am working on it';
      }
    }
    if (!isTool) {
      return jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messages,
      });
    } else {
      return jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messages,
        'tools': api.functions,
        "tool_choice": "auto"
      });
    }
  }

Future<String> processRequest(List choices) async {
  final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${dotenv.env['GEMINI_API_KEY']}');

  final headers = {
    'Content-Type': 'application/json',
  };

  String requestBody = await callFunctions(choices);
  if (!requestBody.contains("gemini-2.0-flash")) {
    return requestBody;
  }

  final response = await http.post(
    uri,
    headers: headers,
    body: requestBody,
  );

  if (response.statusCode == 200) {
    var output = jsonDecode(response.body);
    choices = output['contents'] as List;
    if (choices.isNotEmpty && choices[0]['parts'][0]['text'] != null) {
      return utf8.decode(choices[0]['parts'][0]['text'].runes.toList()).toLowerCase();
    } else {
      return await processRequest(choices);
    }
  } else {
    // Handle error responses
    return 'Error: ${response.statusCode}';
  }
}

Future<String> fetchChatResponse(String text) async {
  API api = API(location:'Gurgaon');

  final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${dotenv.env['GEMINI_API_KEY']}');

  messages.add({'role': 'user', 'content': text});

  final headers = {
    'Content-Type': 'application/json',
  };

  String requestBody = jsonEncode({
    'contents': [
      {
        'parts': [
          {'text': text}
        ]
      }
    ],
    'tools': api.functions,
    'tool_choice': 'auto'
  });

  final response = await http.post(
    uri,
    headers: headers,
    body: requestBody,
  );

  if (response.statusCode == 200) {
    var output = jsonDecode(response.body);
    var choices = output['contents'] as List;
    var messageContent = '';
    if (choices.isNotEmpty && choices[0]['parts'][0]['text'] != null) {
      messageContent = utf8.decode(choices[0]['parts'][0]['text'].runes.toList()).toLowerCase();
      if ((messageContent.contains('district') ||
              messageContent.contains('village')) &&
          (!messageContent.contains('loss') &&
              !messageContent.contains('lost') &&
              !messageContent.contains('damage') &&
              !messageContent.contains('lose') &&
              !messageContent.contains('losing'))) {
        final position = await getCurrentLocation();
        var url = 'https://recommend-crops-pw66dfxg7a-el.a.run.app';
        var body = jsonEncode({
          'lat': position.latitude,
          'long': position.longitude,
        });

        var response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
        var crops = jsonDecode(response.body);
        if (crops is Map) {
          return crops['error'];
        }
        crops = crops.join(', ');
        messageContent = 'You can grow $crops';
      }
    } else {
      messageContent = await processRequest(choices);
    }
    return messageContent;
  } else {
    // Handle error responses
    return 'Error: ${response.statusCode}';
  }
}

  Future<void> geoTag(String doc, Map data) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://geotag-loss-image-pw66dfxg7a-el.a.run.app',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'doc': doc, 'data': data}),
      );
      if (response.body == 'Image superimposed successfully!') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Image has been geotagged successfully')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response.body.toString())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to geotag the image')));
      }
    }
  }

  Future<void> generateSpeech(String text) async {
    final uri = Uri.parse('https://api.openai.com/v1/audio/speech');
    final headers = {
      'Authorization': 'Bearer ${dotenv.env['key']}',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode(
        {'model': 'tts-1', 'input': text, 'voice': 'onyx', 'speed': 1});

    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode == 200) {
      await playFile(response.bodyBytes);
    } else {
      //snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to generate speech: ${response.body}')));
      }
    }
  }

  Future<void> playFile(List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/speech.mp3';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    final player = FlutterSoundPlayer();
    await player.openPlayer();
    await player.startPlayer(
        fromURI: file.path,
        whenFinished: () async {
          await player.stopPlayer();
          await player.closePlayer();
          file.delete();
        });
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
        title: Text(widget.hindi ? 'Assistant' : "सहायक",
            style: const TextStyle(color: Colors.white)),
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
            height: size.height,
            width: size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    height: 20,
                  ),
                  if (!isLoading)
                    Row(
                      mainAxisAlignment: pic
                          ? MainAxisAlignment.spaceEvenly
                          : MainAxisAlignment.center,
                      children: [
                        chatbtn(),
                        if (pic)
                          Column(
                            children: [
                              photoBtn(),
                              const SizedBox(width: 20),
                              galleryBtn()
                            ],
                          ),
                        if (imageFile != null) sendBtn()
                      ],
                    )
                  else
                    const CircularProgressIndicator(), // Add the CircularProgressIndicator here

                  const SizedBox(
                    height: 20,
                  ),
                  if (text != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        text!,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  if (imageFile != null)
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        Image.file(
                          imageFile!,
                          width: 250,
                          height: 250,
                        ),
                        const SizedBox(height: 20),
                        IconButton(
                            onPressed: () {
                              setState(() {
                                imageFile = null;
                              });
                            },
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 50,
                            ))
                      ],
                    ),
                  if (imageFile == null && pic && !isLoading) examplePics(size)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Column examplePics(Size size) {
    const double width = 250;
    return Column(
      children: [
        const SizedBox(height: 40),
        SizedBox(
          height: 200,
          width: size.width,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                  width: width,
                  height: 200,
                  child: Image.asset(
                    'assets/1.jpg',
                    fit: BoxFit.cover,
                  )),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                  width: width,
                  height: 200,
                  child: Image.asset('assets/2.jpg', fit: BoxFit.cover)),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                  width: width,
                  height: 200,
                  child: Image.asset('assets/3.jpg', fit: BoxFit.cover)),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                  width: width,
                  height: 200,
                  child: Image.asset('assets/4.jpg', fit: BoxFit.cover)),
            ],
          ),
        ),
      ],
    );
  }

  IconButton galleryBtn() {
    return IconButton(
        onPressed: () async {
          final status = await Permission.photos.status;
          if (status.isPermanentlyDenied) {
            openAppSettings();
          } else if (status.isDenied) {
            final status = await Permission.photos.request();
            if (status != PermissionStatus.granted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please give the required permissions.')));
              }
            }
          }
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1000,
            maxHeight: 1000,
          );
          if (image != null) {
            setState(() {
              imageFile = File(image.path);
            });
          }
        },
        icon: const Icon(Icons.photo_library_outlined,
            size: 35, color: Colors.white));
  }

  IconButton sendBtn() {
    return IconButton(
        onPressed: () async {
          try {
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
            if (currentFunction == 'RecordCropLoss') {
              data['UID'] = FirebaseAuth.instance.currentUser!.uid;
              var doc = await FirebaseFirestore.instance
                  .collection('crop_loss')
                  .add(data);
              final path = 'crop_loss/${doc.id}.jpg';
              final ref = FirebaseStorage.instance.ref().child(path);
              await ref.putFile(imageFile!);
              final url = await ref.getDownloadURL();
              await doc.update({'image': url});
              geoTag(path, data);
              text = await translateText(
                  'Your loss has been registered. We will verify the provided information and get back to you soon.');
            } else if (currentFunction == 'PestDiseaseRemedy') {
              text = await identifyPestDisease();
            } else {
              String val = await pd.makePrediction(imageFile!);
              if (val.contains('error:')) {
                val = val.replaceAll('error:', '');
                text = await translateText(val);
                await generateSpeech(text!);
                setState(() {
                  isLoading = false;
                  imageFile = null;
                });
                return;
              } else if (data['crop'].toString().toLowerCase() !=
                  val.toLowerCase()) {
                text = await translateText(
                    'Wrong crop uploaded. Please try again.');
                await generateSpeech(text!);
                setState(() {
                  isLoading = false;
                  imageFile = null;
                });
                return;
              } else {
                data['UID'] = FirebaseAuth.instance.currentUser!.uid;
                var doc = FirebaseFirestore.instance
                    .collection('RegisteredCrops')
                    .doc();
                await doc.set(data);
                final path = 'RegisteredCrops/${doc.id}.jpg';
                final ref = FirebaseStorage.instance.ref().child(path);
                await ref.putFile(imageFile!);
                final url = await ref.getDownloadURL();
                await doc.update({'image': url});
                geoTag(path, data);
                text = await translateText('Your crop has been registered.');
              }
            }
            await generateSpeech(text!);
            messages = [
              {
                'role': 'system',
                'content':
                    'Answer in 30 tokens max and english language. The input will be in hindi language'
              },
            ];
            setState(() {
              isLoading = false;
              pic = false;
              imageFile = null;
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        icon: const Icon(
          Icons.send,
          color: Colors.lightBlue,
          size: 35,
        ));
  }

  IconButton photoBtn() {
    return IconButton(
      icon: const Icon(
        Icons.camera_alt_outlined,
        size: 35,
        color: Colors.white,
      ),
      onPressed: () async {
        //ask for permission
        final status = await Permission.camera.request();
        if (status != PermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Please give the required permissions.')));
          }
          return;
        }
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1000,
          maxHeight: 1000,
        );
        if (image != null) {
          setState(() {
            imageFile = File(image.path);
          });
        }
      },
    );
  }

  ElevatedButton chatbtn() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
        ),
        onPressed: () async {
          // try {
          if (isRecording) {
            setState(() {
              isLoading = true;
              text = null;
            });
            audioFile = await stopRecording();
            String response = await uploadAudioFile(audioFile!.path);
            String hindi = await translateText(response);
            setState(() {
              text = hindi;
            });
            // play the audio file
            if (audioFile != null) {
              audioFile!.delete();
              audioFile = null;
            }
            response = await fetchChatResponse(response);
            text = await translateText(response);
            await generateSpeech(text!);
            setState(() {
              isRecording = false;
              isLoading = false;
            });
          } else {
            await startRecording();
            setState(() {
              isRecording = true;
            });
          }
          // }
          //  catch (e) {
          //   if (mounted) {
          //     ScaffoldMessenger.of(context)
          //         .showSnackBar(SnackBar(content: Text(e.toString())));
          //   }
          // }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 60,
          ),
        ));
  }
}
