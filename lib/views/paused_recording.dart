import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';
import '../utils/responsive.dart';

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'New Session',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'New Recording',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '00:06.67',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'monospace',
                  letterSpacing: 1.2,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Waveform
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    color: const Color(0xFFF5F5F5),
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 1.5),
                        ),
                        child: ClipRect(
                          child: CustomPaint(
                            painter: _WaveformPainter(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: -12,
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                ],
              ),
              // Bookmark button and share icon
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.pink],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.bookmark_add_outlined,
                                color: Colors.black,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Set Bookmark',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 32,
                      child: Icon(
                        Icons.ios_share,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Play back and Continue buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      label: 'Play back',
                      onPressed: () {},
                      iconColor: Colors.black,
                      textColor: Colors.black,
                    ),
                    _buildControlButton(
                      icon: Icons.fiber_manual_record_outlined,
                      label: 'Continue',
                      onPressed: () {},
                      iconColor: Colors.red,
                      textColor: Colors.black,
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color iconColor,
    required Color textColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 48),
          color: iconColor,
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final heights = [
      2, 2, 3, 2, 2, 3, 2, 5, 8, 12, 18, 25, 30, 33, 30, 25, 18, 12, 8, 5,
      8, 12, 18, 25, 30, 35, 38, 35, 30, 25, 18, 12, 8, 5, 3,
    ];
    final barWidth = size.width / (heights.length * 1.8);

    for (int i = 0; i < heights.length; i++) {
      final x = barWidth * (i * 1.8);
      final barHeight = heights[i].toDouble();
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
