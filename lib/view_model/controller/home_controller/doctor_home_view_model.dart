import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Appointment {
  final String id;
  final String patientName;
  final String patientId;
  final String doctorName;
  final String specialty;
  final String time;
  final String date;
  final DateTime? dateTime; // Optional for flexibility
  final String status; // 'upcoming', 'completed', 'cancelled', etc.
  final String? notes;
  final String? prescription;
  final String imageUrl;
  final int rating;
  final int experience;
  final String location;
  final bool isEditable;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.doctorName,
    required this.specialty,
    required this.time,
    required this.date,
    this.dateTime,
    required this.status,
    this.notes,
    this.prescription,
    this.imageUrl = '',
    this.rating = 0,
    this.experience = 0,
    this.location = '',
    this.isEditable = false,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientName: data['patientName'] ?? 'Unknown Patient',
      patientId: data['patientId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      specialty: data['specialty'] ?? '',
      time: data['time'] ?? '--:--',
      date: data['date'] ?? 'Unknown Date',
      dateTime: data['dateTime'] != null
          ? (data['dateTime'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'upcoming',
      notes: data['notes'],
      prescription: data['prescription'],
      imageUrl: data['imageUrl'] ?? '',
      rating: data['rating'] ?? 0,
      experience: data['experience'] ?? 0,
      location: data['location'] ?? '',
      isEditable: data['isEditable'] ?? false,
    );
  }

  String get formattedDate =>
      dateTime != null ? DateFormat('MMM dd, yyyy').format(dateTime!) : date;

  String get formattedTime =>
      dateTime != null ? DateFormat('HH:mm').format(dateTime!) : time;

  Appointment copyWith({
    String? status,
    String? notes,
    String? prescription,
  }) {
    return Appointment(
      id: id,
      patientName: patientName,
      patientId: patientId,
      doctorName: doctorName,
      specialty: specialty,
      time: time,
      date: date,
      dateTime: dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      prescription: prescription ?? this.prescription,
      imageUrl: imageUrl,
      rating: rating,
      experience: experience,
      location: location,
      isEditable: isEditable,
    );
  }
}


class DoctorHomeViewModel extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  final isLoading = true.obs;
  final allAppointments = <Appointment>[].obs;
  final upcomingAppointments = <Appointment>[].obs;
  final completedAppointments = <Appointment>[].obs;
  final cancelledAppointments = <Appointment>[].obs;
  final todayAppointments = <Appointment>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAppointments();
  }

  // Fetch appointments from Firestore
  Future<void> fetchAppointments() async {
    try {
      isLoading.value = true;
      final querySnapshot = await _firestore
          .collection('appointments')
          // .where('doctorId', isEqualTo: Get.find<AuthService>().currentUserId)
          .get();

      allAppointments.assignAll(
          querySnapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList()
      );

      _filterAppointments();
    } catch (e) {
      // Get.snackbar('Error', 'Failed to load appointments: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Filter appointments by status and today's date
  void _filterAppointments() {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    upcomingAppointments.assignAll(
        allAppointments.where((appt) => appt.status == 'upcoming').toList()
    );

    completedAppointments.assignAll(
        allAppointments.where((appt) => appt.status == 'completed').toList()
    );

    cancelledAppointments.assignAll(
        allAppointments.where((appt) => appt.status == 'cancelled').toList()
    );

    todayAppointments.assignAll(
        allAppointments.where((appt) => appt.date == today).toList()
    );
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      await fetchAppointments();
    } catch (e) {
      // Get.snackbar('Error', 'Failed to update appointment: ${e.toString()}');
    }
  }

  // Add prescription/notes to appointment
  Future<void> addAppointmentNotes(
      String appointmentId,
      String notes,
      String prescription
      ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'notes': notes,
        'prescription': prescription,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetchAppointments();
    } catch (e) {
      // Get.snackbar('Error', 'Failed to add notes: ${e.toString()}');
    }
  }

  // Refresh appointments list
  Future<void> refreshAppointments() async {
    await fetchAppointments();
  }

  // Get today's date in formatted string
  String get formattedToday {
    return DateFormat('EEEE, MMMM d').format(DateTime.now());
  }
}