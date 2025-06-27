import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'paused_recording.dart';
import '../controllers/navigation_controller.dart';

class NewRecordingScreen extends StatelessWidget {
  const NewRecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Scaffold(
        backgroundColor: Colors.white,
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
                      Navigator.of(context).pop(); // Dismiss the modal
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
            ),
          ],
        ),
        floatingActionButton: SizedBox(
          height: 64,
          width: 64,
          child: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const PausedRecording(),
              );
            },
            elevation: 0,
            backgroundColor: Colors.white,
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
        body: SafeArea(
          child: Column(
            children: [
              // Top indicator for closing screen
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24), // Placeholder for symmetry
                    Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Free Falling v2',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.edit, size: 18, color: Colors.black54),
                          ],
                        ),
                        const Text(
                          'New Recording',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Timer
              const SizedBox(height: 12),
              const Text(
                '00:06.67',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              // Waveform and blue arrow
              const SizedBox(height: 12),
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
                  Positioned(
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
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Container(
                        height: 44,
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
                            children: const [
                              Icon(
                                Icons.bookmark_add_outlined,
                                color: Colors.black,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Set Bookmark',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
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
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Bookmark filter chips and list (as in the image)
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _BookmarkChip(label: 'John', color: Color(0xFFFFA726)),
                      SizedBox(width: 8),
                      _BookmarkChip(label: 'Mark', color: Color(0xFF1976D2), selected: true),
                      SizedBox(width: 8),
                      _BookmarkChip(label: 'Steve', color: Color(0xFF66BB6A)),
                      SizedBox(width: 8),
                      _BookmarkChip(label: 'All', color: Color(0xFFE0E0E0), textColor: Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.bookmark, color: Color(0xFF1976D2)),
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('00:03', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                    SizedBox(width: 8),
                    Text('Intro melody', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Fill remaining space
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple waveform painter for demo purposes
class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
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

class _BookmarkChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final Color? textColor;
  const _BookmarkChip({
    required this.label,
    required this.color,
    this.selected = false,
    this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : (textColor ?? color),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class NewRecordingContent extends StatelessWidget {
  const NewRecordingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // You can add a top border radius for modal effect
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add your new recording content here
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('New Recording Content'),
          ),
          // ...rest of your content...
        ],
      ),
    );
  }
}
