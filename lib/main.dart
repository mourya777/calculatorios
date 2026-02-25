import 'package:calculator/screens/CallService.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/CalculatorScreen.dart';
import 'utils/AppConstants.dart';

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/CalculatorScreen.dart';
import 'utils/AppConstants.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/CalculatorScreen.dart';
import 'utils/AppConstants.dart';

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/CalculatorScreen.dart';
import 'screens/CallScreen.dart';
import 'screens/IncomingCallScreen.dart';
import 'services/CallNotificationService.dart';
import 'utils/StorageService.dart';
import 'utils/AppConstants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // Initialize notifications
    await CallNotificationService.initialize();

    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    print('📱 FCM Token: $token');

  } catch (e) {
    print('❌ Firebase error: $e');
  }

  Get.put(CallService());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => CalculatorScreen()),
        GetPage(name: '/call', page: () {
          final args = Get.arguments;
          return CallScreen(
            channelName: args['channelName'],
            myId: args['myId'],
            contactId: args['callerId'] ?? args['contactId'],
            isIncoming: args['isIncoming'] ?? false,
          );
        }),
        GetPage(name: '/incoming-call', page: () {
          final args = Get.arguments;
          return IncomingCallScreen(
            callerId: args['callerId'],
            channelName: args['channelName'],
          );
        }),
      ],
    );
  }
}ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGquq/0C15EZIy0SUNYeS/o5cwV8kJPgpqbVFR4Pciie dsoijabalpur@gmail.com