import 'package:flutter/material.dart';

class PausedRecording extends StatelessWidget {
  const PausedRecording({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24), // Placeholder for symmetry
                  Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'New Session',
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
                      'Next',
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
                          icon: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
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
                          icon: const Icon(Icons.fiber_manual_record, color: Colors.red, size: 32),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Continue', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom navigation bar
            Container(
              height: 72,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavButton(
                    icon: Icons.folder,
                    label: 'Sessions',
                    onTap: () {},
                    selected: false,
                  ),
                  _BottomNavButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {},
                    selected: false,
                  ),
                ],
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

class _BottomNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? iconColor;

  const _BottomNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor ?? (selected ? Colors.black : Colors.black54),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.black54,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
