import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../res/colors/app_colors.dart';

class MedicalInputField extends StatelessWidget {
  final Function(String) onSendMessage;
  final bool isResponding;
  final VoidCallback onEmergencyTap;

  const MedicalInputField({
    super.key,
    required this.onSendMessage,
    required this.isResponding,
    required this.onEmergencyTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !isResponding,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask about symptoms, medications...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.medical_information, color: Colors.white),
                        onPressed: () {
                          // Add quick medical info options
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => MedicalQuickOptions(
                              onSelect: (text) {
                                controller.text = text;
                                Navigator.pop(ctx);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    onSubmitted: (text) => _sendMessage(controller),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(controller),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          EmergencyButton(onPressed: onEmergencyTap),
        ],
      ),
    );
  }

  void _sendMessage(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isNotEmpty && !isResponding) {
      onSendMessage(text);
      controller.clear();
    }
  }
}

class EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EmergencyButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: Text('Medical Emergency',
            style: GoogleFonts.poppins(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class MedicalQuickOptions extends StatelessWidget {
  final Function(String) onSelect;

  const MedicalQuickOptions({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      'What are the symptoms of diabetes?',
      'How to manage high blood pressure?',
      'Side effects of paracetamol',
      'When should I see a doctor for a fever?',
      'First aid for chest pain'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quick Questions',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...options.map((option) => ListTile(
            title: Text(option, style: GoogleFonts.poppins()),
            onTap: () => onSelect(option),
          )).toList(),
        ],
      ),
    );
  }
}