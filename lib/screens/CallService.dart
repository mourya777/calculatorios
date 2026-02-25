// lib/services/CallService.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/AppConstants.dart';

// lib/services/CallService.dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/AppConstants.dart';
import '../utils/StorageService.dart';

// lib/services/CallService.dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../utils/AppConstants.dart';
import '../utils/StorageService.dart';

// lib/services/CallService.dart
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/AppConstants.dart';
import '../utils/StorageService.dart';

class CallService extends GetxService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // Agora Engine
  RtcEngine? _engine;

  // Audio Player for ringtone
  final AudioPlayer _ringtonePlayer = AudioPlayer();

  // Reactive State Variables
  final RxBool _isInCall = false.obs;
  final RxBool _isRinging = false.obs;
  final RxInt _remoteUid = 0.obs;
  final RxMap<String, dynamic> _incomingCall = RxMap<String, dynamic>();
  final RxBool _isMuted = false.obs;
  final RxBool _isSpeakerOn = false.obs;

  // Getters
  bool get isInCall => _isInCall.value;
  bool get isRinging => _isRinging.value;
  int get remoteUid => _remoteUid.value;
  Map<String, dynamic> get incomingCall => _incomingCall.value;
  bool get isMuted => _isMuted.value;
  bool get isSpeakerOn => _isSpeakerOn.value;

  @override
  void onInit() {
    super.onInit();
    // Initialize on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }

  // Initialize Agora Engine
  Future<void> initialize() async {
    try {
      if (_engine != null) return;

      print('🎮 Initializing Agora with App ID: ${AppConstants.agoraAppId}');

      // Check if App ID is valid
      if (AppConstants.agoraAppId == "YOUR_AGORA_APP_ID" ||
          AppConstants.agoraAppId.length != 32) {
        print('❌ ERROR: Invalid Agora App ID');
        return;
      }

      // Request microphone permission
      await _requestPermissions();

      // Create and initialize Agora engine
      _engine = createAgoraRtcEngine();
      await _engine?.initialize(RtcEngineContext(appId: AppConstants.agoraAppId));

      print('✅ Agora engine created successfully');

      // Register event handlers
      _engine?.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print('✅ Joined channel: ${connection.channelId}');
          _stopRingtone();
          _isInCall.value = true;
          _isRinging.value = false;
        },

        onUserJoined: (connection, remoteUid, elapsed) {
          print('✅ Remote user joined: $remoteUid');
          _remoteUid.value = remoteUid;
          _stopRingtone();
        },

        onUserOffline: (connection, remoteUid, reason) {
          print('👋 Remote user left: $remoteUid');
          _remoteUid.value = 0;
          _isInCall.value = false;
        },

        onError: (ErrorCodeType err, String msg) {
          print('❌ Agora Error: $err - $msg');
        },
      ));

      print('✅ Agora initialized successfully');
    } catch (e) {
      print('❌ Initialize error: $e');
    }
  }

  // Request microphone permission
  Future<void> _requestPermissions() async {
    print('🎤 Requesting microphone permission...');
    PermissionStatus status = await Permission.microphone.request();
    print('🎤 Permission status: $status');

    if (status.isPermanentlyDenied) {
      print('❌ Microphone permission permanently denied');
      // ✅ CORRECT - Open app settings
      await openAppSettings(); // This is a top-level function
    }
  }

  // Start an outgoing call
  Future<bool> startCall(String channelName, int callerAgoraUid) async {
    try {
      print('📞 Starting call: $channelName');

      await initialize();

      if (_engine == null) {
        print('❌ Engine not initialized');
        return false;
      }

      await _engine?.joinChannel(
        token: "",
        channelId: channelName,
        uid: callerAgoraUid,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      return true;
    } catch (e) {
      print('❌ Error starting call: $e');
      return false;
    }
  }

  // Simulate incoming call (for testing)
  Future<void> simulateIncomingCall(String callerId, String channelName) async {
    print('📞 Incoming call from: $callerId on channel: $channelName');
    _incomingCall.value = {
      'callerId': callerId,
      'channelName': channelName,
    };
    _isRinging.value = true;

    // Play ringtone
    await _playRingtone();
  }

  // Play ringtone for incoming call
  Future<void> _playRingtone() async {
    try {
      // Stop any existing playback
      await _ringtonePlayer.stop();

      // Try to play ringtone from assets
      try {
        await _ringtonePlayer.play(AssetSource('ringtones/ringtone.mp3'));
        await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
        print('🔔 Ringtone playing (MP3)');
      } catch (e) {
        print('❌ MP3 failed: $e');
        // Try with different path
        try {
          await _ringtonePlayer.play(AssetSource('ringtone.mp3'));
          await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
          print('🔔 Ringtone playing (alternative path)');
        } catch (e) {
          print('❌ No ringtone found');
        }
      }
    } catch (e) {
      print('❌ Ringtone error: $e');
    }
  }

  // Stop ringtone
  void _stopRingtone() {
    try {
      _ringtonePlayer.stop();
      print('🔕 Ringtone stopped');
    } catch (e) {
      print('Error stopping ringtone: $e');
    }
  }

  // Accept incoming call
  void acceptCall() {
    print('✅ Call accepted');
    _stopRingtone();
    _isRinging.value = false;

    // Get my ID
    StorageService.getMyId().then((myId) {
      // Navigate to call screen with incoming call details
      Get.toNamed('/call', arguments: {
        ..._incomingCall.value,
        'isIncoming': true,
        'myId': myId,
      });
    });

    _incomingCall.value = {};
  }

  // Reject incoming call
  void rejectCall() {
    print('❌ Call rejected');
    _stopRingtone();
    _isRinging.value = false;
    _incomingCall.value = {};
  }

  // End current call
  Future<void> endCall() async {
    print('📞 Call ended');
    _stopRingtone();
    await _engine?.leaveChannel();
    _isInCall.value = false;
    _remoteUid.value = 0;
    _isRinging.value = false;
    _isMuted.value = false;
    _isSpeakerOn.value = false;
  }

  // Toggle mute
  void toggleMute() {
    _isMuted.value = !_isMuted.value;
    _engine?.muteLocalAudioStream(_isMuted.value);
    print(_isMuted.value ? '🎤 Mic muted' : '🎤 Mic unmuted');
  }

  // Toggle speaker
  void toggleSpeaker() {
    _isSpeakerOn.value = !_isSpeakerOn.value;
    _engine?.setEnableSpeakerphone(_isSpeakerOn.value);
    print(_isSpeakerOn.value ? '🔊 Speaker on' : '🎧 Speaker off');
  }

  // Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  @override
  void onClose() {
    _ringtonePlayer.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.onClose();
  }
}