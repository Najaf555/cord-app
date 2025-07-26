import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX
import 'notifications_view.dart'; // Notifications screen
import 'user_profile_view.dart'; // ✅ ➊ User-profile screen
import 'change_password_view.dart'; // ✅ ➋ Change-password screen
import '../views/contact_view.dart'; // ✅ ➌ Corrected Contact screen import
import 'faqs_view.dart'; // ✅ ➍ FAQs screen import added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String userName = 'Loading...';
  String userEmail = '';
  String userProfileImageUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // First try to get display name from Firebase Auth
        String name = user.displayName ?? '';
        String email = user.email ?? '';
        String profileImageUrl = '';
        // If no display name, try to get from Firestore
        if (name.isEmpty) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            final firstName = userData?['firstName'] ?? '';
            final lastName = userData?['lastName'] ?? '';
            profileImageUrl = userData?['imageUrl'] ?? '';
            if (firstName.isNotEmpty && lastName.isNotEmpty) {
              name = '$firstName $lastName';
            } else if (firstName.isNotEmpty) {
              name = firstName;
            } else if (lastName.isNotEmpty) {
              name = lastName;
            } else {
              name = email.split('@')[0]; // Use email prefix as fallback
            }
          } else {
            name = email.split('@')[0]; // Use email prefix as fallback
          }
        }
        setState(() {
          userName = name;
          userEmail = email;
          userProfileImageUrl = profileImageUrl;
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'Guest User';
          userEmail = '';
          userProfileImageUrl = '';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = 'User';
        userEmail = '';
        userProfileImageUrl = '';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Gradient container above the app bar/status bar area
          // Container(
          //   height: MediaQuery.of(context).padding.top,
          //   decoration: const BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Color(0xFFFF833E), Color(0xFFFF0055)],
          //       begin: Alignment.topLeft,
          //       end: Alignment.topRight,
          //     ),
          //   ),
          // ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (userProfileImageUrl.isNotEmpty)
                                ? NetworkImage(userProfileImageUrl)
                                : null,
                            child: (userProfileImageUrl.isEmpty)
                                ? (isLoading
                                    ? const CircularProgressIndicator()
                                    : Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ))
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome,',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                Text(
                                  isLoading ? 'Loading...' : userName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                if (userEmail.isNotEmpty && !isLoading)
                                  Text(
                                    userEmail,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    ),

                    _settingsTile(
                      title: 'User Profile',
                      icon: Icons.person,
                      onTap: () => Get.to(() => const UserProfileView()),
                    ),
                    _divider(),

                    _settingsTile(
                      title: 'Change Password',
                      icon: Icons.lock,
                      onTap: () => Get.to(() => const ChangePasswordView()),
                      forceBlackIcon: true,
                    ),
                    _divider(),

                    // ✅ Updated FAQs navigation
                    _settingsTile(
                      title: 'FAQs',
                      icon: Icons.help_outline,
                      onTap:
                          () => Get.to(
                            () => const FAQScreen(),
                          ), // ← Navigates to FAQsView
                    ),
                    _divider(),

                    _settingsTile(
                      title: 'Notifications',
                      icon: Icons.notifications,
                      onTap: () => Get.to(() => const NotificationsView()),
                      forceBlackIcon: true,
                    ),
                    _divider(),

                    _settingsTile(
                      title: 'Contact Us',
                      icon: Icons.mail_outline,
                      onTap: () => Get.to(() => ContactUsScreen()),
                      forceBlackIcon: true,
                    ),
                    _divider(),

                      // Logout option
                      _settingsTile(
                        title: 'Log Out',
                        icon: Icons.logout,
                        onTap: () async {
                          await Get.dialog(
                            AlertDialog(
                              title: const Text('Log Out'),
                              content: const Text('Are you sure you want to log out?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      final user = FirebaseAuth.instance.currentUser;
                                      final fcmToken = await FirebaseMessaging.instance.getToken();
                                      if (user != null && fcmToken != null) {
                                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                          'fcmTokens': FieldValue.arrayRemove([fcmToken]),
                                        });
                                      }
                                      await FirebaseAuth.instance.signOut();
                                    } catch (e) {
                                      print('Error during logout: $e');
                                    }
                                    await Future.delayed(const Duration(milliseconds: 200));
                                    await Get.offAllNamed('/');
                                  },
                                  child: const Text('Log Out'),
                                ),
                              ],
                            ),
                          );
                        },
                        forceBlackIcon: true,
                      ),
                      _divider(),
                    ],
                  ),
                ),
              ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── helpers ──────────────────────────

  Widget _settingsTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool forceBlackIcon = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: forceBlackIcon ? Colors.black : Colors.black54),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      const Divider(color: Color(0xFFE0E0E0), thickness: 1, height: 1);
}
