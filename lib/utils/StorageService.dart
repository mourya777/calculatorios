import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';



class StorageService {
  static const String _myIdKey = 'my_agora_id';
  static const String _contactsKey = 'saved_contacts';

  // Generate random 4-digit ID
  static String generateRandomId() {
    int random = 1000 + DateTime.now().millisecondsSinceEpoch % 9000;
    return random.toString();
  }

  // Get/Save my ID (LOCAL)
  static Future<String> getMyId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_myIdKey);
    if (id == null) {
      id = generateRandomId();
      await prefs.setString(_myIdKey, id);
    }
    return id;
  }

  // Save contacts (LOCAL - only IDs)
  static Future<void> saveContacts(List<String> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_contactsKey, contacts);
  }

  // Get contacts (LOCAL) - Returns List<String>
  static Future<List<String>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_contactsKey) ?? [];
  }

  // Add contact (LOCAL)
  static Future<bool> addContact(String contactId) async {
    List<String> contacts = await getContacts();
    if (contacts.contains(contactId)) return false;

    String myId = await getMyId();
    if (contactId == myId) return false;

    contacts.add(contactId);
    await saveContacts(contacts);
    return true;
  }

  // Remove contact
  static Future<void> removeContact(String contactId) async {
    List<String> contacts = await getContacts();
    contacts.remove(contactId);
    await saveContacts(contacts);
  }
}