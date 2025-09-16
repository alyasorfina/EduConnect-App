import 'package:educonnect/booking_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class BookingBottomSheet extends StatefulWidget {
  final BuildContext parentContext;
  final Function(String level, String date, String timeSlot) onConfirm;
  final String tutorLevel;
  final String tutorId;
  final String tutorName;
  final String userId;
  final String userName;
  final String tutorSubject;
  final double price;
  final List<String>
      availableDays; // e.g. ["Friday", "Thursday", "Wednesday", "Tuesday"]
  final List<int> availableTimeSlots;

  const BookingBottomSheet({
    super.key,
    required this.parentContext,
    required this.onConfirm,
    required this.tutorLevel,
    required this.tutorId,
    required this.tutorName,
    required this.userId,
    required this.userName,
    required this.tutorSubject,
    required this.price,
    required this.availableDays,
    required this.availableTimeSlots,
  });

  @override
  _BookingBottomSheetState createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  String selectedLevel = '';
  String selectedDate = '';
  String selectedTimeSlot = '';
  final TextEditingController dateController = TextEditingController();

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Book a Session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Choose your level'),
              items: _getDropdownItems(),
              onChanged: (value) {
                setState(() {
                  selectedLevel = value!;
                });
              },
            ),
            TextFormField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                try {
                  // Find the next available date that matches one of the availableDays
                  DateTime initialDate = DateTime.now();
                  while (!widget.availableDays.any((availableDay) =>
                      DateFormat('EEEE').format(initialDate).toLowerCase() ==
                      availableDay.toLowerCase())) {
                    initialDate = initialDate.add(Duration(days: 1));
                  }

                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                    selectableDayPredicate: (DateTime day) {
                      String dayOfWeek =
                          DateFormat('EEEE').format(day).toLowerCase();
                      return widget.availableDays.any((availableDay) =>
                          availableDay.toLowerCase() == dayOfWeek);
                    },
                  );

                  if (pickedDate != null) {
                    setState(() {
                      selectedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                      dateController.text = selectedDate;
                    });
                  }
                } catch (e) {
                  print("Error showing date picker: $e");
                }
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Time Slot',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10.0,
              children: widget.availableTimeSlots.map((slot) {
                String timeSlot = _getTimeSlotString(slot);
                return _timeSlotButton(context, timeSlot);
              }).toList(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (selectedLevel.isEmpty ||
                      selectedDate.isEmpty ||
                      selectedTimeSlot.isEmpty) {
                    // Show Snackbar above the Bottom Sheet
                    _showOverlaySnackBar(
                      'Please select all fields to confirm your booking.',
                    );
                  } else {
                    String bookingId = generateConfirmationNumber();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingConfirmationPage(
                          level: selectedLevel,
                          date: selectedDate,
                          timeSlot: selectedTimeSlot,
                          bookingId: bookingId,
                          tutorId: widget.tutorId,
                          tutorName: widget.tutorName,
                          userId: widget.userId,
                          userName: widget.userName,
                          tutorSubject: widget.tutorSubject,
                          price: widget.price,
                          isPast: false,
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Confirm Booking',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOverlaySnackBar(String message) {
    final overlay = Overlay.of(widget.parentContext);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewInsets.top + 50,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  List<DropdownMenuItem<String>> _getDropdownItems() {
    List<String> levels = widget.tutorLevel == 'Primary'
        ? [
            'Standard 1',
            'Standard 2',
            'Standard 3',
            'Standard 4',
            'Standard 5',
            'Standard 6'
          ]
        : ['Form 1', 'Form 2', 'Form 3', 'Form 4', 'Form 5'];

    return levels
        .map((level) => DropdownMenuItem(
              value: level,
              child: Text(level),
            ))
        .toList();
  }

  String _getTimeSlotString(int slot) {
    switch (slot) {
      case 0:
        return '09:00AM - 10:00AM';
      case 1:
        return '10:00AM - 11:00AM';
      case 2:
        return '11:00AM - 12:00PM';
      case 3:
        return '02:00PM - 03:00PM';
      case 4:
        return '03:00PM - 04:00PM';
      case 5:
        return '04:00PM - 05:00PM';
      case 6:
        return '05:00PM - 06:00PM';
      case 7:
        return '07:00PM - 08:00PM';
      case 8:
        return '08:00PM - 09:00PM';
      case 9:
        return '09:00PM - 10:00PM';
      default:
        return '';
    }
  }

  Widget _timeSlotButton(BuildContext context, String time) {
    double buttonWidth = MediaQuery.of(context).size.width * 0.4;

    bool isSelected = selectedTimeSlot == time;

    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color.fromARGB(255, 59, 208, 89)
              : const Color.fromARGB(255, 186, 240, 202),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(5.0),
        ),
        onPressed: () {
          setState(() {
            selectedTimeSlot = time;
          });
        },
        child: Text(
          time,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String generateConfirmationNumber() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
