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
  final _scrollController = ScrollController();
  String _userType = 'patient';
  bool _rememberMe = false;
  bool _obscurePassword = true;
  final LoginVM = Get.put(LoginViewModel());

  // Get device height
  double get height => MediaQuery.of(context).size.height;

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
                    child: _buildLoginForm(context),
                  )
                      : _buildLoginForm(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
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
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome Back!',
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
                  'Sign in to continue your health journey',
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

          // User Type Selector
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.5, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'I am a',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildUserTypeOption('patient', 'Patient', LucideIcons.user),
                      const SizedBox(width: 16),
                      _buildUserTypeOption('doctor', 'Doctor', LucideIcons.stethoscope),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * .04),

          // Login Form Section
          _buildSectionHeader('Login Details'),
          const SizedBox(height: 20),

          // Email Field
          _buildAnimatedInputField(
            index: 0,
            controller: LoginVM.emailController.value,
            hintText: 'Email Address',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value!.isEmpty ? 'Email is required' :
            !value.isEmail ? 'Invalid email format' : null,
          ),
          const SizedBox(height: 16),

          // Password Field
          _buildAnimatedInputField(
            index: 1,
            controller: LoginVM.passwordController.value,
            hintText: 'Password',
            icon: LucideIcons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) => value!.isEmpty ? 'Password is required' :
            value.length < 6 ? 'Minimum 6 characters' : null,
          ),

          const SizedBox(height: 16),

          // Remember Me & Forgot Password
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
            )),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _rememberMe ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.lightPrimary,
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(RouteName.forgotPasswordPage),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * .04),

          // Login Button
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
            ),
            child: Obx(() => RoundButton(
              buttonColor: Colors.white,
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
              title: _userType == 'doctor' ? "LOGIN AS DOCTOR" : "LOGIN AS PATIENT",
              loading: LoginVM.loading.value,
              textColor: AppColors.primaryColor,
              width: double.infinity,
              height: 50,
            )),
          ),

          const SizedBox(height: 24),

          // Sign Up Prompt
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
                    "Don't have an Account? ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Get.toNamed(RouteName.signupSelection);
                    },
                    child: Text(
                      'Sign Up Here',
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
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3 + (index * 0.1), 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.3 + (index * 0.1), 1.0),
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
            suffixIcon: suffixIcon,
            prefixIconWidth: 60.0,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(String value, String label, IconData icon) {
    final isSelected = _userType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _userType = value;
            LoginVM.emailController.value.clear();
            LoginVM.passwordController.value.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Login Failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(LucideIcons.alertCircle, color: Colors.white),
    );
  }
}