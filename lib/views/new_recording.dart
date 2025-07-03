import 'dart:async';

import 'package:Cord/views/save.recording.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'paused_recording.dart';
import '../controllers/navigation_controller.dart';

class NewRecordingScreen extends StatefulWidget {
  final bool showSaveScreenAtEnd;
  const NewRecordingScreen({super.key, this.showSaveScreenAtEnd = false});

  @override
  State<NewRecordingScreen> createState() => _NewRecordingScreenState();
}

class _NewRecordingScreenState extends State<NewRecordingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRecording = false;
  Timer? _timer;
  double _elapsedSeconds = 0.0;
  bool _isPaused = false;
  bool _isPlayingBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        setState(() {});
      });
    // Start recording automatically
    _startRecording();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    _controller.repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _elapsedSeconds += 0.03;
      });
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _controller.stop();
    _timer?.cancel();
  }

  void _pauseRecording() {
    setState(() {
      _isPaused = true;
      _isRecording = false;
    });
    _controller.stop();
    _timer?.cancel();
  }

  void _resumeRecording() {
    setState(() {
      _isPaused = false;
      _isRecording = true;
    });
    _controller.repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _elapsedSeconds += 0.03;
      });
    });
  }

  void _playback() {
    setState(() {
      _isPlayingBack = !_isPlayingBack;
    });
    // Placeholder: show a SnackBar for playback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPlayingBack ? 'Playing back recording...' : 'Playback stopped.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatElapsed(double seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds.toInt() % 60;
    final int ms = ((seconds - seconds.floor()) * 100).toInt();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}' ;
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
        floatingActionButton: Visibility(
          visible: !_isPaused,
          child: SizedBox(
            height: 64,
            width: 64,
            child: FloatingActionButton(
              onPressed: () {
                if (_isRecording) {
                  _pauseRecording();
                }
              },
              elevation: 0,
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              child: Image.asset(
                'assets/images/linemdpause.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
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
                        if (widget.showSaveScreenAtEnd) {
                          Navigator.of(context).pop(); // Dismiss NewRecordingScreen
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const SaveRecordingScreen(),
                          );
                        } else {
                          // Pop two routes (close both new_recording and previous sheet)
                          int pops = 0;
                          Navigator.of(context, rootNavigator: true).popUntil((route) {
                            pops++;
                            return pops == 2;
                          });
                        }
                      },
                      child: Text(
                        widget.showSaveScreenAtEnd ? 'Next' : 'Done',
                        style: const TextStyle(
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
              Text(
                _formatElapsed(_elapsedSeconds),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              // Waveform and blue arrow (animated, matches paused_recording)
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: const Color(0xFFF5F5F5),
                    child: Center(
                      child: Container(
                        width: 180,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 1.5),
                        ),
                        child: CustomPaint(
                          painter: _WaveformPainter(phase: _isRecording ? _controller.value : 0.0),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: -8,
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
              // Add Stop/Continue buttons at the bottom, above the nav bar
              const Spacer(),
              if (_isPaused)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.play_arrow,
                        label: 'Play back',
                        onPressed: _playback,
                        iconColor: Colors.black,
                        textColor: Colors.black,
                      ),
                      _buildControlButton(
                        icon: Icons.fiber_manual_record_outlined,
                        label: 'Continue',
                        onPressed: _resumeRecording,
                        iconColor: Colors.red,
                        textColor: Colors.black,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated waveform painter from paused_recording.dart
class _WaveformPainter extends CustomPainter {
  final double phase;
  _WaveformPainter({this.phase = 0.0});

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

    // Animate the waveform by shifting the bars horizontally based on phase
    final shift = (phase * heights.length) % heights.length;
    for (int i = 0; i < heights.length; i++) {
      // Calculate shifted index for animation
      int shiftedIndex = (i + shift.toInt()) % heights.length;
      final x = barWidth * (i * 1.8);
      final barHeight = heights[shiftedIndex].toDouble();
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.phase != phase;
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
