import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/menu_widget.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/cards/appointment_card.dart';
import '../../../view_model/controller/home_controller/doctor_home_view_model.dart';
import '../../../models/doctor/appointment/appointment_model.dart';
import '../../doctor/appointment/availability_manager.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> with SingleTickerProviderStateMixin {
  late final DoctorHomeViewModel controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Use Get.put if not registered, or Get.find if it is.
    controller = Get.isRegistered<DoctorHomeViewModel>()
        ? Get.find<DoctorHomeViewModel>()
        : Get.put(DoctorHomeViewModel());

    // Call refreshData() here to ensure the latest doctor's data is loaded
    // even if the ViewModel instance was reused from a previous login.
    controller.refreshData();

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // IMPORTANT: If you want the ViewModel to be completely destroyed when
    // the user navigates away (e.g., they log out), uncomment the line below.
    // If you always want to reuse the same instance, keep it commented.
    // Get.delete<DoctorHomeViewModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('My Appointments',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available, color: Colors.white),
            onPressed: () => Get.to(() => AvailabilityManagerPage()),
            tooltip: 'Manage Availability',
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => Get.toNamed('/notifications'),
          ),
        ],
      ),
      drawer: const MenuWidget(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(controller.formattedToday,
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500)),
                Text('${controller.upcomingAppointments.length} Upcoming',
                    style: GoogleFonts.poppins(fontSize: 16, color: AppColors.secondaryColor)),
              ]),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.secondaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Obx(() => Tab(text: 'Pending (${controller.pendingAppointments.length})')),
                Obx(() => Tab(text: 'Upcoming (${controller.upcomingAppointments.length})')),
                Obx(() => Tab(text: 'History (${controller.historyAppointments.length})')),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPending(controller.pendingAppointments),
                  _buildList(controller.upcomingAppointments),
                  _buildList(controller.historyAppointments),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildList(List<Appointment> items) {
    if (items.isEmpty) {
      return Center(child: Text('No appointments found.', style: GoogleFonts.poppins()));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: items.length,
      itemBuilder: (_, i) => AppointmentCard(
        appointment: items[i].toMap(),
        isDoctorView: true,
      ),
    );
  }

  Widget _buildPending(List<Appointment> items) {
    if (items.isEmpty) {
      return Center(child: Text('No new appointment requests.', style: GoogleFonts.poppins()));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i];
        return AppointmentCard(
          appointment: a.toMap(),
          isDoctorView: true,
          actions: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => controller.confirmAppointment(a),
                tooltip: 'Accept',
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => controller.rejectAppointment(a),
                tooltip: 'Reject',
              ),
            ],
          ),
        );
      },
    );
  }
}