// lib/services/chat_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';



class ChatService {
  static const String _chatsKey = 'chat_messages';

  // Send message
  static Future<void> sendMessage(String fromId, String toId, String message) async {
    final prefs = await SharedPreferences.getInstance();
    String chatId = _getChatId(fromId, toId);

    List<Map<String, dynamic>> messages = await _getMessages(chatId);

    messages.add({
      'fromId': fromId,
      'toId': toId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'isSeen': false,
    });

    await _saveMessages(chatId, messages);
  }

  // Get messages
  static Future<List<Map<String, dynamic>>> getMessages(String id1, String id2) async {
    String chatId = _getChatId(id1, id2);
    return await _getMessages(chatId);
  }

  // Mark messages as seen
  static Future<void> markAsSeen(String fromId, String toId) async {
    String chatId = _getChatId(fromId, toId);
    List<Map<String, dynamic>> messages = await _getMessages(chatId);

    for (var msg in messages) {
      if (msg['fromId'] == fromId && msg['toId'] == toId) {
        msg['isSeen'] = true;
      }
    }

    await _saveMessages(chatId, messages);
  }

  // Check if has unread messages
  static Future<bool> hasUnreadMessages(String myId, String otherId) async {
    String chatId = _getChatId(myId, otherId);
    List<Map<String, dynamic>> messages = await _getMessages(chatId);

    return messages.any((msg) =>
    msg['fromId'] == otherId &&
        msg['toId'] == myId &&
        msg['isSeen'] == false
    );
  }

  static String _getChatId(String id1, String id2) {
    if (id1.compareTo(id2) < 0) {
      return '${id1}_$id2';
    } else {
      return '${id2}_$id1';
    }
  }

  static Future<List<Map<String, dynamic>>> _getMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('$_chatsKey$chatId');
    if (jsonString == null) return [];

    List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> _saveMessages(String chatId, List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_chatsKey$chatId', jsonEncode(messages));
  }
}