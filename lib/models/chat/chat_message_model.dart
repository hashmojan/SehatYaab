import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final Timestamp createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.imageUrl,
    this.isRead = false,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      conversationId: (data['conversationId'] ?? '') as String,
      senderId: (data['senderId'] ?? '') as String,
      receiverId: (data['receiverId'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      isRead: (data['isRead'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}
