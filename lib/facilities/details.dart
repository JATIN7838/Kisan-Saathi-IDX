import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeDetails extends StatefulWidget {
  final String scheme;
  final Map<String, dynamic> details;
  final bool hindi;
  const SchemeDetails(
      {Key? key,
      required this.scheme,
      required this.details,
      required this.hindi})
      : super(key: key);

  @override
  State<SchemeDetails> createState() => _SchemeDetailsState();
}

class _SchemeDetailsState extends State<SchemeDetails> {
  Map translations = {
    'eligibility': 'योग्यता',
    'benefits': 'लाभ',
    'limitations': 'सीमाएँ',
    'when to consider': 'कब विचार करें',
    'website': 'वेबसाइट'
  };
  Map<String, dynamic> sortedDetails = {};

  bool fileReady = false;
  bool isPlaying = false;
  FlutterSoundPlayer? player = FlutterSoundPlayer();
  late File file;
  @override
  void initState() {
    super.initState();
    translations.forEach((key, value) {
      if (widget.details.containsKey(key)) {
        sortedDetails[key] = widget.details[key];
      }
    });
    initPlayer();
    downloadAudioFile();
  }

  Future<void> initPlayer() async {
    await player?.openPlayer();
  }

  @override
  void dispose() {
    //check if player is playing and stop it
    if (isPlaying) {
      player?.stopPlayer();
    }
    player?.closePlayer();
    if (fileReady) {
      file.delete();
    }
    super.dispose();
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await player?.pausePlayer();
    } else {
      if (player?.isStopped ?? true) {
        await player?.startPlayer(
            fromURI: file.path,
            whenFinished: () {
              setState(() {
                isPlaying = false;
              });
            });
      } else {
        await player?.resumePlayer();
      }
    }

    setState(() {
      isPlaying = !isPlaying;
    });
  }

  Future<void> downloadAudioFile() async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('schemes audio/${widget.scheme}.mp3');
      final directory = await getApplicationDocumentsDirectory();
      //list all files in the directory
      final files = directory.listSync();
      for (final f in files) {
        if (f.path.endsWith('.mp3')) {
          f.delete();
        }
      }
      final filePath = '${directory.path}/${widget.scheme}.mp3';
      file = File(filePath);
      await ref.writeToFile(file);
      setState(() {
        fileReady = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
        title: Text(
          !widget.hindi ? 'Scheme Details' : 'योजना का विवरण',
          style: const TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          if (!fileReady)
            const Center(child: CircularProgressIndicator())
          else
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: togglePlay,
            ),
          const SizedBox(
            width: 10,
          )
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
          ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            children: sortedDetails.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !widget.hindi
                        ? '${entry.key.toUpperCase()} :'
                        : '${translations[entry.key]} :',
                    style: const TextStyle(
                        color: Color.fromARGB(255, 219, 191, 157),
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (entry.value is List)
                    ...entry.value.map<Widget>((item) {
                      return Text(
                        '• ${item.toString()}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      );
                    }).toList(),
                  if (entry.key == 'website')
                    InkWell(
                      onTap: () => _launchURL(entry.value),
                      child: Text(
                        entry.value.toString().trim(),
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
