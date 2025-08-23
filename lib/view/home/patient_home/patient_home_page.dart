import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sehatyab/constants/menu_widget.dart';

import '../../../../res/colors/app_colors.dart';
import '../../../../res/components/search_field.dart';
import '../../../../res/routes/routes_name.dart';
import '../../../res/components/cards/doctor_card.dart';


class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final List<String> categories = [
    'All', // Default option
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
    'Rheumatologist', // Arthritis, autoimmune diseases
  ];

  int selectedCategory = 0;
  String searchQuery = '';
  bool isLoading = true;
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('doctors').get();

      setState(() {
        doctors = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            'rating': data['rating'] ?? 0.0,
            'experience': data['experience'] ?? 0,
            'city': data['city'] ?? 'Unknown location',
          };
        }).toList();
        filteredDoctors = List.from(doctors);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Sca

    }
  }

  void filterDoctors() {
    List<Map<String, dynamic>> result = List.from(doctors);

    // Filter by category
    if (selectedCategory != 0) {
      final category = categories[selectedCategory];
      result = result
          .where((doctor) => doctor['specialization'] == category)
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      result = result
          .where((doctor) =>
      doctor['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          doctor['specialization'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          doctor['city'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          // Example: If searching for "heart" also matches "Cardiologist"
          doctor['specialization'].toLowerCase().contains(_getDiseaseKeyword(searchQuery.toLowerCase())))
          .toList();
    }

    setState(() {
      filteredDoctors = result;
    });
  }
  String _getDiseaseKeyword(String query) {
    // Convert query to lowercase for case-insensitive matching
    final lowerQuery = query.toLowerCase();

    // Map diseases to related specializations
    final diseaseToSpecialization = {
      // Heart & Cardiovascular
      'heart': 'cardiologist',
      'cardiac': 'cardiologist',
      'hypertension': 'cardiologist',
      'high blood pressure': 'cardiologist',
      'stroke': 'neurologist', // Also related to cardiology

      // Brain & Nervous System
      'brain': 'neurologist',
      'neurology': 'neurologist',
      'epilepsy': 'neurologist',
      'alzheimer': 'neurologist',
      'parkinson': 'neurologist',
      'migraine': 'neurologist',

      // Diabetes & Hormones
      'diabetes': 'endocrinologist',
      'thyroid': 'endocrinologist',
      'hormone': 'endocrinologist',

      // Lungs & Respiratory
      'asthma': 'pulmonologist',
      'copd': 'pulmonologist',
      'lung': 'pulmonologist',
      'pneumonia': 'pulmonologist',

      // Stomach & Digestive
      'stomach': 'gastroenterologist',
      'digestive': 'gastroenterologist',
      'ibs': 'gastroenterologist',
      'ulcer': 'gastroenterologist',
      'liver': 'gastroenterologist',

      // Bones & Joints
      'arthritis': 'rheumatologist',
      'joint pain': 'rheumatologist',
      'osteoporosis': 'orthopedic',

      // Kidneys
      'kidney': 'nephrologist',
      'dialysis': 'nephrologist',

      // Cancer
      'cancer': 'oncologist',
      'tumor': 'oncologist',
      'chemotherapy': 'oncologist',

      // Skin
      'skin': 'dermatologist',
      'acne': 'dermatologist',
      'eczema': 'dermatologist',
      'psoriasis': 'dermatologist',

      // Mental Health
      'depression': 'psychiatrist',
      'anxiety': 'psychiatrist',
      'adhd': 'psychiatrist',
      'bipolar': 'psychiatrist',
    };

    // Return the matching specialization, or the original query if no match
    return diseaseToSpecialization[lowerQuery] ?? query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Find Doctors',
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
            onPressed: () =>
                Navigator.pushNamed(context, RouteName.notifications),
          ),
        ],
      ),
      drawer: MenuWidget(),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchField(
              hintText: 'Search doctors...',
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  filterDoctors();
                });
              },
            ),
          ),

          // Categories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(categories[index]),
                    selected: selectedCategory == index,
                    selectedColor: AppColors.secondaryColor,
                    labelStyle: GoogleFonts.poppins(
                      color: selectedCategory == index
                          ? Colors.white
                          : Colors.black,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = index;
                        filterDoctors();
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Doctors List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDoctors.isEmpty
                ? Center(
              child: Text(
                'No doctors found',
                style: GoogleFonts.poppins(),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = filteredDoctors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailPage(doctor: doctor),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Doctor Image
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: doctor['imageUrl'] != null
                                ? NetworkImage(doctor['imageUrl']) as ImageProvider
                                : null,
                            child: doctor['imageUrl'] == null
                                ? const Icon(
                              LucideIcons.user,
                              color: Colors.grey,
                              size: 30,
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Doctor Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name and Specialization
                                Text(
                                  doctor['name'] ?? 'No name',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  doctor['specialization'] ?? 'No specialty',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Rating and Experience
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${doctor['rating']?.toStringAsFixed(1) ?? '0.0'}',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.work, color: Colors.blue, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${doctor['experience']?.toString() ?? '0'} yrs',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Location
                                Row(
                                  children: [
                                    Icon(Icons.location_on, color: Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      doctor['city'] ?? 'Unknown location',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Forward arrow
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}