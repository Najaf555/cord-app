import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sessionate/views/session_detail_view.dart';
import '../controllers/navigation_controller.dart';
import 'sessions_view.dart';
import 'settings_view.dart';
import '../controllers/session_detail_controller.dart';

class MainNavigation extends StatelessWidget {
  MainNavigation({super.key});


  final NavigationController navController = Get.put(NavigationController());

  final List<Widget> _pages = [
    SessionsView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          resizeToAvoidBottomInset: false,
          body: Obx(() {
            if (navController.currentSession.value != null) {
              // If a session is selected, show SessionDetailView
              return GetBuilder<SessionDetailController>(
                init: SessionDetailController(session: navController.currentSession.value!),
                builder: (_) => SessionDetailView(),
              );
            } else {
              // Otherwise, show the selected tab (SessionsView or SettingsView)
              return _pages[navController.selectedIndex.value];
            }
          }),
          floatingActionButton: SizedBox(
            height: 64,
            width: 64,
            child: FloatingActionButton(
              onPressed: () {},
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              shape: const CircleBorder(),
              child: Image.asset(
                'assets/images/centerButton.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: Stack(
            children: [
              // Top border line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  color: Color(0xFFE0E0E0),
                ),
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
                  child: BottomNavigationBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: Color(0xFF222222),
                    unselectedItemColor: Color(0xFFBDBDBD),
                    selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 12),
                    unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 12),
                    currentIndex: navController.selectedIndex.value,
                    onTap: (index) {
                      navController.changeTab(index);
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
                  ),
                ),
              ),
            ],
          ),
        ));
  }
} 