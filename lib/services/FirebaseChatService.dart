// lib/services/FirebaseChatService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// lib/services/FirebaseChatService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseChatService {
  late final FirebaseFirestore _firestore;

  FirebaseChatService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      print('✅ FirebaseChatService initialized');
    } catch (e) {
      print('❌ FirebaseChatService error: $e');
    }
  }

  String _getChatId(String id1, String id2) {
    if (id1.compareTo(id2) < 0) {
      return '${id1}_$id2';
    } else {
      return '${id2}_$id1';
    }
  }

  Future<void> sendMessage(String fromId, String toId, String message) async {
    try {
      await Firebase.initializeApp();
      String chatId = _getChatId(fromId, toId);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'fromId': fromId,
        'toId': toId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'seenBy': [fromId],
        'status': 'sent',
      });
      print('✅ Message sent');
    } catch (e) {
      print('❌ Error sending message: $e');
    }
  }

  Stream<QuerySnapshot> getMessages(String userId1, String userId2) {
    String chatId = _getChatId(userId1, userId2);

    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markAsSeen(String messageId, String chatId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'seenBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('❌ Error marking as seen: $e');
    }
  }
}