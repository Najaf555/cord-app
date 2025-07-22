import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/recording_author.dart';
import '../utils/user_colors.dart';
import 'session_detail_view.dart';

const List<Color> userBorderColors = [
  Color(0xFFEB5757), // Red
  Color(0xFF27AE60), // Green
  Color(0xFF2F80ED), // Blue
  Color(0xFFFF833E), // Orange
  Color(0xFF9B51E0), // Purple
  Color(0xFF00B8A9), // Teal
  Color(0xFFFFC542), // Yellow
  Color(0xFF6A89CC), // Indigo
  Color(0xFFB33771), // Pink
  Color(0xFF218c5c), // Dark Green
  Color(0xFFE74C3C), // Bright Red
  Color(0xFF2ECC71), // Emerald
  Color(0xFF3498DB), // Sky Blue
  Color(0xFFF39C12), // Orange
  Color(0xFF8E44AD), // Purple
  Color(0xFF1ABC9C), // Turquoise
  Color(0xFFF1C40F), // Yellow
  Color(0xFF34495E), // Dark Blue
  Color(0xFFE91E63), // Pink
  Color(0xFF795548), // Brown
  Color(0xFF607D8B), // Blue Grey
  Color(0xFF9C27B0), // Deep Purple
  Color(0xFF3F51B5), // Indigo
  Color(0xFF2196F3), // Blue
  Color(0xFF00BCD4), // Cyan
  Color(0xFF009688), // Teal
  Color(0xFF4CAF50), // Green
  Color(0xFF8BC34A), // Light Green
  Color(0xFFCDDC39), // Lime
  Color(0xFFFFEB3B), // Yellow
  Color(0xFFFFC107), // Amber
  Color(0xFFFF9800), // Orange
  Color(0xFFFF5722), // Deep Orange
  Color(0xFF795548), // Brown
  Color(0xFF9E9E9E), // Grey
  Color(0xFF607D8B), // Blue Grey
];

Color getUserColor(String? id, String? name) {
  if (id != null && id.isNotEmpty) {
    return userBorderColors[id.hashCode % userBorderColors.length];
  } else if (name != null && name.isNotEmpty) {
    return userBorderColors[name.hashCode % userBorderColors.length];
  }
  return userBorderColors[0];
}

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
  String? _creatorName;
  String? _creatorProfilePictureUrl;
  bool _isCurrentUserCreator = false;
  bool _loadingCreator = true;
  bool _loadingRecording = false;

  // For SoundCloud-style waveform scrolling
  double _waveformScrollFraction = 0.0; // 0.0=start, 1.0=end
  bool _isDraggingWaveform = false;
  double _draggedSeconds = 0.0;

  // State for adding a bookmark with label
  bool _isAddingBookmark = false;
  double? _pendingBookmarkTime;
  final TextEditingController _bookmarkTextController = TextEditingController();
  String? _selectedUserId; // <-- Add this for filtering

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
          .then((doc) async {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _recordingFileName =
                data['name'] ?? data['fileName'] ?? 'New Recording';
            _recordingFileUrl = data['fileUrl'];
            _fileNameController.text = _recordingFileName;
            _loadingRecording = false;
            _recordingCreatorId = data['userId'];
          });
          if (data['userId'] != null) {
            await _fetchCreatorDetails(data['userId']);
          } else {
            setState(() {
              _creatorName = 'John';
              _creatorProfilePictureUrl = null;
              _loadingCreator = false;
            });
          }
        } else {
          setState(() {
            _recordingFileName = 'New Recording';
            _recordingFileUrl = null;
            _fileNameController.text = _recordingFileName;
            _loadingRecording = false;
            _creatorName = 'John';
            _creatorProfilePictureUrl = null;
            _loadingCreator = false;
          });
        }
      });
    } else {
      _recordingFileName = widget.recordingName ?? 'New Recording';
      _fileNameController.text = _recordingFileName;
      setState(() {
        _creatorName = 'John';
        _creatorProfilePictureUrl = null;
        _loadingCreator = false;
      });
    }

    // If we have a recording file path, we can potentially get the actual duration
    if (widget.recordingFilePath != null) {
      _elapsedSeconds = 0.0;
    }

    // Listen to audio player position for playback progress
    _audioPlayer.positionStream.listen((position) {
      if (_isAudioPlaying && !_isDraggingWaveform) {
        final total = _audioPlayer.duration?.inMilliseconds;
        if (position != null && total != null && total > 0) {
          setState(() {
            _elapsedSeconds = position.inMilliseconds / 1000.0;
            _waveformScrollFraction = position.inMilliseconds / total;
          });
        } else {
          setState(() {
            _elapsedSeconds = 0.0;
            _waveformScrollFraction = 0.0;
          });
        }
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

  @override
  void dispose() {
    _bookmarkTextController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecordingCreator() async {
    if (widget.sessionId != null && widget.recordingDocId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .collection('recordings')
            .doc(widget.recordingDocId)
            .get();
        final data = doc.data();
        final userId = data?['userId'] as String?;
        final currentUser = await _getCurrentUserId();
        if (mounted) {
          setState(() {
            _recordingCreatorId = userId;
            _isCurrentUserCreator =
                (userId != null && currentUser != null && userId == currentUser);
            _loadingCreator = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingCreator = false;
          });
        }
      }
    } else {
      final currentUser = await _getCurrentUserId();
      if (mounted) {
        setState(() {
          _recordingCreatorId = currentUser;
          _isCurrentUserCreator = true;
          _loadingCreator = false;
        });
      }
    }
  }

  Future<void> _fetchCreatorDetails(String userId) async {
    setState(() {
      _loadingCreator = true;
    });
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _creatorName = data?['firstName'] ?? '';
          _creatorProfilePictureUrl = data?['imageUrl'];
          _loadingCreator = false;
        });
      } else {
        setState(() {
          _creatorName = '';
          _creatorProfilePictureUrl = null;
          _loadingCreator = false;
        });
      }
    } catch (e) {
      setState(() {
        _creatorName = 'Error';
        _creatorProfilePictureUrl = null;
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

  // Add this function to handle adding a bookmark to Firestore
  Future<void> _addBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    final sessionId = widget.sessionId;
    final recordingDocId = widget.recordingDocId;
    final bookmarkTime = _isDraggingWaveform ? _draggedSeconds : _elapsedSeconds;
    if (user == null || sessionId == null || recordingDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user/session/recording info'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('recordings')
          .doc(recordingDocId)
          .collection('bookmarks')
          .add({
        'userId': user.uid,
        'created_at': FieldValue.serverTimestamp(),
        'bookmark_time': bookmarkTime,
        'recording_id': recordingDocId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark added!'), backgroundColor: Colors.green),
      );
      // Optionally: update local bookmarks list here
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add bookmark: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Add this function to handle adding a bookmark to Firestore
  Future<void> _addBookmarkWithLabel(String label, double bookmarkTime) async {
    final user = FirebaseAuth.instance.currentUser;
    final sessionId = widget.sessionId;
    final recordingDocId = widget.recordingDocId;
    if (user == null || sessionId == null || recordingDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing user/session/recording info'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('recordings')
          .doc(recordingDocId)
          .collection('bookmarks')
          .add({
        'userId': user.uid,
        'created_at': FieldValue.serverTimestamp(),
        'bookmark_time': bookmarkTime,
        'recording_id': recordingDocId,
        'label': label,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark added!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add bookmark: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Helper to fetch user names for a list of userIds
  Future<Map<String, String>> _fetchUserNames(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();
    final Map<String, String> userNames = {};
    for (final doc in usersSnap.docs) {
      userNames[doc.id] = doc.data()['firstName'] ?? doc.id;
    }
    return userNames;
  }

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
              .collection('sessions')
              .doc(widget.sessionId)
              .collection('recordings')
              .doc(widget.recordingDocId)
              .collection('bookmarks')
              .orderBy('bookmark_time')
              .snapshots(),
            builder: (context, snapshot) {
              final bookmarks = snapshot.hasData ? snapshot.data!.docs : [];
              return ListView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 100),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                              _loadingCreator
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : _isCurrentUserCreator
                                      ? Tooltip(
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
                                      : Tooltip(
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
                  if (_loadingCreator)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[400],
                          backgroundImage: _creatorProfilePictureUrl != null &&
                                  _creatorProfilePictureUrl!.isNotEmpty
                              ? NetworkImage(_creatorProfilePictureUrl!)
                              : null,
                          child: _creatorProfilePictureUrl == null ||
                                  _creatorProfilePictureUrl!.isEmpty
                              ? Text(
                                  _creatorName != null && _creatorName!.isNotEmpty
                                      ? _creatorName![0].toUpperCase()
                                      : 'J',
                                  style: const TextStyle(fontSize: 24, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _creatorName ?? 'John',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatElapsed(_isDraggingWaveform ? _draggedSeconds : _elapsedSeconds),
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  // Waveform
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (details) {
                      setState(() {
                        _isDraggingWaveform = true;
                      });
                    },
                    onHorizontalDragUpdate: (details) async {
                      final box = context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(details.globalPosition);
                      final waveformWidth = box.size.width;
                      final x = localPosition.dx.clamp(0.0, waveformWidth);
                      final totalDuration = _audioPlayer.duration;
                      if (totalDuration != null && totalDuration.inMilliseconds > 0) {
                        final percent = 1.0 - (x / waveformWidth);
                        final newPosition = Duration(milliseconds: (totalDuration.inMilliseconds * percent).toInt());
                        setState(() {
                          _waveformScrollFraction = percent.isNaN || percent.isInfinite ? 0.0 : percent;
                          _draggedSeconds = newPosition.inMilliseconds / 1000.0;
                        });
                      }
                    },
                    onHorizontalDragEnd: (details) async {
                      final totalDuration = _audioPlayer.duration;
                      if (totalDuration != null && totalDuration.inMilliseconds > 0) {
                        final safeFraction = _waveformScrollFraction.isNaN || _waveformScrollFraction.isInfinite ? 0.0 : _waveformScrollFraction;
                        final newPosition = Duration(milliseconds: (totalDuration.inMilliseconds * safeFraction).toInt());
                        await _audioPlayer.seek(newPosition);
                        setState(() {
                          _elapsedSeconds = newPosition.inMilliseconds / 1000.0;
                          _isDraggingWaveform = false;
                        });
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 120,
                          width: double.infinity,
                          color: const Color(0xFFF5F5F5),
                          child: Container(
                            width: double.infinity,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFFF7E27), width: 1.5),
                            ),
                            child: ClipRect(
                              child: CustomPaint(
                                painter: _WaveformPainter(
                                  phase: _isPlaying ? _controller.value : 0.0,
                                  scrollFraction: _waveformScrollFraction,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Blue vertical line indicator in the center
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 2,
                              height: 120, // match the waveform container's height
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child:  Container(
                      width: 2,
                      height: 10, // match the waveform container's height
                      color: Colors.blue,
                    ),
                  ),

                  Image.asset(
                    'assets/images/arrowPointer.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
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
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAddingBookmark = true;
                                    _pendingBookmarkTime = _isDraggingWaveform ? _draggedSeconds : _elapsedSeconds;
                                    _bookmarkTextController.clear();
                                  });
                                },
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
                  // Name tag filters row (dynamic)
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                        .collection('sessions')
                        .doc(widget.sessionId)
                        .collection('recordings')
                        .doc(widget.recordingDocId)
                        .collection('bookmarks')
                        .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedUserId = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _selectedUserId == null ? Colors.black : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('All', style: TextStyle(color: _selectedUserId == null ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          );
                        }
                        final bookmarks = snapshot.data!.docs;
                        final userIds = bookmarks
                            .map((doc) => (doc.data() as Map<String, dynamic>)['userId'] as String?)
                            .where((id) => id != null)
                            .cast<String>()
                            .toSet()
                            .toList();
                        return FutureBuilder<Map<String, String>>(
                          future: _fetchUserNames(userIds),
                          builder: (context, userSnapshot) {
                            final userNames = userSnapshot.data ?? {};
                            return Row(
                              children: [
                                ...userNames.entries.map((entry) {
                                  final isSelected = _selectedUserId == entry.key;
                                  final userColor = getUserColor(entry.key, entry.value);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedUserId = entry.key;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? userColor : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                          border: isSelected ? null : Border.all(color: userColor, width: 2),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.bookmark, color: isSelected ? Colors.white : userColor, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              (entry.value != null && entry.value.isNotEmpty) ? entry.value : entry.key,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : userColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedUserId = null;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      'All',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bookmarks list (scrollable, moves up with keyboard)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: FutureBuilder<Map<String, String>>(
                      future: () async {
                        final userIds = bookmarks.map((doc) => (doc.data() as Map<String, dynamic>)['userId'] as String?).where((id) => id != null).cast<String>().toSet();
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                        if (currentUserId != null) {
                          userIds.add(currentUserId);
                        }
                        return _fetchUserNames(userIds.toList());
                      }(),
                      builder: (context, userNamesSnapshot) {
                        if (!userNamesSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final userNames = userNamesSnapshot.data ?? {};
                        final filteredBookmarks = _selectedUserId == null
                          ? bookmarks
                          : bookmarks.where((doc) => (doc.data() as Map<String, dynamic>)['userId'] == _selectedUserId).toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: filteredBookmarks.length + (_isAddingBookmark && _pendingBookmarkTime != null ? 1 : 0),
                          itemBuilder: (context, index) {
                            final isLast = index == filteredBookmarks.length + (_isAddingBookmark && _pendingBookmarkTime != null ? 1 : 0) - 1;
                            Widget rowWidget;
                            if (_isAddingBookmark && _pendingBookmarkTime != null && index == filteredBookmarks.length) {
                              final currentUser = FirebaseAuth.instance.currentUser;
                              final currentUserName = userNames[currentUser?.uid] ?? '';
                              final userColor = getUserColor(currentUser?.uid, currentUserName);
                              // The new bookmark text field row
                              rowWidget = Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.bookmark_border, color: userColor, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            _formatElapsed(_pendingBookmarkTime ?? 0.0),
                                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _bookmarkTextController,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          hintText: 'Bookmark name',
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                                        ),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        onSubmitted: (value) async {
                                          if (value.trim().isNotEmpty && _pendingBookmarkTime != null) {
                                            await _addBookmarkWithLabel(value.trim(), _pendingBookmarkTime!);
                                          }
                                          setState(() {
                                            _isAddingBookmark = false;
                                            _pendingBookmarkTime = null;
                                            _bookmarkTextController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              final doc = filteredBookmarks[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final time = data['bookmark_time'] ?? 0.0;
                              final label = data['label'] ?? '';
                              final userId = data['userId'] as String?;
                              final userName = userNames[userId] ?? 'Unknown';
                              final userColor = getUserColor(userId, userName);
                              rowWidget = Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.bookmark, color: userColor, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            _formatElapsed(time.toDouble()),
                                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Column(
                              children: [
                                rowWidget,
                                if (!isLast)
                                  Divider(height: 1, thickness: 1, color: Colors.grey[300]),
                              ],
                            );
                          },
                        );
                      },
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
              );
            },
          ),
        ),
        floatingActionButton: MediaQuery.of(context).viewInsets.bottom == 0
            ? SizedBox(
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
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: MediaQuery.of(context).viewInsets.bottom == 0
            ? Stack(
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
                    // shape: const CircularNotchedRectangle(),
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
              )
            : null,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double phase;
  final double scrollFraction;
  _WaveformPainter({this.phase = 0.0, double? scrollFraction})
      : scrollFraction = (scrollFraction == null || scrollFraction.isNaN || scrollFraction.isInfinite) ? 0.0 : scrollFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final heights = [
      4, 4, 6, 4, 4, 6, 4, 10, 16, 24, 36, 50, 60, 66, 60, 50, 36, 24, 16, 10,
      16, 24, 36, 50, 60, 70, 76, 70, 60, 50, 36, 24, 16, 10, 6,
    ];
    final barWidth = size.width / (heights.length * 1.8);

    // Calculate the offset so the playhead (center) matches the scrollFraction
    final totalWaveWidth = barWidth * (heights.length * 1.8 - 1.8);
    final playheadX = size.width / 2;
    final safeScrollFraction = scrollFraction.isNaN || scrollFraction.isInfinite ? 0.0 : scrollFraction;
    final scrollX = safeScrollFraction * totalWaveWidth;
    final shift = (phase * heights.length) % heights.length;
    for (int i = 0; i < heights.length; i++) {
      int shiftedIndex = (i + shift.toInt()) % heights.length;
      // Calculate the x position so the waveform scrolls under the fixed playhead
      final x = barWidth * (i * 1.8) - scrollX + playheadX;
      final barHeight = heights[shiftedIndex].toDouble();
      // Only draw bars that are visible in the widget
      if (x >= 0 && x <= size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2 - barHeight / 2),
          Offset(x, size.height / 2 + barHeight / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.phase != phase || oldDelegate.scrollFraction != scrollFraction;
}
