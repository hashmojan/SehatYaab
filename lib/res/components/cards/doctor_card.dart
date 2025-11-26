import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sehatyab/res/colors/app_colors.dart';

import '../../../models/doctor/doctor_model/doctor_model.dart';
import '../../../services/chat/chat_services.dart';
import '../../../view/patient/appointment/appointment_booking_page.dart';

import '../../../models/chat/chat_conversation_model.dart';
import '../../../view/chat/doctor_chat_screen.dart';


class DoctorDetailPage extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailPage({super.key, required this.doctor});

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  final _auth = FirebaseAuth.instance;
  final _commentCtrl = TextEditingController();
  int _myRating = 0;
  bool _loadingMyReview = true;
  bool _submitting = false;

  late final String doctorId;
  late final DocumentReference<Map<String, dynamic>> doctorRef;
  late final CollectionReference<Map<String, dynamic>> reviewsRef;

  @override
  void initState() {
    super.initState();
    doctorId = (widget.doctor['id'] ??
        widget.doctor['doctorId'] ??
        widget.doctor['docId'] ??
        '')
        .toString();
    doctorRef =
        FirebaseFirestore.instance.collection('doctors').doc(doctorId);
    reviewsRef = doctorRef.collection('reviews');
    _prefillMyReview();
  }

  Future<void> _openChatWithDoctor(Map<String, dynamic> doctor) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to chat.')),
      );
      return;
    }

    final String patientId = user.uid;
    final String doctorDocId =
    (doctor['id'] ?? doctorId ?? '').toString().trim();

    if (doctorDocId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor information not available.')),
      );
      return;
    }

    try {
      // Fetch patient profile to get name + image
      final patientSnap = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get();
      final patientData = patientSnap.data() ?? {};

      final String patientName =
      (patientData['name'] ?? patientData['fullName'] ?? 'Patient')
          .toString();
      final String? patientImage = (patientData['imageUrl'] ??
          patientData['image']) as String?;

      // Doctor display info
      final String doctorName =
      (doctor['name'] ?? 'Unknown Doctor').toString();
      final String? doctorImage =
      (doctor['imageUrl'] ?? doctor['image']) as String?;

      final chatService = ChatService.instance;

      final ChatConversation conversation =
      await chatService.createOrGetConversation(
        doctorId: doctorDocId,
        patientId: patientId,
        doctorName: doctorName,
        patientName: patientName,
        doctorImage: doctorImage,
        patientImage: patientImage,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorChatScreen(
            conversation: conversation,
            currentUserId: patientId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }


  Future<void> _prefillMyReview() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || doctorId.isEmpty) {
      setState(() => _loadingMyReview = false);
      return;
    }
    final myDoc = await reviewsRef.doc(uid).get();
    if (myDoc.exists) {
      final data = myDoc.data()!;
      _myRating = ((data['rating'] ?? 0) as num).toInt();
      _commentCtrl.text = (data['comment'] ?? '') as String;
    }
    setState(() => _loadingMyReview = false);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.doctor;

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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: doctorRef.snapshots(),
        builder: (context, snap) {
          // fallbacks from the passed map
          final headerData = {
            ...base,
            if (snap.data?.data() != null) ...snap.data!.data()!,
          };

          final ratingAvg = (headerData['ratingAvg'] == null)
              ? ((headerData['rating'] ?? 0) as num).toDouble()
              : (headerData['ratingAvg'] as num).toDouble();
          final ratingCount = (headerData['ratingCount'] ?? 0) as int;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(headerData, ratingAvg, ratingCount),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('About Doctor'),
                      const SizedBox(height: 8),
                      _buildAboutSection(headerData),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Clinic Information'),
                      const SizedBox(height: 8),
                      _buildClinicInfo(headerData),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 8),
                      _buildContactInfo(headerData),
                      const SizedBox(height: 24),

                      // ---------------- REVIEWS SECTION ----------------
                      _buildSectionTitle('Reviews'),
                      const SizedBox(height: 8),
                      _ReviewsHeader(avg: ratingAvg, count: ratingCount),
                      const SizedBox(height: 12),

                      _buildMyReviewBox(),
                      const SizedBox(height: 16),

                      _ReviewsList(reviewsRef: reviewsRef),
                      const SizedBox(height: 24),

                      _buildChatButton(context, headerData),
                      const SizedBox(height: 12),
                      _buildAppointmentButton(context, headerData),

                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  // ----------------- CHAT BUTTON -----------------

  Widget _buildChatButton(
      BuildContext context, Map<String, dynamic> doctor) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: AppColors.secondaryColor),
        ),
        icon: Icon(Icons.chat_bubble_outline, color: AppColors.secondaryColor),
        label: Text(
          'Chat with Doctor',
          style: GoogleFonts.poppins(
            color: AppColors.secondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () => _openChatWithDoctor(doctor),
      ),
    );
  }

  // ----------------- HEADER -----------------

  Widget _buildProfileHeader(Map<String, dynamic> doctor, double avg, int count) {
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
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (doctor['imageUrl'] ?? doctor['image']) != null
                ? NetworkImage(doctor['imageUrl'] ?? doctor['image'])
                : null,
            child: (doctor['imageUrl'] == null && doctor['image'] == null)
                ? const Icon(LucideIcons.user, color: Colors.grey, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            (doctor['name'] ?? 'No name') as String,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            (doctor['specialization'] ?? doctor['specialty'] ?? 'No specialty') as String,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rating (shows avg + count)
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
                      '${avg.toStringAsFixed(1)} ($count)',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
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
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
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

  // ----------------- SECTIONS -----------------

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> doctor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Text(
        (doctor['about'] ?? 'No information available about this doctor.') as String,
        style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildClinicInfo(Map<String, dynamic> doctor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (doctor['clinicName'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    doctor['clinicName'] as String,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (doctor['clinicAddress'] ?? doctor['city'] ?? 'Location not specified') as String,
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Map<String, dynamic> doctor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          if (doctor['phone'] != null) _buildContactItem(Icons.phone, doctor['phone'] as String),
          if (doctor['email'] != null) _buildContactItem(Icons.email, doctor['email'] as String),
          if (doctor['website'] != null) _buildContactItem(Icons.language, doctor['website'] as String),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  // ----------------- APPOINTMENT BUTTON -----------------

  Widget _buildAppointmentButton(BuildContext context, Map<String, dynamic> doctor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          final doctorData = Doctor(
            id: (doctor['id'] ?? doctorId) as String,
            image: (doctor['imageUrl'] ?? doctor['image'] ?? 'assets/default_doctor.png') as String,
            name: (doctor['name'] ?? 'Unknown Doctor') as String,
            specialty: (doctor['specialization'] ?? doctor['specialty'] ?? 'General Practitioner') as String,
            rating: ((doctor['rating'] ?? 0) as num).toDouble(),
            experience: (doctor['experience'] ?? 0) as int,
            city: (doctor['city'] ?? '') as String,
            fromMap: '',
            categories: const [],
            ratingAvg: doctor['ratingAvg'] == null ? 0.0 : (doctor['ratingAvg'] as num).toDouble(),
            ratingCount: doctor['ratingCount'] == null ? 0 : (doctor['ratingCount'] as num).toInt(),
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

  // ----------------- REVIEWS: ADD/UPDATE -----------------

  Widget _buildMyReviewBox() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a review', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Please sign in to add a review.', style: GoogleFonts.poppins(color: Colors.grey[700])),
          ],
        ),
      );
    }

    if (_loadingMyReview) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('Loading your review...',
                style: GoogleFonts.poppins(color: Colors.grey[700])),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((_myRating > 0) ? 'Update your review' : 'Add a review',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          _StarPicker(
            initial: _myRating,
            onChanged: (v) => setState(() => _myRating = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share a few words about your experience (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submitting ? null : _submitReview,
              child: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text((_myRating > 0 && _commentCtrl.text.isNotEmpty) ? 'Update' : 'Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_myRating < 1 || _myRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating (1–5).')),
      );
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);

    try {
      final db = FirebaseFirestore.instance;
      final reviewRef = reviewsRef.doc(uid);
      final patientDoc = await db.collection('patients').doc(uid).get();
      final patientName =
          (patientDoc.data()?['name'] as String?) ??
              (_auth.currentUser?.displayName ?? 'Patient');

      await db.runTransaction((tx) async {
        final doctorSnap = await tx.get(doctorRef);
        if (!doctorSnap.exists) {
          throw StateError('Doctor not found');
        }
        final currentAvg = (doctorSnap.data()?['ratingAvg'] ?? 0.0) as num;
        final currentCount = (doctorSnap.data()?['ratingCount'] ?? 0) as num;

        final now = Timestamp.now();
        final newData = <String, dynamic>{
          'doctorId': doctorId,
          'patientId': uid,
          'patientName': patientName,
          'rating': _myRating,
          'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          'updatedAt': now,
        };

        final existing = await tx.get(reviewRef);
        num nextAvg = currentAvg.toDouble();
        num nextCount = currentCount.toInt();

        if (existing.exists) {
          final oldRating = ((existing.data()?['rating']) ?? 0) as num;
          if (nextCount == 0) {
            nextAvg = _myRating.toDouble();
            nextCount = 1;
          } else {
            nextAvg = ((currentAvg * currentCount) - oldRating + _myRating) / nextCount;
          }
          tx.set(
            reviewRef,
            {
              ...newData,
              'createdAt': existing.data()!['createdAt'] ?? now,
            },
            SetOptions(merge: true),
          );
        } else {
          final newCount = currentCount.toInt() + 1;
          final sum = (currentAvg * currentCount) + _myRating;
          nextAvg = sum / newCount;
          nextCount = newCount;

          tx.set(reviewRef, {
            ...newData,
            'createdAt': now,
          });
        }

        final clampedAvg = double.parse(nextAvg.toStringAsFixed(2));
        tx.update(doctorRef, {
          'ratingAvg': clampedAvg,
          'ratingCount': nextCount,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted. Thank you!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit review: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }
}

// ----------------- REVIEWS HEADER -----------------

class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({required this.avg, required this.count});
  final double avg;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(avg.toStringAsFixed(1),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        _Stars(rating: avg),
        const SizedBox(width: 8),
        Text('($count reviews)', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

// ----------------- REVIEWS LIST -----------------

class _ReviewsList extends StatelessWidget {
  const _ReviewsList({required this.reviewsRef});
  final CollectionReference<Map<String, dynamic>> reviewsRef;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: reviewsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Text('No reviews yet.', style: GoogleFonts.poppins());
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snap.data!.docs.length,
          itemBuilder: (_, i) {
            final d = snap.data!.docs[i].data();
            final name = (d['patientName'] ?? 'Patient') as String;
            final rating = ((d['rating'] ?? 0) as num).toDouble();
            final comment = (d['comment'] ?? '') as String?;
            final ts = d['createdAt'] as Timestamp?;
            final created = ts?.toDate();

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  _Stars(rating: rating, size: 16),
                  if (created != null) ...[
                    const SizedBox(width: 8),
                    Text(_ago(created), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ],
              ),
              subtitle: (comment == null || comment.isEmpty)
                  ? null
                  : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(comment),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 16),
        );
      },
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ----------------- STAR WIDGETS -----------------

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 20});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (i < full) {
          icon = Icons.star;
        } else if (i == full && hasHalf) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: size, color: Colors.amber);
      }),
    );
  }
}

class _StarPicker extends StatefulWidget {
  const _StarPicker({required this.initial, required this.onChanged});
  final int initial;
  final ValueChanged<int> onChanged;

  @override
  State<_StarPicker> createState() => _StarPickerState();
}

class _StarPickerState extends State<_StarPicker> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        final on = idx <= _selected;
        return IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(on ? Icons.star : Icons.star_border, color: Colors.amber),
          onPressed: () {
            setState(() => _selected = idx);
            widget.onChanged(idx);
          },
        );
      }),
    );
  }
}
