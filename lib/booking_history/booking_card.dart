import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/booking_history/accepted_booking_card.dart';
import 'package:educonnect/booking_history/canceled_booking_card.dart';
import 'package:educonnect/booking_history/completed_booking_card.dart';
import 'package:educonnect/booking_history/pending_booking_card.dart';
import 'package:educonnect/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

Widget bookingCard(
  BuildContext context,
  String documentId,
  String bookingId,
  String tutorId,
  String tutorName,
  String userId,
  String userName,
  String subject,
  String level,
  String date,
  String time,
  double rate,
  bool isPending,
  bool isAccepted,
  bool isCompleted,
  bool isCanceled,
) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUserRoleDisplay(userId, tutorId, userName, tutorName),
              Text(
                'RM${rate.toStringAsFixed(0)}/hour',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: const TextStyle(fontSize: 15)),
              Text(date, style: const TextStyle(fontSize: 15)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(level, style: const TextStyle(fontSize: 15)),
              Text(time, style: const TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isCanceled)
                CanceledBookingCard(
                  level: level,
                  date: date,
                  time: time,
                  bookingId: bookingId,
                  tutorId: tutorId,
                  tutorName: tutorName,
                  userId: userId,
                  userName: userName,
                  subject: subject,
                  rate: rate,
                )
              else if (isPending)
                PendingBookingCard(
                  documentId: documentId,
                  level: level,
                  date: date,
                  time: time,
                  tutorName: tutorName,
                  userName: userName,
                  subject: subject,
                  rate: rate,
                  bookingId: bookingId,
                  tutorId: tutorId,
                  userId: userId,
                )
              else if (isAccepted)
                AcceptedBookingCard(bookingId: bookingId)
              else if (isCompleted)
                CompletedBookingCard(
                  level: level,
                  date: date,
                  time: time,
                  bookingId: bookingId,
                  tutorId: tutorId,
                  tutorName: tutorName,
                  userId: userId,
                  userName: userName,
                  subject: subject,
                  rate: rate,
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildUserRoleDisplay(
    String userId, String tutorId, String userName, String tutorName) {
  return FutureBuilder<String>(
    future: _getUserRole(userId, tutorId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return const Text("Error loading role");
      } else {
        String role = snapshot.data ?? "Unknown";
        String displayName = role == "Student" ? tutorName : userName;
        return Row(
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 79, 101, 241),
              ),
            ),
            IconButton(
              onPressed: () async {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                if (currentUserId != null) {
                  // Check if current user is tutor
                  if (currentUserId == tutorId) {
                    // Current user is tutor, pass userId as tutorId
                    print(
                        "User is tutor. Student ID: $userId, Tutor name: $tutorName, Student name: $userName");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          tutorId:
                              userId, // Pass student ID since we're the tutor
                          tutorName: tutorName,
                          studentName: userName,
                        ),
                      ),
                    );
                  } else {
                    // Current user is student, pass tutorId as tutorId
                    print(
                        "User is student. Tutor ID: $tutorId, Tutor name: $tutorName, Student name: $userName");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          tutorId:
                              tutorId, // Pass tutor ID since we're the student
                          tutorName: tutorName,
                          studentName: userName,
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(
                Icons.message,
                color: Color.fromARGB(255, 79, 101, 241),
                size: 20,
              ),
            ),
          ],
        );
      }
    },
  );
}

Future<String> _getUserRole(String userId, String tutorId) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == userId) return "Student";
  if (currentUserId == tutorId) return "Tutor";
  return "Unknown";
}

Future<String?> _fetchTutorNameFromBookingId(String bookingId) async {
  try {
    QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('bookingId', isEqualTo: bookingId)
        .get();

    return bookingSnapshot.docs.isNotEmpty
        ? bookingSnapshot.docs.first['tutorName']
        : null;
  } catch (e) {
    print("Error fetching tutor name: $e");
    return null;
  }
}

Future<String?> _fetchStudentNameFromBookingId(String bookingId) async {
  try {
    QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('bookingId', isEqualTo: bookingId)
        .get();

    return bookingSnapshot.docs.isNotEmpty
        ? bookingSnapshot.docs.first['userName']
        : null;
  } catch (e) {
    print("Error fetching student name: $e");
    return null;
  }
}
