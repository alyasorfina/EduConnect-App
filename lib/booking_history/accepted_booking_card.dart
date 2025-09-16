import 'package:educonnect/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AcceptedBookingCard extends StatefulWidget {
  final String bookingId;

  AcceptedBookingCard({required this.bookingId});

  @override
  _AcceptedBookingCardState createState() => _AcceptedBookingCardState();
}

class _AcceptedBookingCardState extends State<AcceptedBookingCard> {
  Color _buttonColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _checkMeetingLink();
  }

  Future<void> _checkMeetingLink() async {
    String? meetingLink = await _getMeetingLink(widget.bookingId);
    if (meetingLink != null) {
      setState(() {
        _buttonColor = Colors.green;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton(
          onPressed: () => _handleMeetingLink(widget.bookingId),
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonColor,
          ),
          child: const Text(
            "Join the meeting",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMeetingLink(String bookingId) async {
    String? meetingLink = await _getMeetingLink(bookingId);
    if (meetingLink != null) {
      _launchURL(meetingLink);
    } else {
      Fluttertoast.showToast(
        msg: "Meeting link is unavailable or outside the scheduled time.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<String?> _getMeetingLink(String bookingId) async {
    try {
      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        DocumentSnapshot bookingDoc = bookingSnapshot.docs.first;

        String? meetingLink = bookingDoc['meetingLink'];
        String dateStr = bookingDoc['date'];
        String timeStr = bookingDoc['time'];
        String tutorId = bookingDoc['tutorId'];
        String userId = bookingDoc['userId'];

        String? tutorToken = await _getUserDeviceToken(tutorId);
        String? userToken = await _getUserDeviceToken(userId);

        if (tutorToken == null || userToken == null) {
          print('Error: One or both device tokens are missing.');
          return null;
        }

        List<String> timeParts = timeStr.split(' - ');
        if (timeParts.length == 2) {
          DateTime bookingStartTime =
              _parseBookingTime(dateStr, timeParts[0].trim());
          DateTime bookingEndTime =
              _parseBookingTime(dateStr, timeParts[1].trim());

          DateTime currentTimeInMYT = DateTime.now();
          DateTime linkAvailabilityTime =
              bookingStartTime.subtract(const Duration(minutes: 30));

          // If the current date is the same as the booking date, check the time

          if (currentTimeInMYT.isAfter(bookingEndTime)) {
            await _updateBookingStatus(bookingDoc.id);
          }

          //Send notifications 30 minutes before the session starts
          if (currentTimeInMYT.isAfter(linkAvailabilityTime) &&
              currentTimeInMYT.isBefore(
                  linkAvailabilityTime.add(const Duration(minutes: 1)))) {
            await NotificationService.sendSessionNotification(
                userToken, tutorToken, bookingId, dateStr, timeStr);
          }

          // Return the meeting link if within the valid timeframe
          if (currentTimeInMYT.isAfter(linkAvailabilityTime) &&
              currentTimeInMYT.isBefore(bookingEndTime)) {
            return meetingLink;
          }
        }
      }
    } catch (e) {
      print('Error retrieving meeting link: $e');
    }
    return null;
  }

  DateTime _parseBookingTime(String dateStr, String timeStr) {
    try {
      String combinedDateTimeStr = "$dateStr $timeStr".trim();
      DateFormat dateFormat = DateFormat("yyyy-MM-dd h:mma");
      return dateFormat.parse(combinedDateTimeStr);
    } catch (e) {
      print('Error parsing date: $e');
      return DateTime.now();
    }
  }

  Future<String?> _getUserDeviceToken(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['token']; // Assuming 'deviceToken' is the field name
      }
    } catch (e) {
      print('Error retrieving device token for user $userId: $e');
    }
  }

  Future<void> _updateBookingStatus(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(documentId)
          .update({
        'isAccepted': false,
        'isCompleted': true,
        'sessionConfirmed': false,
      });
    } catch (e) {
      print('Error updating booking status: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
