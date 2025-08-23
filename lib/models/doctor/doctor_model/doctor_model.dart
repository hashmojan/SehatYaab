import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String image;
  final String name;
  final String specialty;
  final double rating;
  final int experience;
  final String city;
  final String fromMap;
  final List<String> categories;

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
  });

  // For backward compatibility if you need specialization
  String get specialization => specialty;

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Doctor(
      id: doc.id,
      image: data['image'] ?? 'assets/default_doctor.png',
      name: data['name'] ?? 'Unknown Doctor',
      specialty: data['specialty'] ?? data['specialization'] ?? 'General Practitioner',
      rating: (data['rating'] ?? 0).toDouble(),
      experience: data['experience'] ?? 0,
      city: data['city'] ?? '',
      fromMap: data['fromMap'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
    );
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] ?? '',
      image: map['image'] ?? 'assets/default_doctor.png',
      name: map['name'] ?? 'Unknown Doctor',
      specialty: map['specialty'] ?? map['specialization'] ?? 'General Practitioner',
      rating: (map['rating'] ?? 0).toDouble(),
      experience: map['experience'] ?? 0,
      city: map['city'] ?? '',
      fromMap: map['fromMap'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
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
    };
  }
}