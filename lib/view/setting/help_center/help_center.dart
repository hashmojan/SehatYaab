import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/round_button.dart';
import '../../../res/routes/routes_name.dart';

class HelpCenterPage extends StatelessWidget {
  final List<FAQItem> faqs = const [
    FAQItem(
      'How to book an appointment?',
      'Go to the "Book Appointment" section from the homepage or menu. Select a doctor, date, and time to confirm your booking.',
    ),
    FAQItem(
      'Where can I see my upcoming appointments?',
      'Tap on "My Appointments" to view all scheduled, upcoming, and past appointments in one place.',
    ),
    FAQItem(
      'How can doctors access patient health records?',
      'Doctors can open "Patient Records" and search using filters like patient name, condition, or date of visit.',
    ),
    FAQItem(
      'How do I access my prescriptions?',
      'Go to "Prescriptions" from the menu to view, download, or share your prescribed medications.',
    ),
    FAQItem(
      'What is the Doctor Directory for?',
      'Use the "Doctor Directory" to browse and find specialists. You can also book appointments directly from their profile.',
    ),
    FAQItem(
      'Can I chat with a doctor or assistant?',
      'Yes, tap on "Secure Messaging" or use the "Medical Assistant" bot for quick support and FAQs.',
    ),
    FAQItem(
      'Are my medical records safe?',
      'Absolutely. We use encryption and follow data security protocols compliant with regulations like HIPAA.',
    ),
    FAQItem(
      'How do I update my health profile?',
      'Visit your profile page by clicking your avatar or menu option, and tap "Edit Profile" to update details like allergies or history.',
    ),
    FAQItem(
      'Can I upload lab reports manually?',
      'Currently, reports are added by the clinic, but future updates will allow manual uploads and document scans.',
    ),
    FAQItem(
      'What if I forget my login details?',
      'Tap "Forgot Password" on the login screen. You will receive a reset link via your registered email.',
    ),
  ];

  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Help Center',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: faqs.length,
                  itemBuilder: (context, index) => AnimatedFAQItem(
                    faq: faqs[index],
                    index: index,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedButton(
                onPress: () {
                  Get.toNamed(RouteName.contactSupport); // Update this route as needed
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedFAQItem extends StatelessWidget {
  final FAQItem faq;
  final int index;

  const AnimatedFAQItem({
    Key? key,
    required this.faq,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 4,
        color: Colors.white.withOpacity(0.2),
        child: ExpansionTile(
          title: Text(
            faq.question,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                faq.answer,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedButton extends StatelessWidget {
  final VoidCallback onPress;

  const AnimatedButton({
    Key? key,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: RoundButton(
        buttonColor: AppColors.secondaryColor,
        onPress: onPress,
        title: "Need More Help?",
        textColor: AppColors.white,
        elevation: 6,
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem(this.question, this.answer);
}
