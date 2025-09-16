import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/booking_history/booking_model.dart';
import 'package:educonnect/current_user.dart';
import 'package:educonnect/services/current_user_service.dart';
import 'package:educonnect/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BookingConfirmationPage extends StatelessWidget {
  final String level;
  final String date;
  final String timeSlot;
  final String tutorId;
  final String tutorName;
  final String userId;
  final String userName;
  final String tutorSubject;
  final String bookingId;
  final double price;
  final bool isPast;

  const BookingConfirmationPage({
    super.key,
    required this.level,
    required this.date,
    required this.timeSlot,
    required this.tutorId,
    required this.tutorName,
    required this.userId,
    required this.userName,
    required this.tutorSubject,
    required this.bookingId,
    required this.price,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final UserService userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Details',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _detailRow('Booking Date:', date),
            const SizedBox(height: 5),
            _detailRow('Time:', timeSlot),
            const SizedBox(height: 5),
            _detailRow('Tutor:', tutorName),
            const SizedBox(height: 5),
            _detailRow('Subject:', tutorSubject),
            const SizedBox(height: 5),
            _detailRow('Education Level:', level),
            const Divider(height: 30, thickness: 1),
            const Text(
              'Booking Summary',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _detailRow('Confirmation Number:', bookingId),
            const SizedBox(height: 5),
            _detailRow('Price:', 'RM${price.toStringAsFixed(2)}'),
            const Spacer(),
            // Use FutureBuilder to fetch the user data
            FutureBuilder<CurrentUser?>(
              future: userService.fetchCurrentUser(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching user data'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('User not found'));
                }

                final user = snapshot.data;
                final String currentUserName = user?.name ?? 'Guest';

                return SizedBox(
                  width: double.infinity,
                  child: isPast
                      ? const SizedBox() // Empty widget when it's a past booking
                      : ElevatedButton(
                          onPressed: () async {
                            // Create a Booking object to pass back
                            final newBooking = Booking(
                              bookingId: bookingId,
                              tutorId: tutorId,
                              tutorName: tutorName,
                              userId: userId,
                              userName: currentUserName,
                              subject: tutorSubject,
                              level: level,
                              date: date,
                              time: timeSlot,
                              price: price,
                              isPending: true,
                              isAccepted: false,
                              isCompleted: false,
                              isCanceled: false,
                            );

                            try {
                              // Add booking to the 'bookings' collection
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .add({
                                'bookingId': bookingId,
                                'tutorId': tutorId,
                                'tutorName': tutorName,
                                'userId': userId,
                                'userName': currentUserName,
                                'subject': tutorSubject,
                                'level': level,
                                'date': date,
                                'time': timeSlot,
                                'price': price,
                                'isPending': true,
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              // Update student's bookedSessions array
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .update({
                                'bookedSessions':
                                    FieldValue.arrayUnion([bookingId])
                              });

                              // Update tutor's bookedSessions array
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(tutorId)
                                  .update({
                                'bookedSessions':
                                    FieldValue.arrayUnion([bookingId])
                              });

                              Fluttertoast.showToast(
                                msg: "Your booking is successful!",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor:
                                    const Color.fromARGB(255, 34, 145, 38),
                                textColor: Colors.white,
                                fontSize: 16.0,
                              );
                              Navigator.pop(context, newBooking);

                              DocumentSnapshot tutorSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(tutorId)
                                      .get();
                              String deviceToken = tutorSnapshot['token'];

                              // Send notification to tutor
                              await NotificationService.sendNotificationToTutor(
                                  deviceToken,
                                  context,
                                  bookingId,
                                  date,
                                  timeSlot,
                                  currentUserName,
                                  true,
                                  false,
                                  false);
                            } catch (e) {
                              print('Error saving booking: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Failed to save booking. Please try again.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Pay Now',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create detail rows for better readability
  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
