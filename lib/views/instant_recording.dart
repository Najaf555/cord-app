import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'paused_recording.dart';

class InstantRecording extends StatefulWidget {
  const InstantRecording({super.key});

  @override
  _InstantRecordingState createState() => _InstantRecordingState();
}

class _InstantRecordingState extends State<InstantRecording> {
  final NavigationController navController = Get.find<NavigationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
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
          // Top bar
          Stack(
            children: [
              // Next button at absolute top right
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                            child: Scaffold(
                              backgroundColor: Colors.white,
                              body: PausedRecording(),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Centered title and subtitle
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'New Session',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'New Recording',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.edit, size: 16, color: Colors.black54),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Timer
          Text(
            '00:06.67',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 12),
          // Waveform and blue arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 1.5),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 180,
                      height: 60,
                      child: CustomPaint(
                        painter: _WaveformPainter(),
                      ),
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
          ),
          SizedBox(height: 32),
          // Bookmark button and share icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {},
                icon: Icon(Icons.bookmark_border, color: Colors.black, size: 22),
                label: Text(
                  'Set Bookmark',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(width: 24),
              IconButton(
                icon: Icon(Icons.ios_share, color: Colors.blue, size: 28),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 24),
          // Pause icon in the center slot
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, 1), // Center bottom
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Image.asset(
                  'assets/images/linepause.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Stack(
        children: [
          // Top border line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, color: Color(0xFFE0E0E0)),
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
                  selectedItemColor: Color(0xFF222222),
                  unselectedItemColor: Color(0xFFBDBDBD),
                  selectedLabelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                  currentIndex: navController.selectedIndex.value,
                  onTap: (index) {
                    Navigator.of(context).pop(); // Close modal
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
    );
  }
}

// Placeholder waveform painter
class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // Draw a simple waveform
    final points = [
      Offset(0, size.height / 2),
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.2),
      Offset(size.width, size.height / 2),
    ];
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
