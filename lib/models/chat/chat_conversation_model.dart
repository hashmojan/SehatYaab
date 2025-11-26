import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversation {
  final String id;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final String? doctorImage;
  final String? patientImage;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final Timestamp? lastMessageAt;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Map<String, int> unreadCount; // userId -> unread messages count

  ChatConversation({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.doctorImage,
    this.patientImage,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    Map<String, int>? unreadCount,
  }) : unreadCount = unreadCount ?? const {};

  factory ChatConversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final Map<String, dynamic> rawUnread =
    (data['unreadCount'] as Map<String, dynamic>? ?? {});
    final Map<String, int> unread = rawUnread.map(
          (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
    );

    return ChatConversation(
      id: doc.id,
      doctorId: (data['doctorId'] ?? '') as String,
      patientId: (data['patientId'] ?? '') as String,
      doctorName: (data['doctorName'] ?? '') as String,
      patientName: (data['patientName'] ?? '') as String,
      doctorImage: data['doctorImage'] as String?,
      patientImage: data['patientImage'] as String?,
      participants: List<String>.from(data['participants'] ?? const []),
      lastMessage: data['lastMessage'] as String?,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageAt: data['lastMessageAt'] as Timestamp?,
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
      unreadCount: unread,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'doctorImage': doctorImage,
      'patientImage': patientImage,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'unreadCount': unreadCount,
    };
  }
}
