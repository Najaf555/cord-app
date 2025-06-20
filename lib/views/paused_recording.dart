import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';

class PausedRecording extends StatelessWidget {
  const PausedRecording({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top indicator
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paused Recording',
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('00:07', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Waveform
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: const Color(0xFFF5F5F5),
                    child: Center(
                      child: SizedBox(
                        width: 180,
                        height: 60,
                        child: CustomPaint(painter: _WaveformPainter()),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: -10,
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
              // Bookmark button and share icon
              const SizedBox(height: 32),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border, color: Colors.red),
                      label: const Text(
                        'Set Bookmark',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.black54),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Play back and Continue buttons (centered)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black54, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 32,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Play back', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.fiber_manual_record,
                              color: Colors.red,
                              size: 32,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Continue',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
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
              child: Container(height: 2, color: const Color(0xFFE0E0E0)),
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
                child: Obx(
                  () => BottomNavigationBar(
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
                      Get.offAll(() => MainNavigation());
                      Get.find<NavigationController>().changeTab(index);
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
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final heights = [10, 30, 50, 30, 10, 30, 50, 30, 10];
    final barWidth = size.width / (heights.length * 2 - 1);
    for (int i = 0; i < heights.length; i++) {
      final x = i * barWidth * 2;
      final y1 = size.height / 2 - heights[i] / 2;
      final y2 = size.height / 2 + heights[i] / 2;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
