import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/booking_bottom_sheet.dart';
import 'package:educonnect/chat_screen.dart';
import 'package:educonnect/review_card.dart';
import 'package:educonnect/tutor_personal_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/tutor.dart';
import 'package:educonnect/current_user.dart';

class TutorDetails extends StatelessWidget {
  final Tutor tutor;
  final CurrentUser currentUser;

  const TutorDetails(
      {super.key, required this.tutor, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Details'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFDDDFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Container(
              width: 110, // Set width to twice the CircleAvatar radius
              height: 110, // Set height to twice the CircleAvatar radius
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: tutor.profileImageUrl != null &&
                          tutor.profileImageUrl!.isNotEmpty
                      ? NetworkImage(tutor.profileImageUrl!) as ImageProvider
                      : const AssetImage('assets/blank_profile.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tutor.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(tutor.id)
                  .collection('ratings')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // Don't display the rating stars if no ratings
                  return const SizedBox.shrink(); // Empty widget
                }

                // Calculate the average rating
                double totalRating = 0.0;
                int ratingCount = snapshot.data!.docs.length;

                for (var doc in snapshot.data!.docs) {
                  totalRating += doc['rating'] ?? 0.0;
                }

                double averageRating = totalRating / ratingCount;

                // Display the rating stars
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    if (averageRating >= index + 1) {
                      return const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      );
                    } else if (averageRating > index &&
                        averageRating < index + 1) {
                      return const Icon(
                        Icons.star_half,
                        color: Colors.amber,
                        size: 20,
                      );
                    } else {
                      return const Icon(
                        Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }
                  }),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${tutor.level} level',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    tutor.subject,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PersonalInfo(tutor: tutor),
                  const SizedBox(height: 20),
                  if (tutor.aboutMe != '')
                    const Text(
                      'About me',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (tutor.aboutMe != '')
                    Container(
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      width: 500,
                      padding: const EdgeInsets.all(15),
                      child: Text(tutor.aboutMe),
                    ),
                  const SizedBox(height: 20),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(tutor.id)
                        .collection('ratings')
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox
                            .shrink(); // Empty widget if no ratings
                      }

                      // Calculate the average rating
                      double totalRating = 0.0;
                      int ratingCount = snapshot.data!.docs.length;

                      for (var doc in snapshot.data!.docs) {
                        totalRating += doc['rating'] ?? 0.0;
                      }

                      double averageRating = totalRating / ratingCount;

                      // Create a list of reviews from the snapshot
                      List<String> reviews = snapshot.data!.docs
                          .map((doc) => doc['review'] != null
                              ? doc['review'].toString()
                              : '')
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Reviews',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '($ratingCount)', // Show the number of reviews
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Text(
                                    averageRating.toStringAsFixed(
                                        1), // Display rating as a number with one decimal place
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.star,
                                    color: Colors
                                        .amber, // Yellow color for filled star
                                    size: 20, // Set the size of the star
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // ReviewCard widget if you want to show more detailed reviews
                          if (reviews.isNotEmpty)
                            ReviewCard(
                              tutor: tutor,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                // Get current authenticated user's ID
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                if (currentUserId != null) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUserId)
                      .get()
                      .then((userDoc) {
                    if (userDoc.exists) {
                      String studentName =
                          userDoc.data()?['username'] ?? 'Unknown User';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            tutorId: tutor.id,
                            tutorName: tutor.name,
                            studentName:
                                studentName, // Using directly fetched username
                          ),
                        ),
                      );
                    }
                  }).catchError((error) {
                    print('Error fetching user data: $error');
                  });
                }
              },
              icon: const Icon(
                Icons.message,
                color: Color.fromARGB(255, 79, 101, 241),
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showBookingSheet(
                      context,
                      tutor.level,
                      tutor.id,
                      tutor.name,
                      currentUser.id,
                      currentUser.name,
                      tutor.subject,
                      tutor.ratePerHour,
                      tutor.availableDays,
                      tutor.availableTimeSlots);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  'Book a schedule (RM${tutor.ratePerHour}/hour)',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(
      BuildContext context,
      String tutorLevel,
      String tutorId,
      String tutorName,
      String userId,
      String userName,
      String tutorSubject,
      double price,
      List<String> availableDays,
      List<int> availableTimeSlots) {
    showModalBottomSheet(
      context: context, // Parent Scaffold context
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext parentContext) {
        return BookingBottomSheet(
          parentContext: parentContext, // Pass the parent context here
          tutorLevel: tutorLevel,
          tutorId: tutorId,
          tutorName: tutorName,
          userId: userId,
          userName: userName,
          tutorSubject: tutorSubject,
          price: price,
          onConfirm: (level, date, timeSlot) {},
          availableDays: availableDays,
          availableTimeSlots: availableTimeSlots,
        );
      },
    );
  }
}
