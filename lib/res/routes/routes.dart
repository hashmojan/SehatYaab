import 'package:get/get.dart';
import 'package:sehatyab/res/routes/routes_name.dart';
import 'package:sehatyab/view/about_us/about_us_screen.dart';
import 'package:sehatyab/view/patient/health_records/health_records.dart';
import 'package:sehatyab/view/profile/profile.dart';
import 'package:sehatyab/view/setting/change_password/change_pass_page.dart';
import 'package:sehatyab/view/setting/contact_support/contact_support.dart';
import 'package:sehatyab/view/setting/help_center/help_center.dart';
import 'package:sehatyab/view/setting/legal/legal_pages.dart';
import 'package:sehatyab/view/setting/setting_page.dart';
import 'package:sehatyab/view/authentication/dr_signup/dr_signup.dart';
import 'package:sehatyab/view/authentication/forgot_password/forgot_password.dart';
import 'package:sehatyab/view/authentication/login/login_page.dart';
import 'package:sehatyab/view/authentication/otp_page/otp_page.dart';
import 'package:sehatyab/view/authentication/phone_auth/phone_auth.dart';
import 'package:sehatyab/view/authentication/signup_selection/signup_selectionpage.dart';
import 'package:sehatyab/view/chat_screen/chat_screen.dart';
import 'package:sehatyab/view/chat_screen/medical_assistant_service.dart';
import 'package:sehatyab/view/home/patient_home/patient_home_page.dart';
import 'package:sehatyab/view/splash/splash_screen.dart';
import 'package:sehatyab/view/start_page/start_screen.dart';

import '../../view/patient/appointment/appointment_details_page.dart';
import '../../view/authentication/patient_signup/patient_signup_page.dart';
import '../../view/doctor/schedule/doctor_schedule_page.dart';
import '../../view/home/dr_home/doctor_home_page.dart';
import '../../view/notification_page/notification_page.dart';

class AppRoutes {
  static final List<GetPage> routes = [
    GetPage(name: RouteName.splashScreen, page: () => const SplashScreen()),
    GetPage(name: RouteName.loginPage, page: () => const LoginPage()),
    GetPage(name: RouteName.phoneAuthenticationPage, page: () =>  PhoneAuthenticationPage()),


    GetPage(name: RouteName.forgotPasswordPage, page: () => const ForgotPasswordPage()),
    GetPage(name: RouteName.startPage, page: () => const StartPage()),
    GetPage(name: RouteName.profilePage, page: () => const ProfileScreen()),
    GetPage(name: RouteName.setting, page: () => const SettingsScreen()),
    GetPage(name: RouteName.changePasswordPage, page: () => const ChangePasswordPage()),
    GetPage(name: RouteName.helpCenter, page: () => const HelpCenterPage()),
    GetPage(name: RouteName.contactSupport, page: () => const ContactSupportPage()),
    GetPage(name: RouteName.aboutUs, page: () => const AboutUsScreen()),
    GetPage(name: RouteName.termsOfService, page: () => const TermsOfServicePage()),
    GetPage(name: RouteName.privacyPolicy, page: () => const PrivacyPolicyPage()),
    GetPage(name: RouteName.doctorSignup, page: () => const DoctorSignupPage()),
    GetPage(name: RouteName.patientSignup, page: () => const PatientSignupPage()),
    GetPage(name: RouteName.doctorHomePage, page: () => const DoctorHomePage()),
    GetPage(name: RouteName.signupSelection, page: () => const SignupSelectionPage()),
    GetPage(name: RouteName.patientHomePage, page: () => const PatientHomePage()),
    GetPage(name: RouteName.patientHealthRecordPage, page: () =>  PatientHealthRecordsPage()),

    GetPage(name: RouteName.otpPage, page: () =>  OTPPage()),


    // GetPage(name: RouteName.patientAppointments, page: () => const PatientAppointments()),
    GetPage(
      name: RouteName.chattingPage,
      page: () => const MedicalChatScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MedicalChatScreen());
      }),
    ),
    GetPage(
      name: RouteName.notifications,
      page: () => NotificationPage(), // Your notifications page widget
    ),
    GetPage(
      name: RouteName.appointmentDetails,
      page: () => AppointmentDetailsPage(),
    ),
    GetPage(
      name: RouteName.doctorSchedule,
      page: () => DoctorSchedulePage(),
      // Add binding if needed
      // binding: DoctorScheduleBinding(),
    ),

  ];
}