import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sehatyab/res/routes/routes_name.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/input_field.dart';
import '../../../res/components/round_button.dart';
import '../../../res/device_size/device_size.dart';
import '../../../view_model/controller/authentication_controller/dr_signup_view_model.dart';

class DoctorSignupPage extends StatefulWidget {
  const DoctorSignupPage({super.key});

  @override
  State<DoctorSignupPage> createState() => _DoctorSignupPageState();
}

class _DoctorSignupPageState extends State<DoctorSignupPage> with SingleTickerProviderStateMixin {
  final _formkey = GlobalKey<FormState>();
  late AnimationController _animationController;
  final doctorSignupVM = Get.put(DoctorSignupViewModel());
  final _scrollController = ScrollController();

  final List<String> _cities = [
    'Peshawar', 'Abbottabad', 'Mardan', 'Swat', 'Mingora', 'Nowshera',
    'Charsadda', 'Kohat', 'Mansehra', 'Haripur', 'Dera Ismail Khan (DI Khan)',
    'Bannu', 'Swabi', 'Batkhela (Malakand)', 'Timergara (Dir Lower)',
    'Dir Upper', 'Chitral', 'Hangu', 'Lakki Marwat', 'Tank', 'Battagram',
    'Karak', 'Shangla', 'Buner', 'Torghar',
  ];
  String? _selectedCities;

  final List<String> _specializations = [
    'Cardiologist', 'Dermatologist', 'Endocrinologist', 'Gastroenterologist',
    'Neurologist', 'Nephrologist', 'Oncologist', 'Orthopedic', 'Pediatrician',
    'Psychiatrist', 'Pulmonologist', 'Rheumatologist',
  ];
  String? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withOpacity(0.95),
              AppColors.secondaryColor.withOpacity(0.95),
              Colors.blue.shade900.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: isWeb
                      ? Container(
                    width: 500,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: _buildDoctorSignupForm(context, size),
                  )
                      : _buildDoctorSignupForm(context, size),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSignupForm(BuildContext context, Size size) {
    return Form(
      key: _formkey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: Curves.elasticOut,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    LucideIcons.stethoscope,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Join Our Medical Community',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your doctor account and start helping patients',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: height * .04),

          // Personal Information Section
          _buildSectionHeader('Personal Information'),
          SizedBox(height: height * .02),

          // Title and Name in Row for web, column for mobile
          MediaQuery.of(context).size.width > 600
              ? Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildAnimatedInputField(
                  index: 0,
                  controller: doctorSignupVM.titleController,
                  hintText: 'Title (Dr./Prof.)',
                  icon: LucideIcons.award,
                  validator: (value) => value!.isEmpty ? 'Please enter your title' : null,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 3,
                child: _buildAnimatedInputField(
                  index: 1,
                  controller: doctorSignupVM.nameController,
                  hintText: 'Full Name',
                  icon: LucideIcons.user,
                  validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                ),
              ),
            ],
          )
              : Column(
            children: [
              _buildAnimatedInputField(
                index: 0,
                controller: doctorSignupVM.titleController,
                hintText: 'Title (Dr./Prof.)',
                icon: LucideIcons.award,
                validator: (value) => value!.isEmpty ? 'Please enter your title' : null,
              ),
              SizedBox(height: height * .02),
              _buildAnimatedInputField(
                index: 1,
                controller: doctorSignupVM.nameController,
                hintText: 'Full Name',
                icon: LucideIcons.user,
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
            ],
          ),

          SizedBox(height: height * .02),

          // Contact Information Section
          _buildSectionHeader('Contact Information'),
          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 2,
            controller: doctorSignupVM.phoneController,
            hintText: 'Phone Number (e.g., 03001234567)',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value!.isEmpty || !RegExp(r'^03\d{9}$').hasMatch(value)) {
                return 'Invalid phone number (e.g., 03xxxxxxxxx)';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 3,
            controller: doctorSignupVM.emailController,
            hintText: 'Email Address',
            icon: LucideIcons.mail,
            validator: (value) {
              if (value!.isEmpty || !value.isEmail) {
                return 'Invalid email address';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 4,
            controller: doctorSignupVM.passwordController,
            hintText: 'Password',
            icon: LucideIcons.lock,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),

          SizedBox(height: height * .02),

          // Professional Information Section
          _buildSectionHeader('Professional Information'),
          SizedBox(height: height * .02),

          // City and Specialization in Row for web
          MediaQuery.of(context).size.width > 600
              ? Row(
            children: [
              Expanded(
                child: _buildAnimatedDropdown(
                  index: 5,
                  items: _cities,
                  hintText: 'Select City',
                  value: _selectedCities,
                  icon: LucideIcons.mapPin,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCities = newValue;
                      doctorSignupVM.cityController.text = newValue ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildAnimatedDropdown(
                  index: 6,
                  items: _specializations,
                  hintText: 'Specialization',
                  value: _selectedSpecialization,
                  icon: LucideIcons.briefcase,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSpecialization = newValue;
                      doctorSignupVM.specializationController.text = newValue ?? '';
                    });
                  },
                ),
              ),
            ],
          )
              : Column(
            children: [
              _buildAnimatedDropdown(
                index: 5,
                items: _cities,
                hintText: 'Select City',
                value: _selectedCities,
                icon: LucideIcons.mapPin,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCities = newValue;
                    doctorSignupVM.cityController.text = newValue ?? '';
                  });
                },
              ),
              SizedBox(height: height * .02),
              _buildAnimatedDropdown(
                index: 6,
                items: _specializations,
                hintText: 'Specialization',
                value: _selectedSpecialization,
                icon: LucideIcons.briefcase,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpecialization = newValue;
                    doctorSignupVM.specializationController.text = newValue ?? '';
                  });
                },
              ),
            ],
          ),

          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 7,
            controller: doctorSignupVM.yearsOfExperienceController,
            hintText: 'Years of Experience',
            icon: LucideIcons.calendar,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter years of experience';
              }
              if (int.tryParse(value) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),

          SizedBox(height: height * .02),

          // Gender Selection
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
            )),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gender',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Row(
                    children: [
                      _buildGenderOption(
                        value: 'male',
                        label: 'Male',
                        icon: LucideIcons.user,
                        isSelected: doctorSignupVM.gender.value == 'male',
                        onTap: () => doctorSignupVM.gender.value = 'male',
                      ),
                      const SizedBox(width: 16),
                      _buildGenderOption(
                        value: 'female',
                        label: 'Female',
                        icon: LucideIcons.user,
                        isSelected: doctorSignupVM.gender.value == 'female',
                        onTap: () => doctorSignupVM.gender.value = 'female',
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ),

          SizedBox(height: height * .04),

          // Sign Up Button
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
            ),
            child: Obx(() => RoundButton(
              title: 'CREATE DOCTOR ACCOUNT',
              width: double.infinity,
              buttonColor: Colors.white,
              textColor: AppColors.primaryColor,
              onPress: () {
                if (_formkey.currentState!.validate() && _selectedSpecialization != null) {
                  doctorSignupVM.loading.value = true;
                  // Your signup logic here
                  doctorSignupVM.signUpDoctor();
                } else if (_selectedSpecialization == null) {
                  Get.snackbar(
                    'Selection Required',
                    'Please select your specialization',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                    borderRadius: 12,
                    margin: const EdgeInsets.all(16),
                  );
                }
              },
              loading: doctorSignupVM.loading.value,
            )),
          ),

          SizedBox(height: height * .03),

          // Login Link
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.9, 1.0),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have a Doctor Account? ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(RouteName.loginPage),
                    child: Text(
                      'Login Here',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      )),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAnimatedInputField({
    required int index,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.1 + (index * 0.1), 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.1 + (index * 0.1), 1.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InputField(
            controller: controller,
            fillColor: Colors.white.withOpacity(0.15),
            errorcolor: Colors.orange.shade300,
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
            prefixIconWidth: 80.0,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDropdown({
    required int index,
    required List<String> items,
    required String hintText,
    required String? value,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.1 + (index * 0.1), 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.1 + (index * 0.1), 1.0),
        ),
        child: CustomDropdown<String>(
          items: items,
          hintText: hintText,
          value: value,
          onChanged: onChanged,
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          fillColor: Colors.white.withOpacity(0.15),
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String value,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomDropdown<T> extends StatelessWidget {
  final List<T> items;
  final String hintText;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final Widget? prefixIcon;
  final Color? fillColor;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.hintText,
    this.value,
    this.onChanged,
    this.prefixIcon,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            if (prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: prefixIcon!,
              ),
            Expanded(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                hint: Text(
                  hintText,
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                dropdownColor: AppColors.primaryColor,
                style: GoogleFonts.poppins(color: Colors.white),
                underline: Container(),
                icon: Icon(LucideIcons.chevronDown, color: Colors.white.withOpacity(0.6)),
                items: items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      item.toString(),
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}