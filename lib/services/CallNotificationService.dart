// lib/services/CallNotificationService.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class CallNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Android notification settings
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle notification tap
        if (details.payload != null) {
          _handleCallNotification(details.payload!);
        }
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'incoming_call') {
        _showIncomingCallNotification(message.data);
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("📞 Background call: ${message.data}");
    // Handle background call
  }

  static void _showIncomingCallNotification(Map<String, dynamic> data) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'incoming_call',
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      ),
    );

    _notifications.show(
      0,
      '📞 Incoming Call',
      'Call from ID: ${data['callerId']}',
      details,
      payload: 'call|${data['channelName']}|${data['callerId']}',
    );
  }

  static void _handleCallNotification(String payload) {
    final parts = payload.split('|');
    if (parts[0] == 'call') {
      Get.toNamed('/call', arguments: {
        'channelName': parts[1],
        'callerId': parts[2],
        'isIncoming': true,
      });
    }
  }

  static Future<void> sendCallNotification(String callerId, String channelName, String targetFcmToken) async {
    // Send via FCM
    // This would typically be done from a server
    print('📞 Sending call notification to $targetFcmToken');
  }
}