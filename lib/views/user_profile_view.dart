import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // ✅ Email Controller
  final NavigationController navController = Get.find<NavigationController>();

  void _saveProfile() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim(); // ✅ Email

    Get.snackbar(
      'Profile Saved',
      'First Name: $firstName\nLast Name: $lastName\nEmail: $email',
      snackPosition: SnackPosition.BOTTOM,
    );

    Get.back(); // Navigate back to previous screen (Settings)
  }

  void _onTabSelected(int index) {
    navController.changeTab(index);
    Get.offAll(() => MainNavigation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Circle Profile Image
            const CircleAvatar(
              radius: 45,
              backgroundImage: AssetImage('assets/profile.jpg'), // Replace with your asset
            ),
            const SizedBox(height: 16),

            // Title Text
            const Text(
              'User Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // First Name Field
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Last Name Field
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Email Field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.red, width: 2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Square corners
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Stack(
        children: [
          // Top border line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, color: Color(0xFFE0E0E0)),
          ),
          // Shadow overlay just below the border line
          Positioned(
            top: 1,
            left: 0,
            right: 0,
            child: Container(
              height: 12,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
          // BottomAppBar with nav bar
          BottomAppBar(
            color: Colors.white,
            elevation: 0,
            notchMargin: 0,
            child: Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
              ),
              child: Obx(() => BottomNavigationBar(
                backgroundColor: Colors.white,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Color(0xFF222222),
                unselectedItemColor: Color(0xFFBDBDBD),
                selectedLabelStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
                currentIndex: navController.selectedIndex.value,
                onTap: _onTabSelected,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.folder),
                    label: 'Sessions',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}
