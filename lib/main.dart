import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './facilities/facility.dart';
import './phone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp();
  final user = FirebaseAuth.instance.currentUser;
  await dotenv.load(fileName: '.env');
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: user == null ? const Otp() : const Facility(),
  ));
}
