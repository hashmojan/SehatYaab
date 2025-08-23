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
  // Assuming you have a controller for doctor signup
  final doctorSignupVM = Get.put(DoctorSignupViewModel()); // Or a dedicated DoctorSignupViewModel

  final List<String> _cities = [
    'Peshawar', // Capital of KPK
    'Abbottabad',
    'Mardan',
    'Swat', // Mingora is the main city
    'Mingora', // Largest city in Swat
    'Nowshera',
    'Charsadda',
    'Kohat',
    'Mansehra',
    'Haripur',
    'Dera Ismail Khan (DI Khan)',
    'Bannu',
    'Swabi',
    'Batkhela (Malakand)',
    'Timergara (Dir Lower)',
    'Dir Upper',
    'Chitral',
    'Hangu',
    'Lakki Marwat',
    'Tank',
    'Battagram',
    'Karak',
    'Shangla',
    'Buner',
    'Torghar',
  ];
  String? _selectedCities;

  // Dummy data for specialization - replace with your actual data
  final List<String> _specializations = [
     // Default option
    'Cardiologist', // Heart & blood pressure
    'Dermatologist', // Skin issues
    'Endocrinologist', // Diabetes, thyroid
    'Gastroenterologist', // Stomach, liver, digestion
    'Neurologist', // Brain, nerves, epilepsy
    'Nephrologist', // Kidney diseases
    'Oncologist', // Cancer treatment
    'Orthopedic', // Bones, joints, fractures
    'Pediatrician', // Child health
    'Psychiatrist', // Mental health (depression, anxiety)
    'Pulmonologist', // Lungs, asthma, COPD
    'Rheumatologist',

  ];
  String? _selectedSpecialization;

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

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Get.back(),
        ),
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: isWeb
                  ? Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildDoctorSignupForm(context),
              )
                  : _buildDoctorSignupForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorSignupForm(BuildContext context) {
    return Form(
      key: _formkey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutBack,
            ),
            child: Center(
              child: Text(
                'Doctor Sign Up',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: doctorSignupVM.titleController, // Assuming you have this in your controller
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'Mr./Ms./Dr./Prof.',
            prefixIcon: const Icon(
              LucideIcons.tag, // Or a more appropriate icon
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            validator: (String? value) {
              if (value!.isEmpty) {
                return 'Please enter your title';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: doctorSignupVM.nameController, // Assuming you have this in your controller
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'Name',
            prefixIcon: const Icon(
              LucideIcons.user,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            validator: (String? value) {
              if (value!.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: doctorSignupVM.phoneController, // Assuming you have this
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'eg. 03001234567',
            prefixIcon: const Icon(
              LucideIcons.phone,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            keyboardType: TextInputType.phone,
            validator: (String? value) {
              if (value!.isEmpty || !RegExp(r'^03\d{9}$').hasMatch(value)) {
                return 'Invalid phone number (e.g., 03xxxxxxxxx)';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: doctorSignupVM.emailController,
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'Email',
            prefixIcon: const Icon(
              LucideIcons.mail,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            validator: (String? value) {
              if (value!.isEmpty || !value.isEmail) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: doctorSignupVM.passwordController,
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'Password',
            obscureText: true,
            prefixIcon: const Icon(
              LucideIcons.lock,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            validator: (String? value) {
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
          CustomDropdown<String>(
            items: _cities,
            hintText: 'City',
            value: _selectedCities,
            onChanged: (String? newValue) {
              setState(() {
                _selectedCities = newValue;
                doctorSignupVM.cityController.text = newValue ?? ''; // Update the controller if needed
              });
            },
            prefixIcon: const Icon(
              LucideIcons.briefcase,
              color: Colors.white,
            ),
            fillColor: Colors.white.withOpacity(0.2),
          ),
          SizedBox(height: height * .02),
          CustomDropdown<String>(
            items: _specializations,
            hintText: 'Select specialization',
            value: _selectedSpecialization,
            onChanged: (String? newValue) {
              setState(() {
                _selectedSpecialization = newValue;
                doctorSignupVM.specializationController.text = newValue ?? ''; // Update the controller if needed
              });
            },
            prefixIcon: const Icon(
              LucideIcons.briefcase,
              color: Colors.white,
            ),
            fillColor: Colors.white.withOpacity(0.2),
          ),
          SizedBox(height: height * .02),
          Row(
            children: [
              Text(
                'Gender',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Obx(() => Row(
                children: [
                  Radio<String>(
                    value: 'male',
                    groupValue: doctorSignupVM.gender.value,
                    onChanged: (value) => doctorSignupVM.gender.value = value!,
                    fillColor: MaterialStateProperty.all(Colors.white),
                  ),
                  Text(
                    'Male',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Radio<String>(
                    value: 'female',
                    groupValue: doctorSignupVM.gender.value,
                    onChanged: (value) => doctorSignupVM.gender.value = value!,
                    fillColor: MaterialStateProperty.all(Colors.white),
                  ),
                  Text(
                    'Female',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              )),
            ],
          ),
          SizedBox(height: height * .03),
          Center(
            child: Obx(() => RoundButton(
              title: 'SIGN UP',
              width: double.infinity,
              buttonColor: AppColors.darkGreen,
              textColor: Colors.white,
              onPress: () {
                if (_formkey.currentState!.validate() && _selectedSpecialization != null) {
                  doctorSignupVM.loading.value = true;
                  // Implement your doctor signup logic here using doctorSignupVM
                  print('Title: ${doctorSignupVM.titleController.value.text}');
                  print('Name: ${doctorSignupVM.nameController.value.text}');
                  print('Phone: ${doctorSignupVM.phoneController.value.text}');
                  print('Email: ${doctorSignupVM.emailController.value.text}');
                  print('Password: ${doctorSignupVM.passwordController.value.text}');
                  print('City: ${doctorSignupVM.cityController.value.text}');
                  print('Specialization: $_selectedSpecialization');
                  print('Gender: ${doctorSignupVM.gender.value}');
                  doctorSignupVM.signUpDoctor(); // Example function
                } else if (_selectedSpecialization == null) {
                  Get.snackbar(
                    'Error',
                    'Please select your specialization',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                  );
                }
              },
              loading: doctorSignupVM.loading.value,
            )),
          ),
          SizedBox(height: height * .03),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have a Doctor Account? ",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(RouteName.loginPage),
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Assuming you have a reusable CustomDropdown widget like this:
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
        color: fillColor ?? Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            if (prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: prefixIcon!,
              ),
            Expanded(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                hint: Text(
                  hintText,
                  style: TextStyle(color: Colors.white70),
                ),
                dropdownColor: fillColor ?? Colors.white.withOpacity(0.3),
                style: TextStyle(color: Colors.white),
                underline: Container(),
                items: items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString(), style: TextStyle(color: Colors.white)),
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