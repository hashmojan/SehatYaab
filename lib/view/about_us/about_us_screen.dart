import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../res/colors/app_colors.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "About sehatyab",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // Logo with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Center(
                    child: ClipOval(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 0,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/sehatyab.png', // Update with your medical logo
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Version text
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    "Version 1.0.0",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Welcome section
              _buildAnimatedSection(
                title: "Welcome to sehatyab!",
                content:
                "sehatyab is a comprehensive healthcare platform designed to bridge the gap between patients and healthcare providers. "
                    "Our mission is to make healthcare more accessible, efficient, and patient-centered through innovative technology solutions. "
                    "With secure electronic medical records, seamless appointment scheduling, and telemedicine capabilities, we're transforming healthcare delivery.",
              ),

              const SizedBox(height: 25),

              // Core Features section
              _buildAnimatedSection(
                title: "Key Features",
                children: [
                  _buildFeatureTile("Secure Patient Records", LucideIcons.shield),
                  _buildFeatureTile("Doctor-Patient Messaging", LucideIcons.messageCircle),
                  _buildFeatureTile("Appointment Scheduling", LucideIcons.calendar),
                  _buildFeatureTile("E-Prescriptions", LucideIcons.fileText),
                  _buildFeatureTile("Lab Results Tracking", LucideIcons.flaskConical),
                  _buildFeatureTile("Medical Assistant AI", LucideIcons.bot),
                  _buildFeatureTile("Health Analytics", LucideIcons.barChart),
                  _buildFeatureTile("Emergency Services", LucideIcons.alertCircle),
                  _buildFeatureTile("Multi-Language Support", LucideIcons.languages),
                  _buildFeatureTile("HIPAA Compliant", LucideIcons.lock),
                ],
              ),

              const SizedBox(height: 25),

              // Development Team section
              // _buildAnimatedSection(
              //   title: "Our Healthcare Team",
              //   children: [
              //     Container(
              //       decoration: BoxDecoration(
              //         color: Colors.white.withOpacity(0.1),
              //         borderRadius: BorderRadius.circular(15),
              //       ),
              //       child: Column(
              //         children: [
              //           _buildTeamMember(
              //             "assets/images/doctor1.png",
              //             "Dr. Sarah Khan",
              //             "Chief Medical Officer",
              //           ),
              //           _buildTeamMember(
              //             "assets/images/developer1.png",
              //             "Ali Ahmed",
              //             "Lead Developer",
              //           ),
              //           _buildTeamMember(
              //             "assets/images/designer1.png",
              //             "Fatima Malik",
              //             "UX Designer",
              //           ),
              //         ],
              //       ),
              //     ),
              //   ],
              // ),

              const SizedBox(height: 25),

              // Contact Support section
              _buildAnimatedSection(
                title: "Contact Us",
                children: [
                  _buildContactRow(),
                ],
              ),

              const SizedBox(height: 20),

              // Footer
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Center(
                    child: Text(
                      "© 2024 sehatyab. All rights reserved",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required String title,
    String? content,
    List<Widget>? children,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title),
            if (content != null) _buildSectionContent(content),
            if (children != null) ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  Widget _buildSectionContent(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 16,
      height: 1.5,
      color: Colors.white.withOpacity(0.9),
    ),
    textAlign: TextAlign.justify,
  );

  Widget _buildFeatureTile(String title, IconData icon) => ListTile(
    leading: Icon(icon, size: 24, color: Colors.white),
    title: Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: const Icon(LucideIcons.chevronRight, size: 20, color: Colors.white),
  );

  Widget _buildTeamMember(String image, String name, String role) => ListTile(
    leading: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
    ),
    title: Text(
      name,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    subtitle: Text(
      role,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.white.withOpacity(0.8),
        fontStyle: FontStyle.italic,
      ),
    ),
  );

  Widget _buildContactRow() => Center(
    child: Wrap(
      spacing: 20,
      children: [
        IconButton(
          icon: const Icon(LucideIcons.mail),
          color: Colors.white,
          onPressed: () => _launchEmail("hashamahmad0300@gmail.com"),
        ),
        IconButton(
          icon: const Icon(LucideIcons.globe),
          color: Colors.white,
          onPressed: () => _launchWebsite("https://sehatyab.com"),
        ),
        IconButton(
          icon: const Icon(LucideIcons.phone),
          color: Colors.white,
          onPressed: () => _callNumber("+923199172653"),
        ),
      ],
    ),
  );

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=sehatyab Support&body=Hello Healthcare Team,',
    );

    try {
      if (await canLaunchUrl(params)) {
        await launchUrl(params);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not launch email client');
    }
  }

  Future<void> _launchWebsite(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not launch website');
    }
  }

  Future<void> _callNumber(String number) async {
    final Uri params = Uri(
      scheme: 'tel',
      path: number,
    );

    try {
      if (await canLaunchUrl(params)) {
        await launchUrl(params);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not make phone call');
    }
  }
}