import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/doctor/doctor_model/doctor_review.dart';
import '../../../view_model/controller/doctor_review/doctor_review_controller.dart';


class DoctorReviewsSection extends StatelessWidget {
  const DoctorReviewsSection({
    super.key,
    required this.doctorId,
  });

  final String doctorId;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DoctorReviewsController(doctorId: doctorId), permanent: false);

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(avg: c.ratingAvg.value, count: c.ratingCount.value),
          const SizedBox(height: 12),
          if (c.isPatient.value) _MyReviewBox(controller: c),
          const SizedBox(height: 12),
          _ReviewList(reviews: c.reviews),
        ],
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.avg, required this.count});

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

class _MyReviewBox extends StatefulWidget {
  const _MyReviewBox({required this.controller});
  final DoctorReviewsController controller;

  @override
  State<_MyReviewBox> createState() => _MyReviewBoxState();
}

class _MyReviewBoxState extends State<_MyReviewBox> {
  final _text = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    final myR = widget.controller.myRating.value;
    final myC = widget.controller.myComment.value;
    if (myR != null) _rating = myR;
    if (myC != null) _text.text = myC!;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = Theme.of(context);

    return Obx(() {
      final already = c.hasMyReview.value;
      return Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(already ? 'Update your review' : 'Add a review',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _StarPicker(
                initial: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _text,
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
                  onPressed: c.isSubmitting.value
                      ? null
                      : () async {
                    if (_rating < 1 || _rating > 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a rating (1–5).')),
                      );
                      return;
                    }
                    await c.submit(rating: _rating, comment: _text.text.trim().isEmpty ? null : _text.text.trim());
                  },
                  child: c.isSubmitting.value
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(already ? 'Update' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.reviews});
  final List<DoctorReview> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Text('No reviews yet.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, i) {
        final r = reviews[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Text(r.patientName.isEmpty ? 'Patient' : r.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _Stars(rating: r.rating.toDouble(), size: 16),
              const SizedBox(width: 8),
              Text(_ago(r.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          subtitle: (r.comment == null || r.comment!.isEmpty)
              ? null
              : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(r.comment!),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemCount: reviews.length,
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
  }
}

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
        return Icon(icon, size: size);
      }),
    );
  }
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.initial, required this.onChanged});
  final int initial;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    int selected = initial;
    return StatefulBuilder(
      builder: (ctx, setState) {
        return Row(
          children: List.generate(5, (i) {
            final idx = i + 1;
            return IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Icon(idx <= selected ? Icons.star : Icons.star_border),
              onPressed: () {
                setState(() => selected = idx);
                onChanged(idx);
              },
            );
          }),
        );
      },
    );
  }
}
