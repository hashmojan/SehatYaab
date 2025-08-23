import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sehatyab/res/colors/app_colors.dart';

import '../../../models/doctor/doctor_model/doctor_model.dart';
import '../../../view/patient/appointment/appointment_booking_page.dart';

class DoctorDetailPage extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailPage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Doctor Profile',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Doctor Profile Header
            _buildProfileHeader(),

            // Doctor Information Sections
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Section
                  _buildSectionTitle('About Doctor'),
                  const SizedBox(height: 8),
                  _buildAboutSection(),
                  const SizedBox(height: 24),

                  // Clinic Information
                  _buildSectionTitle('Clinic Information'),
                  const SizedBox(height: 8),
                  _buildClinicInfo(),
                  const SizedBox(height: 24),

                  // Contact Information
                  _buildSectionTitle('Contact Information'),
                  const SizedBox(height: 8),
                  _buildContactInfo(),
                  const SizedBox(height: 24),

                  // Book Appointment Button
                  _buildAppointmentButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Doctor Image

          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: doctor['imageUrl'] != null
                ? NetworkImage(doctor['imageUrl']) as ImageProvider
                : null,
            child: doctor['imageUrl'] == null
                ? const Icon(
              LucideIcons.user,
              color: Colors.grey,
              size: 50,
            )
                : null,
          ),
          const SizedBox(height: 16),

          // Doctor Name
          Text(
            doctor['name'] ?? 'No name',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Specialization
          Text(
            doctor['specialization'] ?? 'No specialty',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Rating and Experience
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${doctor['rating']?.toStringAsFixed(1) ?? '0.0'}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Experience
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${doctor['experience'] ?? '0'} years',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        doctor['about'] ?? 'No information available about this doctor.',
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildClinicInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic Name
          if (doctor['clinicName'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    doctor['clinicName'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Clinic Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doctor['clinicAddress'] ??
                      doctor['city'] ??
                      'Location not specified',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (doctor['phone'] != null)
            _buildContactItem(Icons.phone, doctor['phone']),
          if (doctor['email'] != null)
            _buildContactItem(Icons.email, doctor['email']),
          if (doctor['website'] != null)
            _buildContactItem(Icons.language, doctor['website']),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondaryColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Create a Doctor object from the current doctor data
          final doctorData = Doctor(
            id: doctor['id'] ?? '',
            image: doctor['imageUrl'] ?? 'assets/default_doctor.png',
            name: doctor['name'] ?? 'Unknown Doctor',
            specialty: doctor['specialization'] ?? 'General Practitioner',
            rating: (doctor['rating'] ?? 0).toDouble(),
            experience: doctor['experience'] ?? 0,
            city: doctor['city'] ?? '',
            fromMap: '',
            categories: [],
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentBookingPage(doctor: doctorData),
            ),
          );
        },
        child: Text(
          'Book Appointment',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}