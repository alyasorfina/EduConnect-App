import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/booking_history/reschedule_bottom_sheet.dart';
import 'package:educonnect/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PendingBookingCard extends StatefulWidget {
  final String documentId;
  final String level;
  final String date;
  final String time;
  final String tutorName;
  final String userName;
  final String subject;
  final double rate;
  final String bookingId;
  final String tutorId;
  final String userId;

  const PendingBookingCard({
    super.key,
    required this.documentId,
    required this.level,
    required this.date,
    required this.time,
    required this.tutorName,
    required this.userName,
    required this.subject,
    required this.rate,
    required this.bookingId,
    required this.tutorId,
    required this.userId,
  });

  @override
  _PendingBookingCardState createState() => _PendingBookingCardState();
}

class _PendingBookingCardState extends State<PendingBookingCard> {
  String? role;

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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          context,
          role == "Student" ? "Cancel" : "Reject",
          Colors.red,
          () async {
            if (role == "Student") {
              _showCancellationConfirmation(context);
            } else if (role == "Tutor") {
              _showRejectionConfirmation(context);
            }
          },
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          context,
          role == "Student" ? "Reschedule" : "Accept",
          Colors.green,
          () async {
            if (role == "Student") {
              _openRescheduleBottomSheet(context);
            } else if (role == "Tutor") {
              _showMeetingLinkDialog(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: role != null ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown, // Ensures text scales down to fit
        child: Text(label),
      ),
    );
  }

  void _showRejectionConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Rejection'),
          content: const Text('Are you sure you want to reject this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .get();

                String deviceToken = userDoc['token'];

                await NotificationService.sendNotificationToStudent(
                    deviceToken,
                    context,
                    widget.bookingId,
                    widget.date,
                    widget.time,
                    widget.tutorName,
                    false,
                    true);
                Navigator.of(context).pop();
                await _updateBookingStatus(
                    context, "Booking rejected successfully.", {
                  'isCanceled': true,
                  'isPending': false,
                });
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showCancellationConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateBookingStatus(
                    context, "Booking cancelled successfully.", {
                  'isCanceled': true,
                  'isPending': false,
                });

                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.tutorId)
                    .get();

                String deviceToken = userDoc['token'];

                await NotificationService.sendNotificationToTutor(
                  deviceToken,
                  context,
                  widget.bookingId,
                  widget.date,
                  widget.time,
                  widget.userName,
                  false,
                  false,
                  true,
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openRescheduleBottomSheet(BuildContext context) async {
    try {
      // Fetch the tutor's details from Firestore
      DocumentSnapshot tutorDoc = await FirebaseFirestore.instance
          .collection('qualifications')
          .doc(widget.tutorId)
          .get();

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.tutorId)
          .get();

      if (!tutorDoc.exists) {
        Fluttertoast.showToast(
          msg: "Tutor information not found.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      // Extract data from the tutor document
      String tutorLevel = tutorDoc['level'];
      List<String> availableDays = List<String>.from(tutorDoc['availableDays']);
      List<int> availableTimeSlots =
          List<int>.from(tutorDoc['availableTimeSlots']);
      String deviceToken = userDoc['token'];

      // Show the RescheduleBottomSheet with the fetched data
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return RescheduleBottomSheet(
            parentContext: context,
            onRescheduleConfirm:
                (String newLevel, String newDate, String newTime) async {
              await _updateBookingStatus(context, "Rescheduling successful!", {
                'level': newLevel,
                'date': newDate,
                'time': newTime,
                'isPending': true,
                'isAccepted': false,
              });
            },
            tutorLevel: tutorLevel,
            currentLevel: widget.level,
            availableDays: availableDays,
            availableTimeSlots: availableTimeSlots,
            bookingId: widget.bookingId,
            initialDate: widget.date,
            initialTimeSlot: widget.time,
            deviceToken: deviceToken,
            currentUserName: widget.userName,
          );
        },
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to load tutor information. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _showMeetingLinkDialog(BuildContext context) async {
    TextEditingController linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Meeting Link'),
          content: TextField(
            controller: linkController,
            decoration:
                const InputDecoration(hintText: 'Paste your meeting link here'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .get();

                String deviceToken = userDoc['token'];

                NotificationService.sendNotificationToStudent(
                    deviceToken,
                    context,
                    widget.bookingId,
                    widget.date,
                    widget.time,
                    widget.tutorName,
                    true,
                    false);
                String link = linkController.text;
                if (link.isNotEmpty) {
                  await _updateBookingStatus(
                      context, "Booking accepted successfully.", {
                    'isAccepted': true,
                    'isPending': false,
                    'meetingLink': link,
                  });
                } else {
                  Fluttertoast.showToast(
                    msg: "Please enter a valid meeting link.",
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateBookingStatus(BuildContext context, String successMessage,
      Map<String, dynamic> status) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.documentId)
          .update(status);
      Fluttertoast.showToast(
        msg: successMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 34, 145, 38),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update booking. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 142, 11, 27),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}
