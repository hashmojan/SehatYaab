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
  final List<String> categories = const [
    'All',
    'Cardiologist',
    'Dermatologist',
    'Endocrinologist',
    'Gastroenterologist',
    'Neurologist',
    'Nephrologist',
    'Oncologist',
    'Orthopedic',
    'Pediatrician',
    'Psychiatrist',
    'Pulmonologist',
    'Rheumatologist',
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
          final ratingAvg =
          (data['ratingAvg'] == null) ? 0.0 : (data['ratingAvg'] as num).toDouble();
          final ratingCount =
          (data['ratingCount'] == null) ? 0 : (data['ratingCount'] as num).toInt();
          final legacyRating =
          (data['rating'] == null) ? 0.0 : (data['rating'] as num).toDouble();

          return {
            'id': doc.id,
            ...data,
            'imageUrl': data['imageUrl'] ?? data['image'],
            'specialization': data['specialization'] ?? data['specialty'],
            'ratingAvg': ratingAvg,
            'ratingCount': ratingCount,
            'rating': legacyRating,
            'yearsOfExperience': data['yearsOfExperience'] ?? 0,
            'city': data['city'] ?? 'Unknown location',
          };
        }).toList();
        // Keep whatever filters the user already has applied
        filteredDoctors = List.from(doctors);
        isLoading = false;
      });

      // Apply current filters after refresh to respect search/category
      filterDoctors();
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterDoctors() {
    List<Map<String, dynamic>> result = List.from(doctors);

    if (selectedCategory != 0) {
      final category = categories[selectedCategory].toLowerCase();
      result = result.where((doctor) {
        final spec =
        (doctor['specialization'] ?? doctor['specialty'] ?? '').toString().toLowerCase();
        return spec == category;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((doctor) {
        final name = (doctor['name'] ?? '').toString().toLowerCase();
        final spec =
        (doctor['specialization'] ?? doctor['specialty'] ?? '').toString().toLowerCase();
        final city = (doctor['city'] ?? '').toString().toLowerCase();
        final mappedKeyword = _getDiseaseKeyword(q);
        return name.contains(q) ||
            spec.contains(q) ||
            city.contains(q) ||
            spec.contains(mappedKeyword);
      }).toList();
    }

    setState(() {
      filteredDoctors = result;
    });
  }

  String _getDiseaseKeyword(String query) {
    final lowerQuery = query.toLowerCase();
    final diseaseToSpecialization = {
      'heart': 'cardiologist',
      'cardiac': 'cardiologist',
      'hypertension': 'cardiologist',
      'high blood pressure': 'cardiologist',
      'stroke': 'neurologist',
      'brain': 'neurologist',
      'neurology': 'neurologist',
      'epilepsy': 'neurologist',
      'alzheimer': 'neurologist',
      'parkinson': 'neurologist',
      'migraine': 'neurologist',
      'diabetes': 'endocrinologist',
      'thyroid': 'endocrinologist',
      'hormone': 'endocrinologist',
      'asthma': 'pulmonologist',
      'copd': 'pulmonologist',
      'lung': 'pulmonologist',
      'pneumonia': 'pulmonologist',
      'stomach': 'gastroenterologist',
      'digestive': 'gastroenterologist',
      'ibs': 'gastroenterologist',
      'ulcer': 'gastroenterologist',
      'liver': 'gastroenterologist',
      'arthritis': 'rheumatologist',
      'joint pain': 'rheumatologist',
      'osteoporosis': 'orthopedic',
      'kidney': 'nephrologist',
      'dialysis': 'nephrologist',
      'cancer': 'oncologist',
      'tumor': 'oncologist',
      'chemotherapy': 'oncologist',
      'skin': 'dermatologist',
      'acne': 'dermatologist',
      'eczema': 'dermatologist',
      'psoriasis': 'dermatologist',
      'depression': 'psychiatrist',
      'anxiety': 'psychiatrist',
      'adhd': 'psychiatrist',
      'bipolar': 'psychiatrist',
    };

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
            onPressed: () => Navigator.pushNamed(context, RouteName.notifications),
          ),
        ],
      ),
      drawer: const MenuWidget(),
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
                });
                filterDoctors();
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
                      color: selectedCategory == index ? Colors.white : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = index;
                      });
                      filterDoctors();
                    },
                  ),
                );
              },
            ),
          ),

          // Doctors List with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchDoctors,
              edgeOffset: 8,
              child: _buildScrollableBody(),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an always-scrollable body so pull-to-refresh works for all states.
  Widget _buildScrollableBody() {
    if (isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 200),
        ],
      );
    }

    if (filteredDoctors.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          Center(child: Text('No doctors found', style: GoogleFonts.poppins())),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredDoctors.length,
      itemBuilder: (context, index) {
        final doctor = filteredDoctors[index];
        final double avg =
        ((doctor['ratingAvg'] ?? doctor['rating'] ?? 0) as num).toDouble();
        final int count = (doctor['ratingCount'] ?? 0) as int;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        ? const Icon(LucideIcons.user, color: Colors.grey, size: 30)
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
                          (doctor['name'] ?? 'No name') as String,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          (doctor['specialization'] ?? 'No specialty') as String,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Rating (avg + count) and Experience
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${avg.toStringAsFixed(1)} ($count)',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.work, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${doctor['yearsOfExperience']?.toString() ?? '0'} yrs',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (doctor['city'] ?? 'Unknown location') as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
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
    );
  }
}
