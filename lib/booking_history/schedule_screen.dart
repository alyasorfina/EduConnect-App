import 'package:educonnect/booking_history/past_booking.dart';
import 'package:educonnect/booking_history/upcoming_booking.dart';
import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Upcoming and Past
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          title: const Text('Booking History'),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color.fromARGB(255, 0, 0, 0),
            labelColor: Colors.black,
            tabs: [
              Tab(
                text: "Upcoming",
              ),
              Tab(text: "Past"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UpcomingBookings(),
            PastBookings(),
          ],
        ),
      ),
    );
  }
}
