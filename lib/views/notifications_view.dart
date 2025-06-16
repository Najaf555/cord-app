import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../controllers/navigation_controller.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  bool weeklyNewsletter = true;
  bool productUpdates = false;
  bool campaigns = true;

  final NavigationController navController = Get.put(NavigationController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Back Arrow
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // Weekly Newsletter
            _buildToggleTile(
              title: 'Weekly Newsletter',
              value: weeklyNewsletter,
              onChanged: (val) => setState(() => weeklyNewsletter = val),
            ),
            _divider(),

            // Product Updates
            _buildToggleTile(
              title: 'Product Updates',
              value: productUpdates,
              onChanged: (val) => setState(() => productUpdates = val),
            ),
            _divider(),

            // Campaigns
            _buildToggleTile(
              title: 'Campaigns',
              value: campaigns,
              onChanged: (val) => setState(() => campaigns = val),
            ),
            _divider(),
          ],
        ),
      ),

      // ✅ No FAB here
      bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
            activeTrackColor: const Color(0xFFC8E6C9),
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
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
