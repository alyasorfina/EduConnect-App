import 'package:educonnect/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RescheduleBottomSheet extends StatefulWidget {
  final BuildContext parentContext;
  final Function(String level, String date, String timeSlot)
      onRescheduleConfirm;
  final String currentLevel;
  final String tutorLevel;
  final String initialDate;
  final String initialTimeSlot;
  final List<String> availableDays; // e.g., ["Friday", "Thursday", "Wednesday"]
  final List<int> availableTimeSlots;
  final String bookingId;
  final String deviceToken;
  final String currentUserName;

  const RescheduleBottomSheet({
    super.key,
    required this.parentContext,
    required this.onRescheduleConfirm,
    required this.currentLevel,
    required this.tutorLevel,
    required this.initialDate,
    required this.initialTimeSlot,
    required this.availableDays,
    required this.availableTimeSlots,
    required this.bookingId,
    required this.deviceToken,
    required this.currentUserName,
  });

  @override
  _RescheduleBottomSheetState createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  String selectedLevel = '';
  String selectedDate = '';
  String selectedTimeSlot = '';
  final TextEditingController dateController = TextEditingController();
  late Future<Map<String, dynamic>> bookingDataFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the selected level from the current level
    selectedLevel = widget.currentLevel;

    // Initialize the selected date from the initialDate if provided
    selectedDate = widget.initialDate.isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : widget.initialDate;
    dateController.text = selectedDate;

    // Initialize the selected time slot from the initialTimeSlot if provided
    selectedTimeSlot = widget.initialTimeSlot.isNotEmpty
        ? widget.initialTimeSlot
        : _getTimeSlotString(widget.availableTimeSlots.isNotEmpty
            ? widget.availableTimeSlots.first
            : 0); // Default to first time slot if availableTimeSlots is not empty
  }

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
              'Reschedule Session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedLevel,
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
                  // Set the initial date to today.
                  DateTime initialDate = DateTime.now();

                  // Find the next available date that matches the availableDays.
                  while (!widget.availableDays.any((availableDay) =>
                      DateFormat('EEEE').format(initialDate).toLowerCase() ==
                      availableDay.toLowerCase())) {
                    initialDate = initialDate.add(const Duration(days: 1));
                  }

                  // Show the date picker once the initial date is set.
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate, // Set to the found valid date.
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: Colors.blue,
                          buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary),
                        ),
                        child: child!,
                      );
                    },
                    selectableDayPredicate: (DateTime day) {
                      String dayOfWeek =
                          DateFormat('EEEE').format(day).toLowerCase();
                      return widget.availableDays.any((availableDay) {
                        return availableDay.toLowerCase() == dayOfWeek;
                      });
                    },
                  );

                  // If a date is picked, update the state.
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
                onPressed: () async {
                  if (selectedLevel.isEmpty ||
                      selectedDate.isEmpty ||
                      selectedTimeSlot.isEmpty) {
                    _showOverlaySnackBar(
                      'Please select all fields to confirm rescheduling.',
                    );
                  } else {
                    Navigator.pop(context);
                    widget.onRescheduleConfirm(
                        selectedLevel, selectedDate, selectedTimeSlot);

                    await NotificationService.sendNotificationToTutor(
                      widget.deviceToken,
                      context,
                      widget.bookingId,
                      selectedDate,
                      selectedTimeSlot,
                      widget.currentUserName,
                      false,
                      true,
                      false,
                    );
                  }
                },
                child: const Text(
                  'Confirm Reschedule',
                  style: TextStyle(fontSize: 16),
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
}
