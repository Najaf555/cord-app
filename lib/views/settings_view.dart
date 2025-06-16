import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX
import 'notifications_view.dart'; // Import your notification screen

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/profile.jpg'),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Mark Jones',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
              ),

              _settingsTile(title: 'User Profile', icon: Icons.person, onTap: () {}), _divider(),

              _settingsTile(title: 'Change Password', icon: Icons.lock, onTap: () {}, forceBlackIcon: true), _divider(),

              _settingsTile(title: 'FAQs', icon: Icons.help_outline, onTap: () {}), _divider(),

              // ✅ Notifications with Get.to()
              _settingsTile(
                title: 'Notifications',
                icon: Icons.notifications,
                onTap: () {
                  Get.to(() => const NotificationsView());
                },
                forceBlackIcon: true,
              ), _divider(),

              _settingsTile(title: 'Contact Us', icon: Icons.mail_outline, onTap: () {}), _divider(),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _divider() {
    return const Divider(
      color: Color(0xFFE0E0E0),
      thickness: 1,
      height: 1,
    );
  }
}
