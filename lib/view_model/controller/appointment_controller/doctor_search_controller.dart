// // controllers/doctor_search_controller.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:sehatyab/models/doctor_model.dart';
// import 'package:sehatyab/res/routes/routes_name.dart';
//
// import '../../../models/doctor/doctor_model/doctor_model.dart';
//
// class DoctorSearchController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Filter states
//   var searchQuery = ''.obs;
//   var selectedDate = Rx<DateTime?>(null);
//   var sortBy = 'rating'.obs;
//   var minRating = 0.obs;
//   var experienceRange = const RangeValues(0, 30).obs;
//   var activeFilters = <String, List<String>>{}.obs;
//
//   // Data
//   var allDoctors = <Doctor>[].obs;
//   var filteredDoctors = <Doctor>[].obs;
//   var isLoading = true.obs;
//
//   // Filter options
//   var specializations = <String>[].obs;
//   var locations = <String>[].obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _fetchInitialData();
//     everAll([searchQuery, selectedDate, sortBy, minRating, experienceRange], (_) => _filterDoctors());
//   }
//
//   Future<void> _fetchInitialData() async {
//     try {
//       // Fetch all doctors
//       final snapshot = await _firestore.collection('doctors').get();
//       allDoctors.assignAll(snapshot.docs.map((doc) => Doctor.fromFirestore(doc)));
//
//       // Extract filter options
//       specializations.assignAll(_extractUniqueSpecializations());
//       locations.assignAll(_extractUniqueLocations());
//
//       isLoading.value = false;
//       _filterDoctors();
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to load doctors');
//     }
//   }
//
//   void toggleFilter(String type, String value, bool selected) {
//     if (selected) {
//       activeFilters.update(type, (list) => [...list, value], ifAbsent: () => [value]);
//     } else {
//       activeFilters.update(type, (list) => list..remove(value), ifAbsent: () => []);
//     }
//   }
//
//   void _filterDoctors() {
//     filteredDoctors.assignAll(allDoctors.where((doctor) {
//       // Search query filter
//       final matchesSearch = doctor.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
//           doctor.specialization.toLowerCase().contains(searchQuery.toLowerCase());
//
//       // Active filters
//       final matchesSpecialization = activeFilters['specialization']?.isEmpty ?? true
//           ? true
//           : activeFilters['specialization']!.contains(doctor.specialization);
//
//       final matchesLocation = activeFilters['location']?.isEmpty ?? true
//           ? true
//           : activeFilters['location']!.contains(doctor.city);
//
//       // Rating filter
//       final matchesRating = doctor.rating >= minRating.value;
//
//       // Experience filter
//       final matchesExperience = doctor.experience >= experienceRange.value.start &&
//           doctor.experience <= experienceRange.value.end;
//
//       return matchesSearch && matchesSpecialization && matchesLocation &&
//           matchesRating && matchesExperience;
//     }));
//
//     _sortDoctors();
//   }
//
//   void _sortDoctors() {
//     switch (sortBy.value) {
//       case 'rating':
//         filteredDoctors.sort((a, b) => b.rating.compareTo(a.rating));
//         break;
//       case 'experience':
//         filteredDoctors.sort((a, b) => b.experience.compareTo(a.experience));
//         break;
//       case 'distance':
//       // Implement distance sorting logic
//         break;
//     }
//   }
//
//   void clearFilters() {
//     searchQuery.value = '';
//     selectedDate.value = null;
//     minRating.value = 0;
//     experienceRange.value = const RangeValues(0, 30);
//     activeFilters.clear();
//   }
//
//   List<String> _extractUniqueSpecializations() {
//     return [];
//     // return allDoctors.map((d) => d.specialization).toSet().toList();
//   }
//
//   List<String> _extractUniqueLocations() {
//     return allDoctors.map((d) => d.city).toSet().toList();
//   }
//
//   List<String> getAvailableSlots(Doctor doctor) {
//     // Implement availability checking logic
//     return [];
//   }
//
//   void navigateToBooking(Doctor doctor) {
//     Get.toNamed(RouteName.appointmentBookingPage, arguments: doctor);
//   }
//
//   void applyAdvancedFilters() {
//     _filterDoctors();
//   }
// }