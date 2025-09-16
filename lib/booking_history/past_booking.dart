import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/booking_history/booking_card.dart';
import 'package:educonnect/booking_history/booking_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PastBookings extends StatefulWidget {
  const PastBookings({super.key});

  @override
  _PastBookingsState createState() => _PastBookingsState();
}

class _PastBookingsState extends State<PastBookings> {
  bool showCompleted = true;
  bool showCanceled = false;
  List<String> bookedSessionIds = [];

  @override
  void initState() {
    super.initState();
    _fetchBookedSessions();
  }

  // Fetch bookedSession list from the current user's document
  Future<void> _fetchBookedSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          bookedSessionIds =
              List<String>.from(doc.data()?['bookedSessions'] ?? []);
        });
      }
    }
  }

  // Stream query based on selected filter and bookedSession list
  Stream<QuerySnapshot<Map<String, dynamic>>> _getBookingsStream() async* {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        List<String> bookedSessions =
            List<String>.from(userDoc.data()?['bookedSessions'] ?? []);

        if (showCompleted) {
          // Stream only completed bookings
          yield* FirebaseFirestore.instance
              .collection('bookings')
              .where('bookingId', whereIn: bookedSessions)
              .where('isCompleted', isEqualTo: true)
              .snapshots();
        } else if (showCanceled) {
          // Stream both canceled and rejected bookings

          yield* FirebaseFirestore.instance
              .collection('bookings')
              .where('bookingId', whereIn: bookedSessions)
              .where('isCanceled', isEqualTo: true)
              .snapshots();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        ToggleButtons(
          isSelected: [showCompleted, showCanceled],
          onPressed: (int index) {
            setState(() {
              if (index == 0) {
                showCompleted = true;
                showCanceled = false;
              } else {
                showCompleted = false;
                showCanceled = true;
              }
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text('Completed'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text('Canceled'),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                _getBookingsStream(), // stream query based on toggle buttons
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No past bookings.'));
              }

              final bookings = snapshot.data!.docs
                  .map((doc) {
                    try {
                      return Booking.fromFirestore(doc);
                    } catch (e) {
                      print('Error parsing booking: $e');
                      return null;
                    }
                  })
                  .whereType<Booking>()
                  .toList();

              if (bookings.isEmpty) {
                return const Center(
                    child: Text('No completed or canceled bookings.'));
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
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
                        false, // No reschedule/cancel buttons for past bookings
                        false,
                        booking.isCompleted,
                        booking.isCanceled,
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
