import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/booking_confirmation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pannable_rating_bar/flutter_pannable_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CompletedBookingCard extends StatefulWidget {
  final String level;
  final String date;
  final String time;
  final String bookingId;
  final String tutorId;
  final String tutorName;
  final String userId;
  final String userName;
  final String subject;
  final double rate;

  const CompletedBookingCard({
    super.key,
    required this.level,
    required this.date,
    required this.time,
    required this.bookingId,
    required this.tutorId,
    required this.tutorName,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.rate,
  });

  @override
  _CompletedBookingCardState createState() => _CompletedBookingCardState();
}

class _CompletedBookingCardState extends State<CompletedBookingCard> {
  String? role;
  bool isExpanded = false;
  bool isRated = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          role = userDoc['role'];
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unable to fetch user role.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _showRatingDialog() async {
    double currentRate = 0.0;
    String review = "";

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Rate ${widget.tutorName}',
                style: const TextStyle(fontSize: 20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PannableRatingBar(
                    rate: currentRate,
                    onChanged: (newRate) {
                      setState(() {
                        currentRate =
                            newRate; // Update the rating value within dialog state
                      });
                    },
                    items: List.generate(
                      5,
                      (index) => const RatingWidget(
                        selectedColor: Colors.amber,
                        unSelectedColor: Colors.grey,
                        child: Icon(Icons.star),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      review = value; // Capture the review text
                    },
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Write your review',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (currentRate == 0.0) {
                      Fluttertoast.showToast(
                        msg: "Please select a rating before submitting.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                      return;
                    }
                    try {
                      QuerySnapshot bookingQuery = await FirebaseFirestore
                          .instance
                          .collection('bookings')
                          .where('bookingId', isEqualTo: widget.bookingId)
                          .get();

                      if (bookingQuery.docs.isNotEmpty) {
                        String bookingDocId = bookingQuery.docs.first.id;

                        // Save rating to Firestore
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget
                                .tutorId) // Use tutorId to locate the tutor document
                            .collection(
                                'ratings') // Add a subcollection called 'ratings'
                            .add({
                          'userId': widget.userId,
                          'userName': widget.userName,
                          'bookingId': widget.bookingId,
                          'rating': currentRate,
                          'review': review,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        // Update booking document with isRated
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(bookingDocId)
                            .update({
                          'sessionConfirmed': true,
                          'isRated': true,
                          'rating': currentRate,
                          'review': review,
                        });

                        Fluttertoast.showToast(
                          msg: "Rating submitted successfully.",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );

                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: "Failed to submit rating.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Booking not found'));
        }

        var bookingDoc = snapshot.data!.docs[0];
        Map<String, dynamic> bookingData =
            bookingDoc.data() as Map<String, dynamic>;

// Check if the fields exist before accessing them
        bool isRated =
            bookingData.containsKey('isRated') ? bookingData['isRated'] : false;
        double rating =
            bookingData.containsKey('rating') ? bookingData['rating'] : 0.0;
        String review = bookingData.containsKey('review')
            ? bookingData['review']
            : "No review yet.";

        return Expanded(
          child: Column(
            children: [
              if (role == 'Student')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isRated
                        ? null // Disable button if rated
                        : () {
                            _showRatingDialog();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRated ? Colors.grey : Colors.yellow,
                    ),
                    child: Text(
                      isRated ? "Session Confirmed" : "Confirm session",
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmationPage(
                        level: widget.level,
                        date: widget.date,
                        timeSlot: widget.time,
                        bookingId: widget.bookingId,
                        tutorId: widget.tutorId,
                        tutorName: widget.tutorName,
                        userId: widget.userId,
                        userName: widget.userName,
                        tutorSubject: widget.subject,
                        price: widget.rate,
                        isPast: true,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "View Details",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              if (isRated)
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                  ),
                ),

              // Expandable Section for Rating and Review
              if (isExpanded)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Display a 5-star rating view
                        Row(
                          children: List.generate(5, (index) {
                            if (rating >= index + 1) {
                              return const Icon(Icons.star,
                                  color: Colors.amber, size: 20); // Full star
                            } else if (rating > index && rating < index + 1) {
                              return const Icon(Icons.star_half,
                                  color: Colors.amber, size: 20); // Half star
                            } else {
                              return const Icon(Icons.star_border,
                                  color: Colors.amber, size: 20); // Empty star
                            }
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rating.toStringAsFixed(1), // Show rating value
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                )
            ],
          ),
        );
      },
    );
  }
}
