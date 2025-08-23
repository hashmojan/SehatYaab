import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../../res/colors/app_colors.dart';

@HiveType(typeId: 0)
class MedicalMessage {
  @HiveField(0)
  final String text;
  @HiveField(1)
  final bool isUser;
  @HiveField(2)
  final DateTime timestamp;
  @HiveField(3)
  final bool isError;
  @HiveField(4)
  final bool isImportant; // For marking important medical information

  MedicalMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.isImportant = false,
  });
}

class MedicalMessageBubble extends StatelessWidget {
  final MedicalMessage message;

  const MedicalMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: Icon(Icons.medical_services, color: Colors.white),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isError
                    ? Colors.red.shade100
                    : message.isUser
                    ? AppColors.primaryColor
                    : AppColors.secondaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: message.isImportant
                    ? Border.all(color: Colors.amber, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black,
                        fontWeight: message.isImportant ? FontWeight.bold : FontWeight.normal,
                      ),
                      code: TextStyle(
                        backgroundColor: message.isUser
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white,
                        color: message.isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: (message.isUser ? Colors.white70 : Colors.black54)
                              .withOpacity(0.6),
                        ),
                      ),
                      if (message.isImportant && !message.isUser)
                        Icon(Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.amber),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: Icon(
                  message.text.toLowerCase().contains('emergency')
                      ? Icons.emergency
                      : Icons.person,
                  color: Colors.white),
            ),
        ],
      ),
    );
  }
}