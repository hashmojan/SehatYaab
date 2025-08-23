import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/input_field.dart';
import '../../../res/components/round_button.dart';
import '../../../res/routes/routes_name.dart';
import '../../../view_model/controller/authentication_controller/login_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formkey = GlobalKey<FormState>();
  late AnimationController _animationController;
  String _userType = 'patient';
  bool _rememberMe = false;
  bool _obscurePassword = true;
  final LoginVM = Get.put(LoginViewModel());

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
              padding: const EdgeInsets.all(20.0),
              child: isWeb
                  ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: _buildLoginCard(context))
                  : _buildLoginCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formkey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOutBack,
                ),
                child: Column(
                  children: [
                    Icon(Icons.medical_services, size: 50, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Sign in to continue',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // User Type Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUserTypeChip('patient', 'Patient', Icons.person),
                    const SizedBox(width: 16),
                    _buildUserTypeChip('doctor', 'Doctor', Icons.medical_services),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email Field
              InputField(
                controller: LoginVM.emailController.value,
                fillColor: Colors.white.withOpacity(0.15),
                errorcolor: Colors.red[400]!,
                hintText: 'Email Address',
                prefixIcon: const Icon(LucideIcons.mail, color: Colors.white),
                prefixIconWidth: 60.0,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Email is required' :
                !value.isEmail ? 'Invalid email format' : null,
              ),
              const SizedBox(height: 16),

              // Password Field
              InputField(
                controller: LoginVM.passwordController.value,
                fillColor: Colors.white.withOpacity(0.15),
                errorcolor: Colors.red[400]!,
                hintText: 'Password',
                prefixIcon: const Icon(LucideIcons.lock, color: Colors.white),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                prefixIconWidth: 60.0,
                obscureText: _obscurePassword,
                validator: (value) => value!.isEmpty ? 'Password is required' :
                value.length < 6 ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 8),

              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value!),
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                                (states) => _rememberMe ? AppColors.darkGreen : Colors.white.withOpacity(0.5)),
                      ),
                      Text(
                        'Remember me',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(RouteName.forgotPasswordPage),
                    child: Text(
                      'Forgot Pass',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Login Button
              Obx(() => RoundButton(
                buttonColor: AppColors.darkGreen,
                onPress: () async {
                  if (_formkey.currentState!.validate()) {
                    LoginVM.loading.value = true;
                    try {
                      bool success = await LoginVM.login(userType: _userType);

                      if (success) {
                        final route = _userType == 'doctor'
                            ? RouteName.doctorHomePage
                            : RouteName.patientHomePage;
                        Get.offAllNamed(route);
                      } else {
                        _showErrorSnackbar('Email or password is incorrect');
                      }
                    } catch (e) {
                      _showErrorSnackbar('Login failed. Please try again');
                    } finally {
                      LoginVM.loading.value = false;
                    }
                  }
                },
                title: _userType == 'doctor' ? "Login as Doctor" : "Login as Patient",
                loading: LoginVM.loading.value,
                textColor: Colors.white,
                width: double.infinity,
                height: 50,
              )),
              const SizedBox(height: 24),

              // Sign Up Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an Account? ",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Get.toNamed(RouteName.signupSelection);
                    },
                    child: Text(
                      'Sign Up',
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
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildUserTypeChip(String value, String label, IconData icon) {
    final isSelected = _userType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _userType = value;
          LoginVM.emailController.value.clear();
          LoginVM.passwordController.value.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}