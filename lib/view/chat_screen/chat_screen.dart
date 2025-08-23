import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:sehatyab/view/chat_screen/gemini_services.dart';
import '../../res/routes/routes_name.dart';
import '../../res/colors/app_colors.dart';
import 'input_field.dart';
import 'medical_assistant_service.dart';
import 'message_bubble.dart';

class MedicalChatScreen extends StatefulWidget {
  const MedicalChatScreen({Key? key}) : super(key: key);

  @override
  State<MedicalChatScreen> createState() => _MedicalChatScreenState();
}

class _MedicalChatScreenState extends State<MedicalChatScreen> {
  late GeminiService medicalService;
  final List<MedicalMessage> messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isResponding = false;
  late Box<MedicalMessage> _messageBox;

  @override
  void initState() {
    super.initState();
    // Safely initialize medicalService
    medicalService = Get.arguments is GeminiService
        ? Get.arguments as GeminiService
        : GeminiService();
    _initHive();
    _addWelcomeMessage();
  }

  Future<void> _initHive() async {
    try {
      _messageBox = await Hive.openBox<MedicalMessage>('medical_messages');
      setState(() {
        messages.addAll(_messageBox.values);
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = MedicalMessage(
      text: "Hello! I'm your sehatyab medical assistant. "
          "I can help with general health questions, medication information, "
          "and symptom guidance. Remember, I'm not a substitute for "
          "professional medical advice. For emergencies, use the emergency button.",
      isUser: false,
      timestamp: DateTime.now(),
      isImportant: true,
    );

    if (messages.isEmpty || !messages.any((m) => m.text.contains("sehatyab"))) {
      setState(() {
        messages.add(welcomeMessage);
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _handleSendMessage(String text) async {
    if (text.isEmpty || _isResponding) return;

    final newUserMessage = MedicalMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      isImportant: text.toLowerCase().contains('emergency'),
    );

    setState(() {
      messages.add(newUserMessage);
      _isResponding = true;
    });
    _messageBox.add(newUserMessage);
    _scrollToBottom();

    try {
      final response = await medicalService.sendMessage(text);
      final botMessage = MedicalMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        isImportant: response.toLowerCase().contains('see a doctor') ||
            response.toLowerCase().contains('emergency'),
      );

      setState(() {
        messages.add(botMessage);
        _isResponding = false;
      });
      _messageBox.add(botMessage);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add(MedicalMessage(
          text: 'Error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isResponding = false;
      });
      _scrollToBottom();
    }
  }

  void _handleEmergency() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Medical Emergency', style: GoogleFonts.poppins()),
        content: Text('Please call emergency services immediately at 1122 '
            'or go to the nearest hospital.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            child: Text('CALL 1122', style: GoogleFonts.poppins(
                color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () {
              // Implement emergency call
              Navigator.pop(ctx);
            },
          ),
          TextButton(
            child: Text('NEAREST HOSPITAL', style: GoogleFonts.poppins()),
            onPressed: () {
              Get.toNamed(RouteName.nearbyHospitalsPage);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Medical Assistant',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              _addWelcomeMessage();
              _scrollToBottom();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length + (_isResponding ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= messages.length) {
                    return _buildTypingIndicator();
                  }
                  return MedicalMessageBubble(message: messages[index]);
                },
              ),
            ),
            MedicalInputField(
              onSendMessage: _handleSendMessage,
              isResponding: _isResponding,
              onEmergencyTap: _handleEmergency,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            child: Icon(Icons.medical_services, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Consulting medical resources...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}