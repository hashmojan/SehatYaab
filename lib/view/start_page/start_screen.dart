import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../res/colors/app_colors.dart';
import '../../res/components/round_button.dart';
import '../../res/device_size/device_size.dart';
import '../../res/routes/routes_name.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Get.toNamed(RouteName.aboutUs);
        break;
      case 1:
        Get.toNamed(RouteName.privacyPolicy);
        break;
      case 2:
        Get.toNamed(RouteName.contactSupport);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOutBack,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.heartPulse,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your Health,\nOur Priority',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * .15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: RoundButton(
                        onPress: () {
                          Get.offNamed(RouteName.homePage);
                        },
                        title: "Get Started",
                        buttonColor: Colors.white.withOpacity(0.2),
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modern Bottom Navigation Bar with Glassmorphism
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.white.withOpacity(0.5),
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    iconSize: 28,
                    selectedFontSize: 14,
                    unselectedFontSize: 12,
                    selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: GoogleFonts.poppins(),
                    items: [
                      BottomNavigationBarItem(
                        icon: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 0
                                ? Colors.white.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(LucideIcons.info),
                        ),
                        label: 'About Us',
                      ),
                      BottomNavigationBarItem(
                        icon: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 1
                                ? Colors.white.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(LucideIcons.shield),
                        ),
                        label: 'HIPAA Policy',
                      ),
                      BottomNavigationBarItem(
                        icon: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 2
                                ? Colors.white.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(LucideIcons.phone),
                        ),
                        label: 'Contact',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}