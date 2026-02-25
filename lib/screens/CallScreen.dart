// lib/screens/CallScreen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/AppConstants.dart';
import 'CallService.dart';


import '../services/FirebaseCallService.dart';


class CallScreen extends StatefulWidget {
  final String channelName;
  final String myId;
  final String contactId;
  final bool isIncoming;

  const CallScreen({
    Key? key,
    required this.channelName,
    required this.myId,
    required this.contactId,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = Get.find<CallService>();
  final FirebaseCallService _firebaseCallService = FirebaseCallService();

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _callDuration = 0;
  String? _callId;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    // Save call record when call starts
    if (!widget.isIncoming) {
      _callId = await _firebaseCallService.saveCallRecord(
        callerId: widget.myId,
        receiverId: widget.contactId,
        status: 'ringing',
        duration: 0,
        channelName: widget.channelName,
      );

      // Start the outgoing call
      await _startOutgoingCall();
    } else {
      // For incoming call, simulate ringtone
      _callService.simulateIncomingCall(widget.contactId, widget.channelName);
    }
  }

  Future<void> _startOutgoingCall() async {
    final myAgoraUid = int.tryParse(widget.myId) ?? widget.myId.hashCode.abs() % 1000000;
    bool success = await _callService.startCall(widget.channelName, myAgoraUid);

    if (success) {
      setState(() {});
      _startTimer();
    } else {
      _showErrorAndPop('Failed to start call');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && _callService.isInCall) {
        setState(() {
          _callDuration++;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  void _showErrorAndPop(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Future.delayed(Duration(seconds: 1), () => Navigator.pop(context));
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.deepPurple.shade900, Colors.black],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 50),

                // Contact Avatar
                CircleAvatar(
                  radius: 70,
                  backgroundColor: AppConstants.deepPurpleColor,
                  child: Text(
                    widget.contactId[0],
                    style: TextStyle(fontSize: 50, color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),

                // Contact ID
                Text(
                  'ID: ${widget.contactId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Call Status
                Obx(() {
                  if (_callService.isInCall) {
                    return Text(
                      'Connected • ${_formatDuration(_callDuration)}',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    );
                  } else if (widget.isIncoming && _callService.isRinging) {
                    return const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ring_volume, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Incoming call... 🔔',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ],
                    );
                  } else {
                    return const Text(
                      'Calling...',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    );
                  }
                }),

                Spacer(),

                // Call Controls (Mute, End, Speaker)
                if (!widget.isIncoming || !_callService.isRinging)
                  _buildCallControls(),

                SizedBox(height: 50),
              ],
            ),
          ),

          // Incoming Call Buttons (Accept/Reject)
          if (widget.isIncoming && _callService.isRinging)
            _buildIncomingCallButtons(),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute Button
        _buildControlButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          color: _isMuted ? Colors.red : Colors.white,
          label: 'Mute',
          onTap: () {
            setState(() {
              _isMuted = !_isMuted;
            });
            _callService.toggleMute();
          },
        ),

        // End Call Button
        GestureDetector(
          onTap: () async {
            // Update call record when ended
            if (_callId != null && _callId!.isNotEmpty) {
              await _firebaseCallService.updateCallStatus(
                _callId!,
                'ended',
                duration: _callDuration,
              );
            }
            await _callService.endCall();
            _timer.cancel();
            Navigator.pop(context);
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),

        // Speaker Button
        _buildControlButton(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
          color: _isSpeakerOn ? Colors.green : Colors.white,
          label: 'Speaker',
          onTap: () {
            setState(() {
              _isSpeakerOn = !_isSpeakerOn;
            });
            _callService.toggleSpeaker();
          },
        ),
      ],
    );
  }

  Widget _buildIncomingCallButtons() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject Button
          GestureDetector(
            onTap: () {
              _callService.rejectCall();
              Navigator.pop(context);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          // Accept Button
          GestureDetector(
            onTap: () {
              // Accept the incoming call
              _callService.acceptCall();

              // Navigate to call screen as active call
              Get.offNamed('/call', arguments: {
                'channelName': widget.channelName,
                'myId': widget.myId,
                'contactId': widget.contactId,
                'isIncoming': false,
              });

              _startTimer();
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _callService.endCall();
    super.dispose();
  }
}