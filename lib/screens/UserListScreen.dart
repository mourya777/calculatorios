import 'package:flutter/material.dart';
import '../models/ContactModel.dart';
import '../services/ChatService.dart';
import '../utils/AppConstants.dart';
import '../utils/StorageService.dart';
import 'AddContactScreen.dart';
import 'ChatScreen.dart';
import 'CallScreen.dart';



class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<ContactModel> _contacts = [];  // ✅ List<ContactModel>
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    _myId = await StorageService.getMyId();

    // ✅ Convert List<String> to List<ContactModel>
    List<String> contactIds = await StorageService.getContacts();
    _contacts = contactIds.map((id) => ContactModel(
      id: id,
      contactId: id,
      addedAt: DateTime.now(), // You might want to store this separately
      hasUnreadChat: false, // Will be updated below
    )).toList();

    // Check for unread messages
    for (var contact in _contacts) {
      contact.hasUnreadChat = await ChatService.hasUnreadMessages(_myId, contact.contactId);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Contacts',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // My ID Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.deepPurpleColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.deepPurpleColor),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code, color: AppConstants.accentColor, size: 30),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My ID',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _myId,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    // Copy ID to clipboard
                  },
                  child: Icon(Icons.copy, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),

          // Contacts List
          Expanded(
            child: _contacts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No contacts yet',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add a 4-digit ID',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  color: AppConstants.secondaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppConstants.deepPurpleColor,
                          child: Text(
                            contact.contactId[0],
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        if (contact.hasUnreadChat)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      'ID: ${contact.contactId}',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    subtitle: Text(
                      'Added: ${contact.addedAt.day}/${contact.addedAt.month}/${contact.addedAt.year}',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chat,
                            color: contact.hasUnreadChat
                                ? Colors.green
                                : AppConstants.accentColor,
                            size: 28,
                          ),
                          onPressed: () => _startChat(contact),
                        ),
                        IconButton(
                          icon: Icon(Icons.call, color: Colors.green, size: 28),
                          onPressed: () => _startCall(contact),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddContactScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: AppConstants.accentColor,
        child: Icon(Icons.person_add, color: Colors.white, size: 30),
      ),
    );
  }

// In UserListScreen.dart, update _startChat method:

  void _startChat(ContactModel contact) async {
    // Mark as read when opening chat
    await ChatService.markAsSeen(_myId, contact.contactId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          myId: _myId,
          contactId: contact.contactId,
        ),
      ),
    ).then((_) => _loadData());
  }
  void _startCall(ContactModel contact) {
    final channelName = 'call_${_myId}_${contact.contactId}_${DateTime.now().millisecondsSinceEpoch}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          myId: _myId,
          contactId: contact.contactId,
          isIncoming: false,
        ),
      ),
    );
  }
}