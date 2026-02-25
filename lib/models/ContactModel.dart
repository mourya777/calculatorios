class ContactModel {
  final String id;
  final String contactId;
  final DateTime addedAt;
  bool hasUnreadChat;

  ContactModel({
    required this.id,
    required this.contactId,
    required this.addedAt,
    this.hasUnreadChat = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactId': contactId,
      'addedAt': addedAt.toIso8601String(),
      'hasUnreadChat': hasUnreadChat,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'],
      contactId: map['contactId'],
      addedAt: DateTime.parse(map['addedAt']),
      hasUnreadChat: map['hasUnreadChat'] ?? false,
    );
  }
}