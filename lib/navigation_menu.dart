import 'package:educonnect/chat_list_screen.dart';
import 'package:educonnect/services/current_user_service.dart';
import 'package:educonnect/home.dart';
import 'package:educonnect/booking_history/schedule_screen.dart';
import 'package:educonnect/profile/profile_screen.dart';
import 'package:educonnect/services/tutor_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:educonnect/tutor.dart';
import 'package:educonnect/current_user.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: controller.selectedIndex.value,
          onTap: (index) => controller.selectedIndex.value = index,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.schedule), label: "Schedule"),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          selectedItemColor: const Color(0xFF6981FF),
          unselectedItemColor: Colors.grey,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return controller.screens[controller.selectedIndex.value];
      }),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 3.obs;
  final RxBool isLoading = true.obs;
  final List<Widget> screens = [];

  final TutorService _tutorService = TutorService();
  final UserService _currentUserService = UserService();

  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  // Fetch tutors and current user data
  Future<void> _initializeData() async {
    try {
      // Fetch tutors and current user
      List<Tutor> tutors = await _tutorService.fetchTutors();
      CurrentUser? currentUser =
          await _currentUserService.fetchCurrentUser(userId);

      // Use a default user if currentUser is null
      currentUser ??= CurrentUser.defaultUser();

      // Initialize screens with fetched data
      screens.addAll([
        HomeScreen(tutors: tutors, currentUser: currentUser),
        const ScheduleScreen(),
        ChatListScreen(),
        const ProfileScreen(),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
