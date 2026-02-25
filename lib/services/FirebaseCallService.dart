// lib/services/FirebaseCallService.dart
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:firebase_core/firebase_core.dart';

// lib/services/FirebaseCallService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// lib/services/FirebaseCallService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseCallService {
  FirebaseCallService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp();
      print('✅ FirebaseCallService initialized');
    } catch (e) {
      print('❌ FirebaseCallService error: $e');
    }
  }

  // Save call record
  Future<String?> saveCallRecord({
    required String callerId,
    required String receiverId,
    required String status,
    required int duration,
    String? channelName,
  }) async {
    try {
      await Firebase.initializeApp();
      DocumentReference docRef = await FirebaseFirestore.instance.collection('calls').add({
        'callerId': callerId,
        'receiverId': receiverId,
        'status': status,
        'duration': duration,
        'channelName': channelName ?? '',
        'startedAt': FieldValue.serverTimestamp(),
        'endedAt': status == 'ended' ? FieldValue.serverTimestamp() : null,
      });
      print('✅ Call record saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error saving call: $e');
      return null;
    }
  }

  // ✅ UPDATE CALL STATUS METHOD - Yeh missing tha
  Future<void> updateCallStatus(
      String callId,
      String status, {
        int duration = 0,
      }) async {
    try {
      await Firebase.initializeApp();
      await FirebaseFirestore.instance.collection('calls').doc(callId).update({
        'status': status,
        'duration': duration,
        'endedAt': status == 'ended' ? FieldValue.serverTimestamp() : null,
      });
      print('✅ Call status updated to: $status');
    } catch (e) {
      print('❌ Error updating call status: $e');
    }
  }

  // Get call history for a user
  Stream<QuerySnapshot> getCallHistory(String userId) {
    return FirebaseFirestore.instance
        .collection('calls')
        .where('callerId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .snapshots();
  }

  // Get call by ID
  Future<DocumentSnapshot?> getCallById(String callId) async {
    try {
      return await FirebaseFirestore.instance.collection('calls').doc(callId).get();
    } catch (e) {
      print('❌ Error getting call: $e');
      return null;
    }
  }

  // Get call by channel name
  Future<DocumentSnapshot?> getCallByChannel(String channelName) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('calls')
          .where('channelName', isEqualTo: channelName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first;
      }
      return null;
    } catch (e) {
      print('❌ Error getting call by channel: $e');
      return null;
    }
  }

  // Delete old calls (cleanup)
  Future<void> deleteOldCalls({int daysOld = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));
      final query = await FirebaseFirestore.instance
          .collection('calls')
          .where('startedAt', isLessThan: cutoff)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
      print('✅ Deleted ${query.docs.length} old call records');
    } catch (e) {
      print('❌ Error deleting old calls: $e');
    }
  }
}