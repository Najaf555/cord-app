import 'package:flutter/material.dart';

class NewRecordingScreen extends StatelessWidget {
  const NewRecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Bottom navigation and floating pause button
      bottomNavigationBar: BottomNavigationBar(
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
        currentIndex: 1, // Sessions tab selected by default
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/sessions');
          } else if (index == 1) {
            // Already on Sessions (New Recording)
          } else if (index == 2) {
            Navigator.of(context).pushReplacementNamed('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Sessions'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Bookmarks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                    onPressed: () {},
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black54),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Fill remaining space
            const Expanded(child: SizedBox()),
          ],
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
