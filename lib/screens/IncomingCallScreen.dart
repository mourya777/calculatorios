// lib/screens/IncomingCallScreen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/AppConstants.dart';
import 'CallService.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerId;
  final String channelName;

  const IncomingCallScreen({
    Key? key,
    required this.callerId,
    required this.channelName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callService = Get.find<CallService>();

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: AppConstants.deepPurpleColor,
              child: Text(
                callerId[0],
                style: TextStyle(fontSize: 50, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Incoming Call',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            Text(
              'ID: $callerId',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject Button
                GestureDetector(
                  onTap: () {
                    callService.rejectCall();
                    Get.back();
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 40),
                  ),
                ),
                // Accept Button
                GestureDetector(
                  onTap: () {
                    callService.acceptCall();
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call, color: Colors.white, size: 40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}