import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './facilities/facility.dart';

class Otp extends StatefulWidget {
  const Otp({super.key});

  @override
  State<Otp> createState() => _OtpState();
}

class _OtpState extends State<Otp> {
  int isPhoneEntered = 0;
  bool hindi = false;
  TextEditingController phoneController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  String actualOtp = '';
  int? resendToken;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          Scaffold(
              appBar: AppBar(
                leading: IconButton(
                    onPressed: () {
                      setState(() {
                        isPhoneEntered = 0;
                        phoneController.clear();
                        otpController.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    )),
                backgroundColor: const Color.fromARGB(255, 36, 69, 66),
                title: Text(hindi ? "ओटीपी" : 'OTP',
                    style: const TextStyle(color: Colors.white)),
                actions: [
                  Center(
                      child: Text(hindi ? 'हिन्दी  ' : 'English ',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
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
                  Center(
                      child: Padding(
                    padding: const EdgeInsets.only(
                      left: 30,
                      right: 30,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (isPhoneEntered == 0)
                          TextField(
                              cursorColor: Colors.white,
                              controller: phoneController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: hindi
                                    ? 'फ़ोन नंबर दर्ज करें'
                                    : 'Enter Phone Number',
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                contentPadding:
                                    const EdgeInsets.only(bottom: 0, left: 15),
                              ),
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        const SizedBox(
                          height: 10,
                        ),
                        if (isPhoneEntered == 0)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            onPressed: () async {
                              try {
                                if (phoneController.text.isNotEmpty &&
                                    phoneController.text.length == 10 &&
                                    int.tryParse(phoneController.text) !=
                                        null) {
                                  setState(() {
                                    isPhoneEntered = 2;
                                  });
                                  await FirebaseAuth.instance
                                      .verifyPhoneNumber(
                                    phoneNumber: '+91${phoneController.text}',
                                    verificationCompleted:
                                        (PhoneAuthCredential credential) {
                                      FirebaseAuth.instance
                                          .signInWithCredential(credential)
                                          .then((value) => {
                                            if (context.mounted)
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (BuildContext
                                                            context) =>
                                                        const Facility(),
                                                  ),
                                                )
                                              });
                                    },
                                    verificationFailed:
                                        (FirebaseAuthException e) {
                                      throw Exception(e.message);
                                    },
                                    codeSent: (String verificationId,
                                        int? resendToken) {
                                      actualOtp = verificationId;
                                      this.resendToken = resendToken;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(hindi
                                              ? 'दर्ज किए गए नंबर पर ओटीपी भेजी गई है'
                                              : 'OTP sent to the entered number'),
                                        ),
                                      );
                                      setState(() {
                                        isPhoneEntered = 1;
                                      });
                                    },
                                    codeAutoRetrievalTimeout:
                                        (String verificationId) {},
                                  )
                                      .catchError((e) {
                                    throw Exception(e.toString());
                                  });
                                } else {
                                  throw Exception('Invalid Phone Number');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              hindi ? 'जमा करें' : 'SUBMIT',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                        if (isPhoneEntered == 1)
                          TextField(
                              cursorColor: Colors.white,
                              controller: otpController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText:
                                    hindi ? 'ओटीपी दर्ज करें' : 'Enter OTP',
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                contentPadding:
                                    const EdgeInsets.only(bottom: 0, left: 15),
                              ),
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        const SizedBox(
                          height: 10,
                        ),
                        if (isPhoneEntered == 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onPressed: () async {
                                  try {
                                    if (otpController.text.isNotEmpty &&
                                        otpController.text.length == 6 &&
                                        int.tryParse(otpController.text) !=
                                            null) {
                                      setState(() {
                                        isPhoneEntered = 2;
                                      });
                                      await FirebaseAuth.instance
                                          .signInWithCredential(
                                        PhoneAuthProvider.credential(
                                          verificationId: actualOtp,
                                          smsCode: otpController.text,
                                        ),
                                      );
                                      final userDoc = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(FirebaseAuth
                                              .instance.currentUser!.uid);
                                      final docSnapshot = await userDoc.get();
                                      if (docSnapshot.exists) {
                                        await userDoc.update({
                                          'timestamp':
                                              FieldValue.serverTimestamp(),
                                        });
                                      } else {
                                        await userDoc.set({
                                          'phone': phoneController.text,
                                          'isAdmin': false,
                                          'timestamp':
                                              FieldValue.serverTimestamp(),
                                        });
                                      }

                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                const Facility(),
                                          ),
                                        );
                                      }
                                    } else {
                                      throw Exception('Invalid OTP');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString()),
                                        ),
                                      );
                                      setState(() {
                                        isPhoneEntered = 0;
                                      });
                                    }
                                  }
                                },
                                child: Text(hindi ? 'सत्यापित करें' : 'VERIFY',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onPressed: () async {
                                  if (resendToken != null) {
                                    setState(() {
                                      isPhoneEntered = 2;
                                    });
                                    await FirebaseAuth.instance
                                        .verifyPhoneNumber(
                                      phoneNumber: '+91${phoneController.text}',
                                      verificationCompleted:
                                          (PhoneAuthCredential credential) {
                                        FirebaseAuth.instance
                                            .signInWithCredential(credential);
                                      },
                                      verificationFailed:
                                          (FirebaseAuthException e) {
                                        throw Exception(e.message);
                                      },
                                      codeSent: (String verificationId,
                                          int? resendToken) {
                                        actualOtp = verificationId;
                                        this.resendToken = resendToken;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'OTP resent to the entered number'),
                                          ),
                                        );
                                        setState(() {
                                          isPhoneEntered = 1;
                                        });
                                      },
                                      codeAutoRetrievalTimeout:
                                          (String verificationId) {},
                                      forceResendingToken: resendToken,
                                    );
                                  }
                                },
                                child: Text(
                                  hindi ? 'पुनः भेजें' : 'RESEND OTP',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  )),
                ],
              )),
          if (isPhoneEntered == 2)
            Container(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 0, 0, 0.5),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
