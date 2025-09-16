import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? documentId; // Unique identifier for the booking
  final String bookingId;
  final String tutorId;
  final String tutorName;
  final String userId;
  final String userName;
  final String subject; // Subject being tutored
  final String level; // Education level of the student
  final String date; // Date of the booking
  final String time; // Time of the booking
  final double price; // Price of the booking
  final bool isPending; // Status of the booking
  final bool isAccepted;
  final bool isCompleted;
  final bool isCanceled;

  Booking({
    this.documentId,
    required this.bookingId,
    required this.tutorId,
    required this.tutorName,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.level,
    required this.date,
    required this.time,
    required this.price,
    required this.isPending,
    required this.isAccepted,
    required this.isCompleted,
    required this.isCanceled,
  });

  // Factory constructor to create a Booking object from Firestore data
  factory Booking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Booking(
      documentId: doc.id,
      bookingId: data['bookingId'] ?? '',
      tutorId: data['tutorId'] ?? '',
      tutorName: data['tutorName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      subject: data['subject'] ?? '',
      level: data['level'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      price: (data['price'] is num) // Ensure price is a number
          ? (data['price'] as num).toDouble()
          : double.tryParse(data['price'].toString()) ??
              0.0, // Handle conversion
      isPending: data['isPending'] ?? false,
      isAccepted: data['isAccepted'] ?? false,
      isCompleted: data['isCompleted'] ?? false,
      isCanceled: data['isCanceled'] ?? false,
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'boookingId': bookingId,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'userId': userId,
      'userName': userName,
      'subject': subject,
      'level': level,
      'date': date,
      'time': time,
      'price': price,
      'isPending': isPending,
      'isAccepted': isAccepted,
      'isCompleted': isCompleted,
      'isCanceled': isCanceled,
    };
  }
}
