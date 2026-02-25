import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ChatService.dart';
import '../utils/AppConstants.dart';
import 'CallScreen.dart';

// lib/screens/ChatScreen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/FirebaseChatService.dart';
import '../utils/AppConstants.dart';

// lib/screens/ChatScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/FirebaseChatService.dart';
import '../services/FirebaseCallService.dart';
import '../utils/AppConstants.dart';

class ChatScreen extends StatefulWidget {
  final String myId;
  final String contactId;

  const ChatScreen({Key? key, required this.myId, required this.contactId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseChatService _chatService = FirebaseChatService();
  final FirebaseCallService _callService = FirebaseCallService();

  String _chatId = '';

  @override
  void initState() {
    super.initState();
    _chatId = widget.myId.compareTo(widget.contactId) < 0
        ? '${widget.myId}_${widget.contactId}'
        : '${widget.contactId}_${widget.myId}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Chat with ${widget.contactId}',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: Colors.green),
            onPressed: _startCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.myId, widget.contactId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                // Mark messages as seen when displayed
                for (var msg in messages) {
                  if (msg['fromId'] != widget.myId && !(msg['seenBy']?.contains(widget.myId) ?? false)) {
                    _chatService.markAsSeen(msg.id, _chatId, widget.myId);
                  }
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['fromId'] == widget.myId;

                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot msg, bool isMe) {
    final data = msg.data() as Map<String, dynamic>;
    List seenBy = data['seenBy'] ?? [];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppConstants.accentColor : AppConstants.deepPurpleColor,
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              data['message'] ?? '',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data['timestamp'] != null
                      ? DateFormat('HH:mm').format(
                    (data['timestamp'] as Timestamp).toDate(),
                  )
                      : '',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                if (isMe && seenBy.length >= 2)
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.done_all, size: 12, color: Colors.blue),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      color: AppConstants.secondaryDark,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: AppConstants.accentColor, size: 30),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _chatService.sendMessage(
        widget.myId,
        widget.contactId,
        _messageController.text.trim(),
      );

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startCall() {
    final channelName = 'call_${widget.myId}_${widget.contactId}_${DateTime.now().millisecondsSinceEpoch}';

    // Save call record to Firebase
    _callService.saveCallRecord(
      callerId: widget.myId,
      receiverId: widget.contactId,
      status: 'initiated',
      duration: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          myId: widget.myId,
          contactId: widget.contactId,
          isIncoming: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}