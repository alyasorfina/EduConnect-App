import 'package:educonnect/current_user.dart';
import 'package:educonnect/tutor.dart';
import 'package:educonnect/tutor_card.dart';
import 'package:educonnect/services/tutor_service.dart';
import 'package:flutter/material.dart';
import 'primary_filter_bar.dart';

class PrimaryScreen extends StatefulWidget {
  final List<Tutor> tutors;
  final CurrentUser currentUser;

  const PrimaryScreen(
      {super.key, required this.tutors, required this.currentUser});

  @override
  PrimaryScreenState createState() => PrimaryScreenState();
}

class PrimaryScreenState extends State<PrimaryScreen> {
  String selectedFilter = 'All';
  List<Tutor> displayedTutors = [];
  List<Tutor> allPrimaryTutors = [];

  @override
  void initState() {
    super.initState();
    fetchPrimaryTutors();
  }

  // Fetch primary level tutors
  Future<void> fetchPrimaryTutors() async {
    TutorService tutorService = TutorService();
    List<Tutor> tutors = await tutorService.fetchTutors();
    setState(() {
      allPrimaryTutors =
          tutors.where((tutor) => tutor.level == 'Primary').toList();
      displayedTutors = List.from(allPrimaryTutors);
    });
  }

  // Filter tutors based on selected filter
  void onFilterSelected(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'All') {
        displayedTutors =
            List.from(allPrimaryTutors); // Fetch again to reset the filter
      } else {
        displayedTutors = allPrimaryTutors
            .where((tutor) =>
                tutor.subject == filter) // Filter from allPrimaryTutors
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          PrimaryFilterBar(
            selectedFilter: selectedFilter,
            onFilterSelected: onFilterSelected,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: displayedTutors.length,
              itemBuilder: (context, index) {
                final tutor = displayedTutors[index];
                return TutorCard(
                  tutor: tutor,
                  currentUser: widget.currentUser,
                  isPrimary: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
