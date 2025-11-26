import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat/chat_conversation_model.dart';
import '../../models/chat/chat_message_model.dart';

class ChatService {
  ChatService._internal();

  static final ChatService _instance = ChatService._internal();
  static ChatService get instance => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _conversationsCol =>
      _db.collection('conversations');

  // ------------------ CONVERSATION HELPERS ------------------

  /// Deterministic conversation id: <doctorId>_<patientId>
  String _conversationId(String doctorId, String patientId) {
    // doctor/patient roles are fixed, so no need to sort.
    return '${doctorId}_$patientId';
  }

  /// Create or get an existing doctor–patient conversation.
  Future<ChatConversation> createOrGetConversation({
    required String doctorId,
    required String patientId,
    required String doctorName,
    required String patientName,
    String? doctorImage,
    String? patientImage,
  }) async {
    final convId = _conversationId(doctorId, patientId);
    final convRef = _conversationsCol.doc(convId);

    final snap = await convRef.get();
    if (snap.exists) {
      return ChatConversation.fromDoc(
        snap as DocumentSnapshot<Map<String, dynamic>>,
      );
    }

    final now = Timestamp.now();
    final conversation = ChatConversation(
      id: convId,
      doctorId: doctorId,
      patientId: patientId,
      doctorName: doctorName,
      patientName: patientName,
      doctorImage: doctorImage,
      patientImage: patientImage,
      participants: [doctorId, patientId],
      createdAt: now,
      updatedAt: now,
      lastMessage: null,
      lastMessageAt: null,
      lastMessageSenderId: null,
      unreadCount: {
        doctorId: 0,
        patientId: 0,
      },
    );

    await convRef.set(conversation.toMap());
    return conversation;
  }


  Stream<List<ChatConversation>> streamUserConversations(String userId) {
    return _conversationsCol
        .where('participants', arrayContains: userId)
    // DO NOT call orderBy('updatedAt') here to avoid composite index requirement
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ChatConversation.fromDoc(
        d as DocumentSnapshot<Map<String, dynamic>>,
      ))
          .toList();

      // Sort in Dart by updatedAt DESC (newest first)
      list.sort((a, b) {
        final aTime = a.updatedAt.toDate();
        final bTime = b.updatedAt.toDate();
        return bTime.compareTo(aTime);
      });

      return list;
    });
  }


  /// Mark conversation unread count for given user as zero.
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    final convRef = _conversationsCol.doc(conversationId);
    await convRef.update({
      'unreadCount.$userId': 0,
    });
  }

  // ------------------ MESSAGE HELPERS ------------------

  CollectionReference<Map<String, dynamic>> _messagesCol(String convId) {
    return _conversationsCol.doc(convId).collection('messages');
  }

  /// Stream messages for a conversation.
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _messagesCol(conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ChatMessage.fromDoc(d))
        .toList());
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    required String receiverId,
    String? imageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    final senderId = currentUser.uid;
    final msgRef = _messagesCol(conversationId).doc();
    final now = Timestamp.now();

    final msg = ChatMessage(
      id: msgRef.id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: text.trim(),
      imageUrl: imageUrl,
      createdAt: now,
      isRead: false,
    );

    final convRef = _conversationsCol.doc(conversationId);

    await _db.runTransaction((tx) async {
      // ✅ 1. READ first
      final convSnap = await tx.get(convRef);

      // ✅ 2. WRITE message
      tx.set(msgRef, msg.toMap());

      // ✅ 3. UPDATE conversation
      if (!convSnap.exists) {
        // Conversation doc doesn't exist yet (edge case)
        tx.set(
          convRef,
          {
            'lastMessage': msg.text,
            'lastMessageSenderId': senderId,
            'lastMessageAt': now,
            'updatedAt': now,
            'unreadCount': {
              senderId: 0,
              receiverId: 1,
            },
          },
          SetOptions(merge: true),
        );
      } else {
        tx.update(convRef, {
          'lastMessage': msg.text,
          'lastMessageSenderId': senderId,
          'lastMessageAt': now,
          'updatedAt': now,
          'unreadCount.$receiverId': FieldValue.increment(1),
        });
      }
    });
  }

  /// Mark all messages received by [userId] in this conversation as read.
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    final snap = await _messagesCol(conversationId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
