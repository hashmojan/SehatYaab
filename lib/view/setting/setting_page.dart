import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../res/colors/app_colors.dart';
import '../../res/routes/routes_name.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool _dataSaverMode = false;
  String _currentLanguage = 'English';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkModeEnabled = prefs.getBool('darkMode') ?? false;
      _dataSaverMode = prefs.getBool('dataSaver') ?? false;
      _currentLanguage = prefs.getString('appLanguage') ?? 'English';
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    // Update the theme controller
    await Get.find<ThemeController>().toggleTheme(value);

    // Update local state
    setState(() {
      darkModeEnabled = value;
    });
    Get.offNamed(RouteName.homePage);
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed(RouteName.loginPage);
    } catch (e) {
      Get.snackbar('Logout Error', 'Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        title: Text(
          "App Settings",
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSectionHeader("Account Settings"),
              _buildListTile(
                onTap: () => Get.toNamed(RouteName.profilePage),
                title: "Account Information",
                icon: LucideIcons.user,
              ),
              _buildListTile(
                onTap: () => Get.toNamed(RouteName.changePasswordPage),
                title: "Change Password",
                icon: LucideIcons.lock,
              ),

              _buildSectionHeader("App Preferences"),
              _buildSwitchTile(
                title: "Dark Mode",
                icon: LucideIcons.moon,
                value: Get.find<ThemeController>().isDarkMode.value,
                onChanged: _toggleDarkMode,
              ),
              _buildSwitchTile(
                title: "Data Saver Mode",
                icon: LucideIcons.database,
                value: _dataSaverMode,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('dataSaver', value);
                  setState(() => _dataSaverMode = value);
                },
              ),
              _buildListTile(
                onTap: () => _showLanguageDialog(),
                title: "App Language",
                icon: LucideIcons.languages,
                trailing: Text(
                  _currentLanguage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),

              // _buildSectionHeader("Notifications"),
              // _buildSwitchTile(
              //   title: "Enable Notifications",
              //   icon: LucideIcons.bell,
              //   value: _notificationsEnabled,
              //   onChanged: (value) => setState(() => _notificationsEnabled = value),
              // ),
              // _buildListTile(
              //   onTap: () => Get.toNamed(RouteName.notificationSettings),
              //   title: "Notification Preferences",
              //   icon: LucideIcons.settings,
              // ),

              _buildSectionHeader("Support"),
              _buildListTile(
                onTap: () => Get.toNamed(RouteName.helpCenter),
                title: "Help Center",
                icon: LucideIcons.helpCircle,
              ),
              _buildListTile(
                onTap: () => Get.toNamed(RouteName.contactSupport),
                title: "Contact Support",
                icon: LucideIcons.headphones,
              ),
              _buildListTile(
                onTap: () => Get.toNamed(RouteName.aboutUs),
                title: "About App",
                icon: LucideIcons.info,
              ),

              _buildSectionHeader("Legal"),
              _buildListTile(
                onTap: () => Get.toNamed(RouteName.termsOfService),
                title: "Terms of Service",
                icon: LucideIcons.fileText,
              ),
              _buildListTile(
                onTap: () => Get.toNamed(RouteName.privacyPolicy),
                title: "Privacy Policy",
                icon: LucideIcons.shield,
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.logOut),
                  label: const Text("Log Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => _confirmLogout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );

  Widget _buildListTile({
    required VoidCallback onTap,
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 24, color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        secondary: Icon(icon, size: 24, color: Colors.white),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryColor,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Select Language",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption("English"),
            _languageOption("हिन्दी"), // Hindi
            _languageOption("اردو"), // Urdu
            _languageOption("தமிழ்"), // Tamil
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String language) => ListTile(
    title: Text(
      language,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black,
      ),
    ),
    trailing: _currentLanguage == language
        ? Icon(Icons.check, color: AppColors.primaryColor)
        : null,
    onTap: () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appLanguage', language);
      setState(() => _currentLanguage = language);
      Navigator.pop(context);
    },
  );

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Log Out",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              "Log Out",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              logout();
            },
          ),
        ],
      ),
    );
  }
}