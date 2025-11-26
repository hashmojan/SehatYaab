import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/chat/chat_conversation_model.dart';
import '../../models/chat/chat_message_model.dart';
import '../../res/colors/app_colors.dart';
import '../../services/chat/chat_services.dart';

class DoctorChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final String currentUserId;

  const DoctorChatScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late final String _otherUserId;
  late final String _otherUserName;
  String? _otherUserImage;

  @override
  void initState() {
    super.initState();
    final c = widget.conversation;
    final me = widget.currentUserId;

    if (me == c.doctorId) {
      _otherUserId = c.patientId;
      _otherUserName = c.patientName;
      _otherUserImage = c.patientImage;
    } else {
      _otherUserId = c.doctorId;
      _otherUserName = c.doctorName;
      _otherUserImage = c.doctorImage;
    }

    // Mark unread as read on open
    ChatService.instance.markConversationAsRead(
      conversationId: c.id,
      userId: me,
    );
    ChatService.instance.markMessagesAsRead(
      conversationId: c.id,
      userId: me,
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final convId = widget.conversation.id;

    try {
      await ChatService.instance.sendTextMessage(
        conversationId: convId,
        text: text,
        receiverId: _otherUserId,
      );
      _messageCtrl.clear();
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Failed to send message: $e');
      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final convId = widget.conversation.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage:
              _otherUserImage != null && _otherUserImage!.isNotEmpty
                  ? NetworkImage(_otherUserImage!)
                  : null,
              child: _otherUserImage == null || _otherUserImage!.isEmpty
                  ? Text(
                _otherUserName.isNotEmpty
                    ? _otherUserName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _otherUserName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.instance.streamMessages(convId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? const [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Start your conversation with $_otherUserName',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMine = m.senderId == widget.currentUserId;

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                          maxWidth:
                          MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.secondaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMine ? 16 : 4),
                            bottomRight: Radius.circular(isMine ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (m.text.isNotEmpty)
                              Text(
                                m.text,
                                style: GoogleFonts.poppins(
                                  color: isMine ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(m.createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: isMine
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
