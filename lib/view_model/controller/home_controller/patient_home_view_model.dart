import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/doctor/doctor_model/doctor_model.dart';

class PatientHomeViewModel extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  final isLoading = true.obs;
  final allDoctors = <Doctor>[].obs;
  final filteredDoctors = <Doctor>[].obs;
  final searchQuery = ''.obs;
  final selectedCategory = 0.obs;

  final categories = <String>[
    'All',
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Pediatrician',
    'Orthopedist',
    'Dentist',
    'Gynecologist',
  ].obs;


  @override
  void onInit() {
    super.onInit();
    fetchDoctors();
  }

  // Fetch doctors from Firestore
  Future<void> fetchDoctors() async {
    try {
      isLoading.value = true;
      final querySnapshot = await _firestore.collection('doctors').get();

      allDoctors.assignAll(
          querySnapshot.docs.map((doc) => Doctor.fromFirestore(doc)).toList()
      );

      filteredDoctors.assignAll(allDoctors);
    } catch (e) {
      // Get.snackbar('Error', 'Failed to load doctors: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Search doctors by name or specialty
  void searchDoctors(String query) {
    searchQuery.value = query.toLowerCase();
    _applyFilters();
  }

  // Filter doctors by category
  void filterByCategory(int index) {
    selectedCategory.value = index;
    _applyFilters();
  }

  // Apply both search and category filters
  void _applyFilters() {
    if (allDoctors.isEmpty) return;

    var result = allDoctors.where((doctor) {
      // Apply search filter
      final matchesSearch = searchQuery.value.isEmpty ||
          doctor.name.toLowerCase().contains(searchQuery.value) ||
          doctor.specialty.toLowerCase().contains(searchQuery.value);

      // Apply category filter
      final matchesCategory = selectedCategory.value == 0 ||
          doctor.categories.contains(categories[selectedCategory.value]);

      return matchesSearch && matchesCategory;
    }).toList();

    filteredDoctors.assignAll(result);
  }

  // Refresh doctors list
  Future<void> refreshDoctors() async {
    await fetchDoctors();
  }
}