import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';
import 'dart:async';
import 'save.recording.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audioplayers/audioplayers.dart' as ap;

class PausedRecording extends StatefulWidget {
  final VoidCallback? onNext;
  final bool showSaveScreenAtEnd;
  final String? recordingFilePath;
  const PausedRecording({
    super.key, 
    this.onNext, 
    this.showSaveScreenAtEnd = false,
    this.recordingFilePath,
  });

  @override
  State<PausedRecording> createState() => _PausedRecordingState();
}

class _PausedRecordingState extends State<PausedRecording> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = false;
  Timer? _timer;
  double _elapsedSeconds = 0.0;
  String _recordingFileName = 'New Recording';
  final TextEditingController _fileNameController = TextEditingController();
  bool _showCenterButton = true;

  // Loading indicator for permission
  bool _isRequestingPermission = true;
  bool _hasPermission = false;

  // just_audio player for playback
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  bool _isAudioPlaying = false;
  // flutter_sound for recording only
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isAudioRecording = false;
  String? _recordingPath;

  // just_audio player for playback (if needed elsewhere)
  // audioplayers for test
  final ap.AudioPlayer _testAudioPlayer = ap.AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    ); // Do NOT start animation here
    
    // If we have a recording file path, we can potentially get the actual duration
    // For now, we'll start with 0 and let the user see the timer as they interact
    if (widget.recordingFilePath != null) {
      // You could add logic here to get the actual audio file duration
      // For now, we'll start with 0 and let the timer run
      _elapsedSeconds = 0.0;
    }

   _audioRecorder.openRecorder();
_requestMicrophonePermissionAndStart();
    _audioRecorder.openRecorder();
    _requestMicrophonePermissionAndStart();
  }

  Future<void> _requestMicrophonePermissionAndStart() async {
    // Stop and reset everything BEFORE showing permission dialog
    _controller.stop();
    _controller.value = 0.0;
    _timer?.cancel();
    _elapsedSeconds = 0.0;
    setState(() { _isRequestingPermission = true; });

    final status = await Permission.microphone.request();

    if (status.isGranted) {
      setState(() { _hasPermission = true; });
      await _startAudioRecording();
      _controller.repeat();
      _startTimer();
    } else {
      setState(() { _hasPermission = false; });
      // Already stopped and reset above
      Get.snackbar(
        'Permission Required',
        'Microphone permission is required to record audio.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    setState(() { _isRequestingPermission = false; });
  }

  Future<String> _getRecordingSavePath() async {
    final directory = await getApplicationDocumentsDirectory(); // App directory, safe for all platforms
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'paused_recording_$timestamp.m4a';
    return '${directory.path}/$fileName';
  }

  Future<void> _pauseRecordingAndSave() async {
    if (_isAudioRecording) {
      await _audioRecorder.stopRecorder();
      setState(() {
        _isAudioRecording = false;
      });
      // Show a small message when the temp file is saved
      if (_recordingPath != null) {
        Get.snackbar(
          'Recording Saved',
          'Temporary recording file saved.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  // Update _startAudioRecording to use the app directory
  Future<void> _startAudioRecording() async {
    try {
      final filePath = await _getRecordingSavePath();
      _recordingPath = filePath; // Save temp recording file path
      await _audioRecorder.startRecorder(
        toFile: _recordingPath!,
        codec: Codec.aacMP4,
      );
      setState(() {
        _isAudioRecording = true;
      });
    } catch (e) {
      print('Error starting audio recording: $e');
      Get.snackbar(
        'Recording Error',
        'Failed to start audio recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      if (_isAudioRecording) {
        await _audioRecorder.stopRecorder();
        setState(() {
          _isAudioRecording = false;
        });
      }
    } catch (e) {
      print('Error stopping audio recording: $e');
    }
  }

  void _startTimer() {
    setState(() {
      _isPlaying = true;
      _showCenterButton = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_isPlaying) return;
      setState(() {
        _elapsedSeconds += 0.03;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _audioPlayer.dispose(); // just_audio cleanup
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  // Pause logic: stop and save recording
  Future<void> _onPausePressed() async {
    await _pauseRecordingAndSave(); // This will stop and ensure _recordingPath is set
    setState(() {
      _isPlaying = false;
      _isAudioRecording = false;
      // Do NOT reset _elapsedSeconds
    });
  }

  // Play Back logic: play from saved temp file, do NOT reset timer
  Future<void> _onPlayPressed() async {
    if (_isAudioRecording) {
      await _pauseRecordingAndSave();
    }
    final tempPath = _recordingPath;
    if (tempPath == null || !File(tempPath).existsSync()) {
      Get.snackbar('No Recording', 'No recording file found to play.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    setState(() {
      _isAudioPlaying = true;
      _isPlaying = true;
      _showCenterButton = false;
    });
    try {
      await _testAudioPlayer.play(ap.DeviceFileSource(tempPath));
      _testAudioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isAudioPlaying = false;
          _isPlaying = false;
        });
      });
    } catch (e) {
      setState(() {
        _isAudioPlaying = false;
        _isPlaying = false;
      });
      Get.snackbar('Playback Error', 'Failed to play audio: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // Continue logic: resume timer from stopped state
  void _onContinuePressed() {
    if (!_isPlaying) {
      setState(() {
        _isPlaying = true;
      });
      _controller.repeat();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        setState(() {
          _elapsedSeconds += 0.03;
        });
      });
    }
  }

  Future<void> _onStopPlayback() async {
    await _testAudioPlayer.stop();
    setState(() {
      _isAudioPlaying = false;
      _isPlaying = false;
    });
  }

  String _formatElapsed(double seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds.toInt() % 60;
    final int ms = ((seconds - seconds.floor()) * 100).toInt();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}' ;
  }

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    if (_isRequestingPermission) {
      // Timer and waveform are not built, and are at zero
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasPermission) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Microphone permission is required to record.'),
        ),
      );
    }

    // Only here, after permission is granted, build timer and waveform
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
                            children: [
                              Text(
                                _recordingFileName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Edit file name',
                                child: GestureDetector(
                                  onTap: () async {
                                     print('🟢 Edit icon tapped'); // ✅ Debug print
                                    _fileNameController.text = _recordingFileName;
                                    String? errorText;
                                    final result = await showDialog<String>(
                                      context: context,
                                      barrierDismissible: false, // User must tap Save or Cancel
                                      builder: (context) {
                                        return StatefulBuilder(
                                          builder: (context, setState) {
                                            return AlertDialog(
                                              backgroundColor: Colors.white, // Pure white background
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.zero, // Sharp corners
                                              ),
                                              insetPadding: EdgeInsets.zero, // Remove default dialog padding
                                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Minimal padding
                                              titlePadding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 0),
                                              actionsPadding: EdgeInsets.only(left: 0, right: 0, bottom: 16, top: 8),
                                              title: const Text('Recording Name', style: TextStyle(fontSize: 16)),
                                              content: TextField(
                                                controller: _fileNameController,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.zero, // Sharp corners
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.zero,
                                                    borderSide: BorderSide(color: Colors.grey),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.zero,
                                                    borderSide: BorderSide(color: Colors.black),
                                                  ),
                                                  errorText: errorText,
                                                  fillColor: Colors.white,
                                                  filled: true,
                                                ),
                                                style: const TextStyle(fontSize: 22),
                                                autofocus: true,
                                              ),
                                              actions: [
                                                Center(
                                                  child: OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      foregroundColor: Colors.black,
                                                      side: const BorderSide(
                                                        width: 2,
                                                        color: Color(0xFFFF9800), // Orange border (can use gradient if needed)
                                                      ),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                                      textStyle: const TextStyle(fontSize: 20),
                                                    ),
                                                    onPressed: () {
                                                      final trimmed = _fileNameController.text.trim();
                                                      if (trimmed.isEmpty) {
                                                        setState(() {
                                                          errorText = 'File name cannot be empty';
                                                        });
                                                      } else {
                                                        Navigator.of(context).pop(trimmed);
                                                      }
                                                    },
                                                    child: const Text('Save'),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                    if (result != null && result.isNotEmpty) {
                                      setState(() {
                                        _recordingFileName = result;
                                      });
                                    }
                                  },
                                  child: const Icon(
                                    Icons.edit,
                                    size: 18, // Larger size for better visibility
                                    color: Color.fromARGB(255, 253, 162, 27),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SaveRecordingScreen(
                              timerValue: _formatElapsed(_elapsedSeconds),
                              recordingFilePath: widget.recordingFilePath ?? _recordingPath,
                              recordingFileName: _recordingFileName,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Next',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatElapsed(_elapsedSeconds),
                style: const TextStyle(
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
                            painter: _WaveformPainter(
                              phase: _isPlaying ? _controller.value : 0.0,
                            ),
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
                child: Visibility(
                  visible: !_showCenterButton,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IgnorePointer(
                        ignoring: true,
                        child: _buildControlButton(
                          icon: _isAudioPlaying ? Icons.stop : Icons.play_arrow,
                          label: _isAudioPlaying ? 'Stop' : 'Play back',
                          onPressed: _isAudioPlaying ? _onStopPlayback : _onPlayPressed,
                          iconColor: _isAudioPlaying ? Colors.red : Colors.blue,
                          textColor: _isAudioPlaying ? Colors.red : Colors.blue,
                        ),
                      ),
                      _buildControlButton(
                        icon: Icons.fiber_manual_record_outlined,
                        label: 'Continue',
                        onPressed: _onContinuePressed,
                        iconColor: Colors.red,
                        textColor: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Visibility(
          visible: !_showCenterButton,
          child: SizedBox(
            height: 64,
            width: 64,
            child: FloatingActionButton(
              onPressed: _onPausePressed,
              elevation: 0,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
              shape: const CircularNotchedRectangle(),
              notchMargin: 6,
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
    required VoidCallback? onPressed,
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
