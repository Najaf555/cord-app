import 'dart:async';

import 'package:Cord/views/save.recording.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/azure_storage_service.dart';
import '../utils/audio_combine_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

/*
 * Recording Document Structure:
 * - userId: String (Firebase Auth UID)
 * - fileUrl: String (Azure Blob Storage HTTPS URL)
 * - duration: String (formatted as MM:SS.ms)
 * - createdAt: Timestamp (server timestamp)
 * - recordingId: String (Firestore document ID)
 * - fileName: String (e.g., "recording_1234567890.m4a")
 * 
 * File naming convention: recording_[timestamp].m4a
 * 
 * ✅ IMPLEMENTED FEATURES:
 * - Automatic filename generation (no user input required)
 * - Complete document structure with all required fields
 * - Azure Blob Storage upload with public HTTPS URL
 * - Firestore document creation under sessions/6xfhQsVPQkTGCeFDfcIt/recordings
 * - Document verification and logging
 */

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
  final bool _isPlayingBack = false;
  
  // Audio recording variables
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isAudioRecording = false;
  String? _recordingPath;
  bool _hasPermission = false;
  // Add a new state variable to track if we are in the paused controls state
  bool _showPausedControls = false;
  String? _playbackSnapshotPath;
  List<String> _segmentPaths = [];
  int _segmentIndex = 0;
  String? _currentSegmentPath;

  // Session title variable for editing
  String _sessionTitle = 'Free Falling v2';
  String _recordingFileName = 'New Recording';

  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        setState(() {});
      });
    _segmentPaths = [];
    _segmentIndex = 0;
    _startNewSegment();
    _startRecording();
    
    // Test FFmpeg integration
    _testFFmpegIntegration();
  }

  Future<void> _testFFmpegIntegration() async {
    try {
      final isWorking = await AudioCombineService.testIntegration();
      print('🎵 FFmpeg integration test: ${isWorking ? "SUCCESS" : "FAILED"}');
    } catch (e) {
      print('🎵 FFmpeg integration test error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _audioRecorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Start a new segment (called on start and resume)
  Future<void> _startNewSegment() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final segmentPath = '${directory.path}/segment_${_segmentIndex++}.m4a';
      _currentSegmentPath = segmentPath;
      await _audioRecorder.openRecorder();
      await _audioRecorder.startRecorder(
        toFile: segmentPath,
        codec: Codec.aacMP4,
      );
      setState(() {
        _isAudioRecording = true;
      });
      print('Started new segment: $segmentPath');
    } catch (e) {
      print('Error starting new segment: $e');
      Get.snackbar(
        'Recording Error',
        'Failed to start new segment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Stop the current segment (called on pause and final stop)
  Future<void> _stopCurrentSegment() async {
    try {
      if (_isAudioRecording) {
        final path = await _audioRecorder.stopRecorder();
        await _audioRecorder.closeRecorder();
        setState(() {
          _isAudioRecording = false;
        });
        if (path != null) {
          _currentSegmentPath = path;
          _segmentPaths.add(path);
          print('Stopped segment: $path');
        }
      }
    } catch (e) {
      print('Error stopping segment: $e');
    }
  }

  // On pause, stop the current segment
  void _pauseRecording() async {
    setState(() {
      _isPaused = true;
      _isRecording = false;
      _showPausedControls = true;
    });
    _controller.stop();
    _timer?.cancel();
    await _stopCurrentSegment();
  }

  // On resume, start a new segment
  void _resumeRecording() async {
    setState(() {
      _isPaused = false;
      _isRecording = true;
      _showPausedControls = false;
    });
    await _startNewSegment();
    _controller.repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _elapsedSeconds += 0.03;
      });
    });
  }

  // On start, start the first segment
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

  // On final stop, stop the current segment
  Future<void> _stopAudioRecording() async {
    await _stopCurrentSegment();
  }

  // Playback: play all segments in order
  void _playback() async {
    if (_segmentPaths.isEmpty) {
      Get.snackbar(
        'No Recording',
        'No recording segments found to play.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    final sources = <ja.AudioSource>[];
    for (final path in _segmentPaths) {
      if (File(path).existsSync()) {
        final file = File(path);
        final fileSize = await file.length();
        if (fileSize > 44) {
          sources.add(ja.AudioSource.uri(Uri.file(path)));
        }
      }
    }
    if (sources.isEmpty) {
      Get.snackbar(
        'Empty Recording',
        'No playable segments found.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    try {
      await _audioPlayer.setAudioSource(ja.ConcatenatingAudioSource(children: sources));
      await _audioPlayer.play();
      setState(() {
        _isAudioPlaying = true;
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ja.ProcessingState.completed) {
          setState(() {
            _isAudioPlaying = false;
          });
        }
      });
    } catch (e) {
      print('Playback error: $e');
      Get.snackbar(
        'Playback Error',
        'Failed to play recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    
    if (_hasPermission) {
      await _startAudioRecording();
    } else {
      Get.snackbar(
        'Permission Required',
        'Microphone permission is required to record audio.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Refactor: Only start recording and create the file when paused (not at start)
  Future<void> _startAudioRecording() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'recording_$timestamp.m4a';
        _recordingPath = '${directory.path}/$fileName';
        print('Generated recording file:');
        print('- File name: $fileName');
        print('- Full path: $_recordingPath');
        print('- Timestamp: $timestamp');
        await _audioRecorder.openRecorder();
        await _audioRecorder.startRecorder(
          toFile: _recordingPath!,
          codec: Codec.aacMP4,
        );
        setState(() {
          _isAudioRecording = true;
        });
        print('Audio recording started at: $_recordingPath');
        print('Generated file name: $fileName');
        print('File name format: recording_$timestamp.m4a');
      } else {
        Get.snackbar(
          'Permission Required',
          'Microphone permission is required to record audio.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
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

  Future<void> _saveRecordingToDownloads() async {
    if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
      Get.snackbar(
        'No Recording',
        'No recording file found to save.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Get the downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = Directory('/storage/emulated/0/Downloads');
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (!downloadsDir.existsSync()) {
        throw Exception('Downloads directory not found');
      }

      // Extract the original file name from the recording path
      final originalFileName = _recordingPath!.split('/').last;
      final destinationPath = '${downloadsDir.path}/$originalFileName';

      // Copy the recording file to downloads
      await File(_recordingPath!).copy(destinationPath);

      Get.snackbar(
        'Recording Saved Successfully',
        'Recording saved to Downloads folder as $originalFileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      print('Recording saved to: $destinationPath');
    } catch (e) {
      print('Error saving recording: $e');
      Get.snackbar(
        'Save Error',
        'Failed to save recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
        floatingActionButton: !_showPausedControls
            ? Visibility(
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
              )
            : null,
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
                            Text(
                              _sessionTitle, // Use a variable for the session title
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _recordingFileName,
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async {
                                final controller = TextEditingController(text: _recordingFileName);
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Edit Recording Name'),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Recording Name',
                                          border: OutlineInputBorder(),
                                        ),
                                        autofocus: true,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            final newName = controller.text.trim();
                                            if (newName.isNotEmpty) {
                                              Navigator.of(context).pop(newName);
                                            }
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (result != null && result.isNotEmpty) {
                                  setState(() {
                                    _recordingFileName = result;
                                  });
                                }
                              },
                              child: Icon(Icons.edit, size: 18, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        await _stopAudioRecording();
                        
                        // Check if we have recording segments to combine
                        if (_segmentPaths.isEmpty) {
                          Get.snackbar(
                            'No Recording',
                            'No recording segments found to save.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        // Show loading indicator
                        Get.dialog(
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                          barrierDismissible: false,
                        );

                        try {
                          // Validate input files
                          final isValid = await AudioCombineService.validateInputFiles(_segmentPaths);
                          if (!isValid) {
                            Get.back(); // Close loading dialog
                            Get.snackbar(
                              'Invalid Files',
                              'Some recording segments are invalid or missing.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Check if segments are ready for upload
                          final areReady = await AudioCombineService.areSegmentsReadyForUpload(_segmentPaths);
                          if (!areReady) {
                            Get.back(); // Close loading dialog
                            Get.snackbar(
                              'Segments Not Ready',
                              'Some recording segments are not ready for upload.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Get primary recording file (first segment)
                          final primaryFilePath = await AudioCombineService.getPrimaryRecordingFile(_segmentPaths);
                          if (primaryFilePath == null) {
                            Get.back(); // Close loading dialog
                            Get.snackbar(
                              'No Primary File',
                              'No primary recording file found.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          // Get recording metadata
                          final metadata = await AudioCombineService.getRecordingMetadata(_segmentPaths);
                          
                          print('🎵 Processing recording segments...');
                          print('🎵 Total segments: ${_segmentPaths.length}');
                          print('🎵 Primary file: $primaryFilePath');

                          // 1. Upload primary file to Azure
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw Exception('User not logged in');
                          
                          final fileName = primaryFilePath.split('/').last;
                          final blobName = 'recordings/${user.uid}/$fileName';
                          final file = File(primaryFilePath);
                          final fileUrl = await AzureStorageService.uploadFile(file, blobName);
                          
                          // Clean up temporary segment files
                          await AudioCombineService.cleanupTempFiles(_segmentPaths);
                          
                          Get.back(); // Close loading dialog
                          Get.snackbar(
                            'Success',
                            'Recording uploaded to Azure successfully! (${_segmentPaths.length} segments)',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                          
                          if (widget.showSaveScreenAtEnd) {
                            Navigator.of(context).pop();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => SaveRecordingScreen(
                                azureFileUrl: fileUrl,
                                timerValue: _formatElapsed(_elapsedSeconds),
                                fileName: fileName,
                                recordingMetadata: metadata,
                              ),
                            );
                          } else {
                            int pops = 0;
                            Navigator.of(context, rootNavigator: true).popUntil((route) {
                              pops++;
                              return pops == 2;
                            });
                          }
                        } catch (e) {
                          Get.back(); // Close loading dialog
                          print('Error processing and uploading recording: $e');
                          Get.snackbar(
                            'Error',
                            'Failed to process and upload recording: $e',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatElapsed(_elapsedSeconds),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  if (_isAudioRecording) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'REC',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
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
              if (_showPausedControls)
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

  Future<void> _doneAndSaveRecording() async {
    await _stopAudioRecording();
    if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
      Get.snackbar(
        'No Recording',
        'No recording file found to save.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final fileName = _recordingPath!.split('/').last;
      final blobName = 'recordings/${user.uid}/$fileName';
      final file = File(_recordingPath!);
      final fileUrl = await AzureStorageService.uploadFile(file, blobName);
      final recordingsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc('6xfhQsVPQkTGCeFDfcIt')
        .collection('recordings');
      final docRef = await recordingsRef.add({
        'userId': user.uid,
        'fileUrl': fileUrl,
        'duration': _formatElapsed(_elapsedSeconds),
        'createdAt': FieldValue.serverTimestamp(),
        'fileName': fileName,
      });
      await recordingsRef.doc(docRef.id).update({
        'recordingId': docRef.id,
      });
      Get.snackbar(
        'Success',
        'Recording uploaded and saved!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Navigator.of(context).pop(); // Close the recording screen
    } catch (e) {
      print('Error uploading or saving recording: $e');
      Get.snackbar(
        'Error',
        'Failed to upload/save recording: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
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
