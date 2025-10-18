// view/doctor/doctor_home_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../constants/menu_widget.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/cards/appointment_card.dart';
import '../../../view_model/controller/home_controller/doctor_home_view_model.dart';
import '../../../models/doctor/appointment/appointment_model.dart';

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
    controller = Get.find<DoctorHomeViewModel>();
    _tabController = TabController(length: 3, vsync: this);

    // Add a listener to rebuild the tabs when the data changes
    controller.pendingAppointments.listen((_) {
      if (mounted) setState(() {});
    });
    controller.upcomingAppointments.listen((_) {
      if (mounted) setState(() {});
    });
    controller.historyAppointments.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => Get.toNamed('/notifications'),
          ),
        ],
      ),
      drawer: const MenuWidget(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.formattedToday,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Obx(() => Text(
                  '${controller.upcomingAppointments.length} Upcoming',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.secondaryColor,
                  ),
                )),
              ],
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return const Expanded(child: Center(child: CircularProgressIndicator()));
            }

            return Expanded(
              child: Column(
                children: [
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
                        _buildPendingAppointmentList(controller.pendingAppointments),
                        _buildAppointmentList(controller.upcomingAppointments),
                        _buildAppointmentList(controller.historyAppointments),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          'No appointments found.',
          style: GoogleFonts.poppins(),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppointmentCard(
          appointment: appointment.toMap(),
        );
      },
    );
  }

  Widget _buildPendingAppointmentList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          'No new appointment requests.',
          style: GoogleFonts.poppins(),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppointmentCard(
          appointment: appointment.toMap(),
          actions: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => controller.confirmAppointment(appointment.id),
                tooltip: 'Accept Appointment',
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => controller.rejectAppointment(appointment.id),
                tooltip: 'Reject Appointment',
              ),
            ],
          ),
        );
      },
    );
  }
}