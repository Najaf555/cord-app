import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final Function(int) onTabSelected;
  const CustomBottomNavigationBar({super.key, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<NavigationController>();

    return BottomAppBar(
      color: Colors.white,
      elevation: 0,
      child: Obx(() => BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF222222),
            unselectedItemColor: const Color(0xFFBDBDBD),
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            currentIndex: navController.selectedIndex.value,
            onTap: (index) {
              navController.changeTab(index);
              onTabSelected(index);
            },
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
    );
  }
}
