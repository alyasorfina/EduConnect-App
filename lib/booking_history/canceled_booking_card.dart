import 'package:flutter/material.dart';
import 'package:educonnect/booking_confirmation.dart'; // Ensure this import points to the correct path

class CanceledBookingCard extends StatelessWidget {
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

  const CanceledBookingCard({
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
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingConfirmationPage(
                  level: level,
                  date: date,
                  timeSlot: time,
                  bookingId: bookingId,
                  tutorId: tutorId,
                  tutorName: tutorName,
                  userId: userId,
                  userName: userName,
                  tutorSubject: subject,
                  price: rate,
                  isPast: true,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 80, 79, 79),
          ),
          child: const Text(
            "View details",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
