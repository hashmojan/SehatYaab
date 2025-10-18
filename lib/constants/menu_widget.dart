import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../res/colors/app_colors.dart';
import '../res/routes/routes_name.dart';
import '../view/patient/appointment/myappointments_page.dart';
import '../view/patient/health_records/health_records.dart';
import '../view/profile/profile_controller.dart';

class MenuWidget extends StatefulWidget {
  const MenuWidget({Key? key}) : super(key: key);

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  final ProfileController profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    profileController.fetchUserData();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Widget _buildProfileHeader() {
    return Obx(() => Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular Avatar with User Type Badge
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              radius: 30,
              child: profileController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : (profileController.profilePicURL.value.isNotEmpty
                  ? CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(profileController.profilePicURL.value),
              )
                  : const Icon(LucideIcons.user, size: 30, color: Colors.white)),
            ),



          ],

        ),
        const SizedBox(width: 16),
        // User Name and Email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                profileController.userName.value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                profileController.userEmail.value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (profileController.userType.value != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: profileController.userType.value == 'Doctor'
                        ? Colors.blue
                        : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Text(

                    profileController.userType.value == 'Doctor' ? 'Doctor' : 'Patient',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Show specialization for doctors
              if (profileController.userType.value == 'Doctor' &&
                  profileController.userSpecialization.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    profileController.userSpecialization.value,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.secondaryColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _buildProfileHeader(),
          ),
          // Common items for both roles
          _buildListTile(
            onTap: () => Get.offAllNamed(profileController.userType.value == 'Doctor'
                ? RouteName.doctorHomePage
                : RouteName.patientHomePage),
            title: "Dashboard",
            icon: LucideIcons.home,
          ),
          _buildListTile(
            onTap: () => Get.toNamed(RouteName.profilePage),
            title: "My Profile",
            icon: LucideIcons.user,
          ),

          // Patient-specific items
          Obx(() {
            if (profileController.userType.value == 'Patient') {
              return Column(
                children: [

                  _buildListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AppointmentsPage()),
                    ),
                    title: "My Appointments",
                    icon: LucideIcons.calendarCheck,
                  ),
                  _buildListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PatientHealthRecordsPage()),
                    ),
                    title: "Health Records",
                    icon: LucideIcons.clipboardList,
                  ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          // Doctor-specific items
          Obx(() {
            if (profileController.userType.value == 'Doctor') {
              return Column(
                children: [
                  _buildListTile(
                    onTap: () => Get.toNamed(RouteName.availabilityManagerPage),
                    title: "My Schedule",
                    icon: LucideIcons.calendarCheck,
                  ),
                  _buildListTile(
                    onTap: () => Get.toNamed(RouteName.doctorHomePage),
                    title: "My Patients",
                    icon: LucideIcons.users,
                  ),
                  // _buildListTile(
                  //   onTap: () => Get.toNamed(RouteName.doctorHomePage),
                  //   title: "Write Prescription",
                  //   icon: LucideIcons.fileText,
                  // ),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          // Common items
          // _buildListTile(
          //   onTap: () => Get.toNamed(RouteName.chattingPage),
          //   title: "Assistant",
          //   icon: LucideIcons.bot,
          // ),
          _buildListTile(
            onTap: () => Get.toNamed(RouteName.setting),
            title: "Settings",
            icon: LucideIcons.settings,
          ),
          _buildListTile(
            onTap: () {
              profileController.clearProfile();
              logout();
            },
            title: "Logout",
            icon: LucideIcons.logOut,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required VoidCallback onTap,
    required String title,
    required IconData icon,
  }) {
    return ListTile(
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
      trailing: const Icon(LucideIcons.chevronRight, size: 20, color: Colors.white),
    );
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed(RouteName.loginPage);
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }
}