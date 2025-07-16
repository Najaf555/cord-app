import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PausedRecording extends StatefulWidget {
  final String? recordingFilePath;
  final String? recordingDocId;
  final String? recordingName;
  final String? sessionName;
  final String? sessionId;
  
  const PausedRecording({
    super.key, 
    this.recordingFilePath,
    this.recordingDocId,
    this.recordingName,
    this.sessionName,
    this.sessionId,
  });

  @override
  State<PausedRecording> createState() => _PausedRecordingState();
}

class _PausedRecordingState extends State<PausedRecording> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = false;
  Timer? _timer;
  double _elapsedSeconds = 0.0;
  String _recordingFileName = '';
  String? _recordingFileUrl;
  final TextEditingController _fileNameController = TextEditingController();
  bool _showCenterButton = true;

  // just_audio player for playback
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  bool _isAudioPlaying = false;
  String? _recordingCreatorId;
  bool _isCurrentUserCreator = false;
  bool _loadingCreator = true;
  bool _loadingRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    // If we have a recordingDocId and sessionId, fetch the recording document
    if (widget.recordingDocId != null && widget.sessionId != null) {
      _loadingRecording = true;
      FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('recordings')
          .doc(widget.recordingDocId)
          .get()
          .then((doc) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _recordingFileName = data['name'] ?? data['fileName'] ?? 'New Recording';
            _recordingFileUrl = data['fileUrl'];
            _fileNameController.text = _recordingFileName;
            _loadingRecording = false;
          });
        } else {
          setState(() {
            _recordingFileName = 'New Recording';
            _recordingFileUrl = null;
            _fileNameController.text = _recordingFileName;
            _loadingRecording = false;
          });
        }
      });
    } else {
      _recordingFileName = widget.recordingName ?? 'New Recording';
      _fileNameController.text = _recordingFileName;
    }

    // If we have a recording file path, we can potentially get the actual duration
    if (widget.recordingFilePath != null) {
      _elapsedSeconds = 0.0;
    }

    // Listen to audio player position for playback progress
    _audioPlayer.positionStream.listen((position) {
      if (_isAudioPlaying) {
        setState(() {
          _elapsedSeconds = position.inMilliseconds / 1000.0;
        });
      }
    });
    // Listen for audio player state changes ONCE
    _audioPlayer.playerStateStream.listen((state) {
      if (state.playing && state.processingState == just_audio.ProcessingState.ready) {
        if (!_isPlaying) {
          setState(() {
            _isPlaying = true;
          });
          _controller.reset();
          _controller.repeat();
        }
      } else {
        if (_isPlaying) {
          setState(() {
            _isPlaying = false;
          });
          _controller.stop();
        }
      }
    });
    _fetchRecordingCreator();
  }

  Future<void> _fetchRecordingCreator() async {
    if (widget.sessionId == null || widget.recordingDocId == null) {
      setState(() {
        _loadingCreator = false;
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('recordings')
          .doc(widget.recordingDocId)
          .get();
      final data = doc.data();
      final userId = data != null ? data['userId'] as String? : null;
      final currentUser = await _getCurrentUserId();
      setState(() {
        _recordingCreatorId = userId;
        _isCurrentUserCreator = (userId != null && currentUser != null && userId == currentUser);
        _loadingCreator = false;
      });
    } catch (e) {
      setState(() {
        _loadingCreator = false;
      });
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  // Play Back logic: play from Azure URL
  Future<void> _onPlayPressed() async {
    final recordingPath = _recordingFileUrl ?? widget.recordingFilePath;
    if (recordingPath == null) {
      Get.snackbar('No Recording', 'No recording found to play.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    
    setState(() {
      _isAudioPlaying = true;
      _showCenterButton = false;
    });
    
    try {
      // Only set URL if player is idle or completed
      if (_audioPlayer.processingState == just_audio.ProcessingState.idle || 
          _audioPlayer.processingState == just_audio.ProcessingState.completed) {
        await _audioPlayer.setUrl(recordingPath);
      }
      await _audioPlayer.play();
      
    } catch (e) {
      setState(() {
        _isAudioPlaying = false;
        _isPlaying = false;
      });
      _controller.stop();
      Get.snackbar('Playback Error', 'Failed to play audio: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // Pause logic: pause playback
  Future<void> _onPausePressed() async {
    setState(() {
      _isAudioPlaying = false;
      _showCenterButton = true;
    });
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  // Continue logic: resume timer from stopped state
  void _onContinuePressed() {
    if (!_isPlaying) {
      setState(() {
        _isPlaying = true;
      });
      _controller.reset();
      _controller.repeat();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        setState(() {
          _elapsedSeconds += 0.03;
        });
      });
    }
  }

  Future<void> _onStopPlayback() async {
    try {
      await _audioPlayer.stop();
      _controller.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
    setState(() {
      _isAudioPlaying = false;
      _isPlaying = false;
    });
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

  String _formatElapsed(double seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds.toInt() % 60;
    final int ms = ((seconds - seconds.floor()) * 100).toInt();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }

  // Update recording name in Firestore
  Future<void> _updateRecordingNameInFirestore(String newName) async {
    if (widget.recordingDocId == null) {
      print('No recording document ID available');
      return;
    }

    if (widget.sessionId == null) {
      print('No session ID available');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('recordings')
          .doc(widget.recordingDocId)
          .update({
        'name': newName,
      });
      print('Recording name updated successfully in Firestore');
      Get.snackbar(
        'Success',
        'Recording name updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error updating recording name in Firestore: $e');
      Get.snackbar(
        'Error',
        'Failed to update recording name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 60), // Balance the Done button
                        Expanded(
                          child: Text(
                            widget.sessionName ?? 'New Session',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Dismiss the bottom sheet modal
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Done',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 47, 142, 238),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Centered recording name with edit icon
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: _loadingRecording
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _recordingFileName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                          ),
                          const SizedBox(width: 8),
                          if (_loadingCreator)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_isCurrentUserCreator)
                            Tooltip(
                              message: 'Edit file name',
                              child: GestureDetector(
                                onTap: () async {
                                  print('🟢 Edit icon tapped');
                                  _fileNameController.text = _recordingFileName;
                                  String? errorText;
                                  final result = await showDialog<String>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return Dialog(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Recording Name',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 24),
                                                  TextField(
                                                    controller: _fileNameController,
                                                    textAlign: TextAlign.center,
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.zero,
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
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 16,
                                                      ),
                                                    ),
                                                    style: const TextStyle(fontSize: 15),
                                                    autofocus: true,
                                                  ),
                                                  const SizedBox(height: 24),
                                                  GestureDetector(
                                                    onTap: () {
                                                      final trimmed = _fileNameController.text.trim();
                                                      if (trimmed.isEmpty) {
                                                        setState(() {
                                                          errorText = 'File name cannot be empty';
                                                        });
                                                      } else {
                                                        Navigator.of(context).pop(trimmed);
                                                      }
                                                    },
                                                    child: Center(
                                                      child: Container(
                                                        width: 120,
                                                        height: 40,
                                                        padding: EdgeInsets.zero,
                                                        child: Stack(
                                                          children: [
                                                            // Gradient border
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.zero,
                                                                gradient: const LinearGradient(
                                                                  colors: [
                                                                    Color(0xFFFFA726), // orange
                                                                    Color(0xFFE040FB), // pink
                                                                  ],
                                                                  begin: Alignment.centerLeft,
                                                                  end: Alignment.centerRight,
                                                                ),
                                                              ),
                                                            ),
                                                            // Inner white container with margin for border effect
                                                            Container(
                                                              margin: const EdgeInsets.all(1.5), // Border thickness
                                                              decoration: const BoxDecoration(
                                                                color: Colors.white,
                                                                borderRadius: BorderRadius.zero,
                                                              ),
                                                              alignment: Alignment.center,
                                                              child: const Text(
                                                                'Save',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w400,
                                                                  color: Colors.black,
                                                                ),
                                                              ),
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
                                        },
                                      );
                                    },
                                  );
                                  if (result != null && result.isNotEmpty) {
                                    final newName = result.trim();
                                    if (newName != _recordingFileName) {
                                      setState(() {
                                        _recordingFileName = newName;
                                      });
                                      // Update the recording name in Firestore
                                      await _updateRecordingNameInFirestore(newName);
                                    }
                                  }
                                },
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Color.fromARGB(255, 253, 162, 27),
                                ),
                              ),
                            )
                          else
                            Tooltip(
                              message: 'Only the creator can rename this recording',
                              child: const Icon(
                                Icons.edit_off,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                        ],
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
                    child: Container(
                      width: double.infinity,
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
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 16.0),
              //   child: Visibility(
              //     visible: !_showCenterButton,
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //       children: [
              //         IgnorePointer(
              //           ignoring: true,
              //           child: _buildControlButton(
              //             icon: _isAudioPlaying ? Icons.stop : Icons.play_arrow,
              //             label: _isAudioPlaying ? 'Stop' : 'Play back',
              //             onPressed: _isAudioPlaying ? _onStopPlayback : _onPlayPressed,
              //             iconColor: _isAudioPlaying ? Colors.red : Colors.blue,
              //             textColor: _isAudioPlaying ? Colors.red : Colors.blue,
              //           ),
              //         ),
              //         _buildControlButton(
              //           icon: Icons.fiber_manual_record_outlined,
              //           label: 'Continue',
              //           onPressed: _onContinuePressed,
              //           iconColor: Colors.red,
              //           textColor: Colors.black,
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        floatingActionButton: SizedBox(
          height: 64,
          width: 64,
          child: FloatingActionButton(
            onPressed: _isAudioPlaying ? _onPausePressed : _onPlayPressed,
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
