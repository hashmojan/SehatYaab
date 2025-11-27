import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/chat/chat_conversation_model.dart';
import '../../res/colors/app_colors.dart';
import '../../services/chat/chat_services.dart';
import '../chat/doctor_chat_screen.dart';


class AllChatsPage extends StatefulWidget {
  const AllChatsPage({Key? key}) : super(key: key);

  @override
  State<AllChatsPage> createState() => _AllChatsPageState();
}

class _AllChatsPageState extends State<AllChatsPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _formatTime(DateTime dt) {
    final now = DateTime.now();

    // Same day → just show HH:mm
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    // Same year → dd/MM HH:mm
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');

    return '$dd/$mm $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'My Chats',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.lightSecondary,
        ),
        body: Center(
          child: Text(
            'You must be logged in to see your chats.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      );
    }

    final String currentUserId = _currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Chats',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.lightSecondary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: ChatService.instance.streamUserConversations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No chats yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'When you start chatting with a doctor or patient,\n'
                          'your conversations will appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conv = conversations[index];

              // Determine who is "other" person
              final bool iAmDoctor = currentUserId == conv.doctorId;
              final String otherUserId =
              iAmDoctor ? conv.patientId : conv.doctorId;
              final String otherUserName =
              iAmDoctor ? conv.patientName : conv.doctorName;
              final String? otherUserImage =
              iAmDoctor ? conv.patientImage : conv.doctorImage;

              final String lastMsg = conv.lastMessage ?? '';
              final DateTime? lastMsgTime =
              conv.lastMessageAt?.toDate();

              // unread count for current user
              final int unread = conv.unreadCount[currentUserId] ?? 0;

              return ListTile(
                onTap: () async {
                  // Mark unread as read for this conversation for current user
                  await ChatService.instance.markConversationAsRead(
                    conversationId: conv.id,
                    userId: currentUserId,
                  );
                  await ChatService.instance.markMessagesAsRead(
                    conversationId: conv.id,
                    userId: currentUserId,
                  );

                  if (!mounted) return;

                  // Open chat screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorChatScreen(
                        conversation: conv,
                        currentUserId: currentUserId,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
                  backgroundImage: (otherUserImage != null &&
                      otherUserImage.isNotEmpty)
                      ? NetworkImage(otherUserImage)
                      : null,
                  child: (otherUserImage == null ||
                      otherUserImage.isEmpty)
                      ? Text(
                    otherUserName.isNotEmpty
                        ? otherUserName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  )
                      : null,
                ),
                title: Text(
                  otherUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: lastMsg.isNotEmpty
                    ? Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                )
                    : Text(
                  'No messages yet',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lastMsgTime != null)
                      Text(
                        _formatTime(lastMsgTime),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : unread.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
