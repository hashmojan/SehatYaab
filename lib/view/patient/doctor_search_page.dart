// // views/patient/doctor_search_page.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:sehatyab/res/colors/app_colors.dart';
//
// // import 'package:sehatyab/components/doctor_card.dart';
// // import 'package:sehatyab/components/custom_dropdown.dart';
// // import 'package:sehatyab/components/loading_shimmer.dart';
// // import 'package:sehatyab/controllers/doctor_search_controller.dart';
// // import 'package:sehatyab/models/doctor_model.dart';
// // import 'package:sehatyab/res/colors/app_colors.dart';
// // import 'package:sehatyab/utils/device_size.dart';
//
//
// class DoctorSearchPage extends StatelessWidget {
//   final DoctorSearchController _controller = Get.put(DoctorSearchController());
//   final _searchController = TextEditingController();
//
//   DoctorSearchPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Find Doctors'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.filter_list),
//             onPressed: _showAdvancedFilterSheet,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildSearchBar(),
//           _buildQuickFilters(),
//           _buildDateSelector(),
//           _buildResultsHeader(),
//           Expanded(child: _buildDoctorList()),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Search doctors by name or specialty...',
//           prefixIcon: const Icon(Icons.search),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30),
//           ),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 20),
//           suffixIcon: IconButton(
//             icon: const Icon(Icons.clear),
//             onPressed: () {
//               _searchController.clear();
//               _controller.searchQuery.value = '';
//             },
//           ),
//         ),
//         onChanged: (value) => _controller.searchQuery.value = value,
//       ),
//     );
//   }
//
//   Widget _buildQuickFilters() {
//     return SizedBox(
//       height: 50,
//       child: Obx(() => ListView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         children: [
//           _buildFilterChip('Cardiologist', 'specialization'),
//           _buildFilterChip('Dermatologist', 'specialization'),
//           _buildFilterChip('Pediatrician', 'specialization'),
//           _buildFilterChip('Islamabad', 'location'),
//           _buildFilterChip('Lahore', 'location'),
//           _buildFilterChip('Available Today', 'availability'),
//         ],
//       )),
//     );
//   }
//
//   Widget _buildFilterChip(String label, String type) {
//     return Obx(() => FilterChip(
//       label: Text(label),
//       selected: _controller.activeFilters[type]?.contains(label) ?? false,
//       onSelected: (selected) => _controller.toggleFilter(type, label, selected),
//       backgroundColor: AppColors.primaryColor,
//       selectedColor: AppColors.primaryColor.withOpacity(0.2),
//       labelStyle: TextStyle(
//         color: _controller.activeFilters[type]?.contains(label) ?? false
//             ? AppColors.primaryColor
//             : Colors.black,
//       ),
//       side: BorderSide.none,
//       shape: StadiumBorder(
//         side: BorderSide(
//           color: _controller.activeFilters[type]?.contains(label) ?? false
//               ? AppColors.primaryColor
//               : AppColors.primaryColor,
//         ),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     ));
//   }
//
//   Widget _buildDateSelector() {
//     return Obx(() => ListTile(
//         leading: const Icon(Icons.calendar_today),
//         title: Text(
//           _controller.selectedDate.value == null
//               ? 'Select Date'
//               : DateFormat('EEE, MMM d, y').format(_controller.selectedDate.value!),
//           trailing: IconButton(
//             icon: const Icon(Icons.arrow_drop_down),
//             onPressed: _selectDate,
//           ),
//           ontap : _selectDate,
//         )));
//     }
//
//   Widget _buildResultsHeader() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Obx(() => Text(
//             '${_controller.filteredDoctors.length} Doctors Found',
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           )),
//           _buildSortDropdown(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSortDropdown() {
//     return Obx(() => DropdownButtonHideUnderline(
//       child: DropdownButton<String>(
//         value: _controller.sortBy.value,
//         items: const [
//           DropdownMenuItem(value: 'rating', child: Text('Top Rated')),
//           DropdownMenuItem(value: 'experience', child: Text('Experience')),
//           DropdownMenuItem(value: 'distance', child: Text('Nearest')),
//         ],
//         onChanged: (value) => _controller.sortBy.value = value!,
//         icon: const Icon(Icons.sort),
//         style: TextStyle(
//           color: AppColors.primaryColor,
//           fontSize: 14,
//         ),
//       ),
//     ));
//   }
//
//   Widget _buildDoctorList() {
//     return Obx(() {
//       if (_controller.isLoading.value) {
//         return const LoadingShimmer(itemCount: 5);
//       }
//
//       if (_controller.filteredDoctors.isEmpty) {
//         return _buildEmptyState();
//       }
//
//       return ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: _controller.filteredDoctors.length,
//         itemBuilder: (context, index) {
//           final doctor = _controller.filteredDoctors[index];
//           return Doctor(
//             doctor: doctor,
//             availableSlots: _controller.getAvailableSlots(doctor),
//             onBook: () => _controller.navigateToBooking(doctor),
//           );
//         },
//       );
//     });
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.search_off, size: 80, color: AppColors.primaryColor),
//           const SizedBox(height: 20),
//           const Text('No doctors found matching your criteria'),
//           const SizedBox(height: 10),
//           TextButton(
//             onPressed: _controller.clearFilters,
//             child: const Text('Clear Filters'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: Get.context!,
//       initialDate: _controller.selectedDate.value ?? DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 60)),
//     );
//     if (picked != null) {
//       _controller.selectedDate.value = picked;
//     }
//   }
//
//   void _showAdvancedFilterSheet() {
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: ListView(
//           shrinkWrap: true,
//           children: [
//             const Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             _buildFilterSection('Specialization', _controller.specializations),
//             _buildFilterSection('Cities', _controller.locations),
//             _buildRatingFilter(),
//             _buildExperienceFilter(),
//             _buildActionButtons(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFilterSection(String title, List<String> options) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 20),
//         Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         Wrap(
//           spacing: 8,
//           children: options.map((option) => _buildFilterChip(option, title.toLowerCase())).toList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildRatingFilter() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 20),
//         const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
//         Obx(() => Row(
//           children: List.generate(5, (index) => IconButton(
//             icon: Icon(
//               Icons.star,
//               color: index < _controller.minRating.value
//                   ? AppColors.primaryColor
//                   : AppColors.primaryColor,
//               size: 30,
//             ),
//             onPressed: () => _controller.minRating.value = index + 1,
//           )),
//         )),
//       ],
//     );
//   }
//
//   Widget _buildExperienceFilter() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 20),
//         const Text('Years of Experience', style: TextStyle(fontWeight: FontWeight.bold)),
//         Obx(() => RangeSlider(
//           values: _controller.experienceRange.value,
//           min: 0,
//           max: 30,
//           divisions: 30,
//           labels: RangeLabels(
//             '${_controller.experienceRange.value.start.round()} yrs',
//             '${_controller.experienceRange.value.end.round()} yrs',
//           ),
//           onChanged: (values) => _controller.experienceRange.value = values,
//         )),
//       ],
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         Expanded(
//           child: TextButton(
//             onPressed: Get.back,
//             child: const Text('Cancel'),
//           ),
//         ),
//         Expanded(
//           child: ElevatedButton(
//             onPressed: () {
//               _controller.applyAdvancedFilters();
//               Get.back();
//             },
//             child: const Text('Apply Filters'),
//           ),
//         ),
//       ],
//     );
//   }
// }