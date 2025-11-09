import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String image;
  final String name;
  final String specialty;
  final double rating;      // legacy field if you were storing a fixed rating
  final int experience;
  final String city;
  final String fromMap;
  final List<String> categories;

  /// NEW: aggregated review stats kept on the doctor doc for fast reads
  final double ratingAvg;   // e.g. 4.35
  final int ratingCount;    // e.g. 17

  Doctor({
    required this.id,
    required this.image,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.experience,
    required this.city,
    required this.fromMap,
    required this.categories,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  // For backward compatibility if you need specialization
  String get specialization => specialty;

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Doctor(
      id: doc.id,
      image: (data['imageUrl'] ?? data['image'] ?? 'assets/default_doctor.png') as String,
      name: (data['name'] ?? 'Unknown Doctor') as String,
      specialty: (data['specialty'] ?? data['specialization'] ?? 'General Practitioner') as String,
      rating: ((data['rating'] ?? 0) as num).toDouble(),
      experience: (data['experience'] ?? 0) as int,
      city: (data['city'] ?? '') as String,
      fromMap: (data['fromMap'] ?? '') as String,
      categories: List<String>.from(data['categories'] ?? const []),
      ratingAvg: data['ratingAvg'] == null ? 0.0 : (data['ratingAvg'] as num).toDouble(),
      ratingCount: data['ratingCount'] == null ? 0 : (data['ratingCount'] as num).toInt(),
    );
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: (map['id'] ?? '') as String,
      image: (map['imageUrl'] ?? map['image'] ?? 'assets/default_doctor.png') as String,
      name: (map['name'] ?? 'Unknown Doctor') as String,
      specialty: (map['specialty'] ?? map['specialization'] ?? 'General Practitioner') as String,
      rating: ((map['rating'] ?? 0) as num).toDouble(),
      experience: (map['experience'] ?? 0) as int,
      city: (map['city'] ?? '') as String,
      fromMap: (map['fromMap'] ?? '') as String,
      categories: List<String>.from(map['categories'] ?? const []),
      // NEW fields also supported from plain maps:
      ratingAvg: map['ratingAvg'] == null ? 0.0 : (map['ratingAvg'] as num).toDouble(),
      ratingCount: map['ratingCount'] == null ? 0 : (map['ratingCount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image': image,
      'name': name,
      'specialty': specialty,
      'rating': rating,
      'experience': experience,
      'city': city,
      'fromMap': fromMap,
      'categories': categories,
      'ratingAvg': ratingAvg,     // keep on doctor doc for quick reads
      'ratingCount': ratingCount, // keep on doctor doc for quick reads
    };
  }

  Doctor copyWith({
    String? id,
    String? image,
    String? name,
    String? specialty,
    double? rating,
    int? experience,
    String? city,
    String? fromMap,
    List<String>? categories,
    double? ratingAvg,
    int? ratingCount,
  }) {
    return Doctor(
      id: id ?? this.id,
      image: image ?? this.image,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
      city: city ?? this.city,
      fromMap: fromMap ?? this.fromMap,
      categories: categories ?? this.categories,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
