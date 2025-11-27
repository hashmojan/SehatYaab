import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/menu_widget.dart';
import '../../res/colors/app_colors.dart';
import '../../res/routes/routes_name.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileController _controller = Get.put(ProfileController());
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
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

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(LucideIcons.image, color: Colors.black),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
                onTap: () {
                  _controller.pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.camera, color: Colors.black),
                title: Text(
                  'Camera',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
                onTap: () {
                  _controller.pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit),
            onPressed: () => Get.toNamed(RouteName.editProfilePage),
          ),
        ],
      ),
      drawer: const MenuWidget(),
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
        child: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 100, bottom: 20, left: 16, right: 16),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        radius: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: _controller.profilePicURL.value.isNotEmpty
                              ? Image.network(
                            _controller.profilePicURL.value,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                              : _controller.profilePic.value != null
                              ? Image.file(
                            _controller.profilePic.value!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                              : const Icon(
                            LucideIcons.user,
                            size: 70.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(LucideIcons.camera, size: 20),
                            color: Colors.white,
                            onPressed: () => _showImagePickerOptions(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          _buildProfileTile(
                            icon: LucideIcons.user,
                            title: 'Name',
                            value: _controller.userName.value,
                          ),
                          const Divider(color: Colors.white70),
                          _buildProfileTile(
                            icon: LucideIcons.mail,
                            title: 'Email',
                            value: _controller.userEmail.value,
                          ),
                          const Divider(color: Colors.white70),
                          _buildProfileTile(
                            icon: LucideIcons.badge,
                            title: 'User ID',
                            value: _controller.userID.value,
                          ),
                          const Divider(color: Colors.white70),
                          _buildProfileTile(
                            icon: LucideIcons.lock,
                            title: 'Account Type',
                            value: _controller.userType.value ?? 'Loading...',
                            trailing: _controller.userType.value == 'Patient'
                                ? TextButton(
                              child: Text(
                                'Upgrade',
                                style: GoogleFonts.poppins(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () => Get.toNamed(RouteName.accountUpgradePage),
                            )
                                : null,
                          ),
                          if (_controller.userPhone.value.isNotEmpty) ...[
                            const Divider(color: Colors.white70),
                            _buildProfileTile(
                              icon: LucideIcons.phone,
                              title: 'Phone',
                              value: _controller.userPhone.value,
                            ),
                          ],
                          // Doctor-specific fields
                          if (_controller.userType.value == 'Doctor') ...[
                            if (_controller.userSpecialization.value.isNotEmpty) ...[
                              const Divider(color: Colors.white70),
                              _buildProfileTile(
                                icon: LucideIcons.stethoscope,
                                title: 'Specialization',
                                value: _controller.userSpecialization.value,
                              ),
                            ],
                            if (_controller.userHospital.value.isNotEmpty) ...[
                              const Divider(color: Colors.white70),
                              _buildProfileTile(
                                icon: LucideIcons.building,
                                title: 'Hospital',
                                value: _controller.userHospital.value,
                              ),
                            ],
                          ],
                          // Patient-specific fields
                          if (_controller.userType.value == 'Patient') ...[
                            if (_controller.userAge.value > 0) ...[
                              const Divider(color: Colors.white70),
                              _buildProfileTile(
                                icon: LucideIcons.cake,
                                title: 'Age',
                                value: _controller.userAge.value.toString(),
                              ),
                            ],
                            if (_controller.userGender.value.isNotEmpty) ...[
                              const Divider(color: Colors.white70),
                              _buildProfileTile(
                                icon: LucideIcons.users,
                                title: 'Gender',
                                value: _controller.userGender.value,
                              ),
                            ],
                            if (_controller.userBloodGroup.value.isNotEmpty) ...[
                              const Divider(color: Colors.white70),
                              _buildProfileTile(
                                icon: LucideIcons.droplet,
                                title: 'Blood Group',
                                value: _controller.userBloodGroup.value,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // _buildMedicalInfoSection(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 15,
        ),
      ),
      trailing: trailing,
    );
  }

// Widget _buildMedicalInfoSection() {
//   return FadeTransition(
//     opacity: _fadeAnimation,
//     child: Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(15),
//         color: Colors.white.withOpacity(0.2),
//       ),
//       child: Column(
//         children: [
//           // Show different options based on user type
//           if (_controller.userType.value == 'Patient') ...[
//             ListTile(
//               leading: const Icon(LucideIcons.fileText, color: Colors.white),
//               title: Text(
//                 'Health Records',
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               trailing: const Icon(LucideIcons.chevronRight, color: Colors.white),
//               onTap: () => Get.toNamed(RouteName.patientHealthRecordPage),
//             ),
//
//
//           ],
//           if (_controller.userType.value == 'Doctor') ...[
//             ListTile(
//               leading: const Icon(LucideIcons.calendar, color: Colors.white),
//               title: Text(
//                 'My Schedule',
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               trailing: const Icon(LucideIcons.chevronRight, color: Colors.white),
//               onTap: () => Get.toNamed(RouteName.doctorSchedulePage),
//             ),
//             const Divider(color: Colors.white70),
//             ListTile(
//               leading: const Icon(LucideIcons.users, color: Colors.white),
//               title: Text(
//                 'My Patients',
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               trailing: const Icon(LucideIcons.chevronRight, color: Colors.white),
//               // onTap: () => Get.toNamed(RouteName.doctorPatientsPage),
//             ),
//             const Divider(color: Colors.white70),
//             ListTile(
//               leading: const Icon(LucideIcons.fileText, color: Colors.white),
//               title: Text(
//                 'Patient Records',
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               trailing: const Icon(LucideIcons.chevronRight, color: Colors.white),
//               // onTap: () => Get.toNamed(RouteName.doctorRecordsPage),
//             ),
//           ],
//         ],
//       ),
//     ),
//   );
// }
}