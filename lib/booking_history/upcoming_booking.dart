import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/booking_history/booking_card.dart';
import 'package:educonnect/booking_history/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for user authentication

class UpcomingBookings extends StatefulWidget {
  const UpcomingBookings({super.key});

  @override
  _UpcomingBookingsState createState() => _UpcomingBookingsState();
}

class _UpcomingBookingsState extends State<UpcomingBookings> {
  bool showPending = true; // Show pending bookings by default
  bool showAccepted = false; // Show accepted bookings by default
  List<String> userBookedSessions = []; // To store the user's booked sessions

  @override
  void initState() {
    super.initState();
    _fetchUserBookedSessions();
  }

  // Fetch the current user's bookedSessions
  Future<void> _fetchUserBookedSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data();
      if (data != null && data['bookedSessions'] != null) {
        setState(() {
          userBookedSessions = List<String>.from(data['bookedSessions']);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Toggle Buttons for Upcoming Bookings
        ToggleButtons(
          isSelected: [showPending, showAccepted],
          onPressed: (int index) {
            setState(() {
              showPending = index == 0;
              showAccepted = index == 1;
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text('Pending'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text('Accepted'),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance.collection('bookings').snapshots(),
            builder: (context, snapshot) {
              // Check for loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Handle errors and empty data
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading bookings.'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No upcoming bookings.'));
              }

              // Filter bookings based on the current user's bookedSessions and toggle selection
              final bookings = snapshot.data!.docs
                  .map((doc) =>
                      Booking.fromFirestore(doc)) // Convert to Booking objects
                  .where((booking) {
                // Filter bookings by the booking ID in user's bookedSessions
                if (!userBookedSessions.contains(booking.bookingId)) {
                  return false;
                }

                // Filter further based on toggle selection
                if (showPending && booking.isPending) {
                  return true;
                } else if (showAccepted && booking.isAccepted) {
                  return true;
                }
                return false;
              }).toList();

              if (bookings.isEmpty) {
                return const Center(child: Text('No bookings found.'));
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bookings.map((booking) {
                      return bookingCard(
                        context,
                        booking.documentId ?? '',
                        booking.bookingId,
                        booking.tutorId,
                        booking.tutorName,
                        booking.userId,
                        booking.userName,
                        booking.subject,
                        booking.level,
                        booking.date,
                        booking.time,
                        booking.price,
                        booking.isPending,
                        booking.isAccepted,
                        false, // No reschedule/cancel buttons for upcoming bookings
                        false, // Not a past booking
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
