import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DoctorScheduleSettingsController extends GetxController {
  final RxString doctorId = ''.obs;
  final RxList<String> timeSlots = <String>[].obs; // e.g., "09:00 AM - 10:00 AM"
  final RxString timezone = 'UTC'.obs;
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      FirebaseFirestore.instance.collection('doctor_settings').doc(doctorId.value);

  @override
  void onInit() {
    super.onInit();
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      doctorId.value = u.uid;
      _load();
    } else {
      loading.value = false;
    }
  }

  Future<void> _load() async {
    loading.value = true;
    try {
      final snap = await _settingsRef.get();
      final data = snap.data();
      if (data != null) {
        final slots = (data['timeSlots'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        timeSlots.assignAll(slots);
        timezone.value = (data['timezone'] ?? 'UTC') as String;
      } else {
        // sensible defaults
        timeSlots.assignAll([
          '09:00 AM - 10:00 AM',
          '10:00 AM - 11:00 AM',
          '11:00 AM - 12:00 PM',
          '02:00 PM - 03:00 PM',
          '03:00 PM - 04:00 PM',
          '04:00 PM - 05:00 PM',
        ]);
        timezone.value = 'UTC';
      }
    } catch (_) {}
    loading.value = false;
  }

  Future<void> save() async {
    if (doctorId.value.isEmpty) return;
    saving.value = true;
    try {
      await _settingsRef.set({
        'doctorId': doctorId.value,
        'timeSlots': timeSlots,
        'timezone': timezone.value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Get.snackbar('Saved', 'Schedule settings updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save settings: $e');
    } finally {
      saving.value = false;
    }
  }

  void addSlot(String slot) {
    if (!timeSlots.contains(slot)) {
      timeSlots.add(slot);
    }
  }

  void removeSlot(String slot) {
    timeSlots.remove(slot);
  }
}
