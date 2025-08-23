import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sehatyab/res/colors/app_colors.dart';
import '../../../constants/menu_widget.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class Appointment {
  final String id;
  final String patientName;
  final String status;
  final DateTime dateTime;
  final String time;
  final String? notes;
  final String date;

  Appointment({
    required this.id,
    required this.patientName,
    required this.status,
    required this.dateTime,
    required this.time,
    this.notes,
    required this.date,
  });

  // Factory method to create from static data
  factory Appointment.fromStatic(Map<String, dynamic> data) {
    return Appointment(
      id: data['id'],
      patientName: data['patientName'],
      status: data['status'],
      dateTime: data['dateTime'],
      time: data['time'],
      notes: data['notes'],
      date: data['date'],
    );
  }
}

class _DoctorHomePageState extends State<DoctorHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _appointments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStaticAppointments();
  }

  void _loadStaticAppointments() {
    // Static appointment data
    final now = DateTime.now();
    final staticAppointments = [
      {
        'id': '1',
        'patientName': 'Ali Khan',
        'status': 'confirmed',
        'dateTime': now.add(const Duration(days: 1)),
        'time': '10:00 AM',
        'notes': 'Follow-up for diabetes management',
        'date': DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1))),
      },
      {
        'id': '2',
        'patientName': 'Sara Ahmed',
        'status': 'pending',
        'dateTime': now.add(const Duration(days: 2)),
        'time': '02:30 PM',
        'notes': 'Annual checkup',
        'date': DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 2))),
      },
      {
        'id': '3',
        'patientName': 'Usman Malik',
        'status': 'completed',
        'dateTime': now.subtract(const Duration(days: 1)),
        'time': '11:00 AM',
        'notes': 'Blood pressure follow-up',
        'date': DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1))),
      },
      {
        'id': '4',
        'patientName': 'Fatima Riaz',
        'status': 'cancelled',
        'dateTime': now.subtract(const Duration(days: 3)),
        'time': '09:30 AM',
        'notes': 'Patient cancelled due to travel',
        'date': DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3))),
      },
      {
        'id': '5',
        'patientName': 'Ahmed Hassan',
        'status': 'confirmed',
        'dateTime': now.add(const Duration(days: 3)),
        'time': '04:00 PM',
        'notes': 'New patient consultation',
        'date': DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 3))),
      },
    ];

    setState(() {
      _appointments = staticAppointments
          .map((appt) => Appointment.fromStatic(appt))
          .toList();
    });
  }

  List<Appointment> get _upcomingAppointments => _appointments
      .where((a) => a.status == 'pending' || a.status == 'confirmed')
      .toList();

  List<Appointment> get _completedAppointments => _appointments
      .where((a) => a.status == 'completed')
      .toList();

  List<Appointment> get _cancelledAppointments => _appointments
      .where((a) => a.status == 'cancelled')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('My Appointments (${_appointments.length})',
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
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
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
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_upcomingAppointments.length} Upcoming',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.secondaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs:  [
                    Tab(text: 'Upcoming (${_upcomingAppointments.length})'),
                    Tab(text: 'Completed (${_completedAppointments.length})'),
                    Tab(text: 'Cancelled (${_cancelledAppointments.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentList(_upcomingAppointments),
                      _buildAppointmentList(_completedAppointments),
                      _buildAppointmentList(_cancelledAppointments),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          'No appointments found',
          style: GoogleFonts.poppins(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: appointments.length,
      itemBuilder: (context, index) => _buildAppointmentCard(appointments[index]),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondaryColor,
                  child: Text(
                    appointment.patientName[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Status: ${appointment.status}',
                      style: TextStyle(
                        color: _getStatusColor(appointment.status),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(appointment.dateTime),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(appointment.time),
              ],
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Notes:'),
              Text(
                appointment.notes!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            if (appointment.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _updateAppointment(appointment, 'cancelled'),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryColor,
                    ),
                    onPressed: () => _updateAppointment(appointment, 'confirmed'),
                    child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updateAppointment(Appointment appointment, String newStatus) {
    // Since we're using static data, we'll just update the local state
    setState(() {
      _appointments = _appointments.map((a) {
        if (a.id == appointment.id) {
          return Appointment(
            id: a.id,
            patientName: a.patientName,
            status: newStatus,
            dateTime: a.dateTime,
            time: a.time,
            notes: a.notes,
            date: a.date,
          );
        }
        return a;
      }).toList();
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Appointment ${newStatus.toLowerCase()}')),
    // );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}