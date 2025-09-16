import 'package:educonnect/chat_list_screen.dart';
import 'package:educonnect/current_user.dart';
import 'package:educonnect/primary_level/primary_level.dart';
import 'package:educonnect/profile/profile_screen.dart';
import 'package:educonnect/booking_history/schedule_screen.dart';
import 'package:educonnect/search.dart';
import 'package:educonnect/secondary_level/secondary_level.dart';
import 'package:educonnect/tutor.dart';
import 'package:educonnect/services/tutor_service.dart';
import 'package:flutter/material.dart';
import 'appbar.dart';

class HomeScreen extends StatefulWidget {
  final List<Tutor> tutors;
  final CurrentUser currentUser; // Accept currentUser as a parameter

  const HomeScreen({
    super.key,
    required this.tutors,
    required this.currentUser, // Pass currentUser
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Tutor> searchResults = [];
  final TutorService tutorService = TutorService();

  late CurrentUser currentUser; // Declare currentUser in the state

  @override
  void initState() {
    super.initState();
    currentUser =
        widget.currentUser; // Initialize currentUser from the passed parameter
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleSearch(BuildContext context) async {
    List<Tutor> fetchedTutors = await tutorService.fetchTutors();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          allTutors: fetchedTutors,
          currentUser: currentUser, // Pass currentUser to the search page
          onSearchResults: (List<Tutor> results) {
            setState(() {
              searchResults = results;
            });
          },
        ),
      ),
    );
  }

  Future<void> _refreshTutors() async {
    List<Tutor> updatedTutors = await tutorService.fetchTutors();
    setState(() {
      searchResults = updatedTutors
          .where((tutor) => tutor.qualificationStatus == 'Verified')
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Tutor> tutorsToDisplay =
        searchResults.isNotEmpty ? searchResults : widget.tutors;

    final List<Widget> _children = [
      PrimaryScreen(
        tutors: tutorsToDisplay,
        currentUser: currentUser, // Pass currentUser to PrimaryScreen
      ),
      SecondaryScreen(
        tutors: tutorsToDisplay,
        currentUser: currentUser, // Pass currentUser to SecondaryScreen
      ),
      const ScheduleScreen(),
      ChatListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        currentIndex: _currentIndex,
        onTabTapped: onTabTapped,
        onSearchPressed: () => _handleSearch(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTutors,
        child: _children[_currentIndex], // Display the correct screen
      ),
    );
  }
}
