import 'package:get/get.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../models/recording.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class SessionDetailController extends GetxController {
  final Session session;
  var selectedTabIndex = 0.obs;

  SessionDetailController({required this.session});

  var participants = <User>[].obs;
  var recordings = <Recording>[].obs;
  var isDescendingOrder = true.obs;
  var sessionName = ''.obs;
  var isRecordingsLoading = false.obs;
  StreamSubscription? _recordingsSubscription;

  // Add stream for real-time recordings updates
  Stream<List<Recording>> get recordingsStream {
    final sessionId = session.id;
    final recordingsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('recordings');
    return recordingsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Recording.fromFirestore(data, doc.id);
            }).toList());
  }

  // Explicit Firestore loading for recordings (like sessions)
  Future<void> loadRecordingsFromFirestore() async {
    try {
      isRecordingsLoading.value = true;
      final sessionId = session.id;
      final recordingsRef = FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('recordings');
      final snapshot = await recordingsRef.get();
      final List<Recording> loadedRecordings = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final recording = Recording.fromFirestore(data, doc.id);
        // Fetch user avatar
        String avatarUrl = '';
        if (recording.userId.isNotEmpty) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(recording.userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            avatarUrl = userData['profileImageUrl'] ?? userData['avatarUrl'] ?? userData['imageUrl'] ?? '';
          }
        }
        // Attach avatarUrl to the recording (if you want to extend the Recording model, do so; otherwise, use a map or tuple)
        // For now, we'll use a RecordingWithAvatar tuple-like class (or you can extend Recording)
        loadedRecordings.add(recording.copyWith(userAvatarUrl: avatarUrl ?? ''));
      }
      // Sort by createdAt
      if (isDescendingOrder.value) {
        loadedRecordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        loadedRecordings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      recordings.value = loadedRecordings;
    } catch (e) {
      print('Error loading recordings from Firestore: $e');
    } finally {
      isRecordingsLoading.value = false;
    }
  }

  // Manual refresh for pull-to-refresh
  Future<void> refreshRecordings() async {
    await loadRecordingsFromFirestore();
  }

  // Update sorting and reload
  @override
  void onInit() {
    super.onInit();
    participants.assignAll(session.users);
    sessionName.value = session.name;
    _listenToRecordings();
    ever(isDescendingOrder, (_) => _listenToRecordings());
  }

  void _listenToRecordings() {
    _recordingsSubscription?.cancel();
    final sessionId = session.id;
    final recordingsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('recordings');
    _recordingsSubscription = recordingsRef.snapshots().listen((snapshot) async {
      final List<Recording> loadedRecordings = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final recording = Recording.fromFirestore(data, doc.id);
        // Fetch user avatar
        String avatarUrl = '';
        if (recording.userId.isNotEmpty) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(recording.userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            avatarUrl = userData['profileImageUrl'] ?? userData['avatarUrl'] ?? userData['imageUrl'] ?? '';
          }
        }
        loadedRecordings.add(recording.copyWith(userAvatarUrl: avatarUrl ?? ''));
      }
      // Sort by createdAt
      if (isDescendingOrder.value) {
        loadedRecordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        loadedRecordings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      recordings.value = loadedRecordings;
    });
  }

  @override
  void onClose() {
    _recordingsSubscription?.cancel();
    super.onClose();
  }

  void loadMockRecordings() {
    recordings.value = [
      Recording(
        recordingId: 'rec1',
        userId: session.users.first.id,
        fileUrl: 'https://example.com/recording1.m4a',
        duration: '00:00.00',
        createdAt: DateTime(2024, 12, 30, 13, 50),
        fileName: 'recording_1735567800000.m4a',
        name: 'New Recording',
      ),
      Recording(
        recordingId: 'rec2',
        userId: session.users[1].id,
        fileUrl: 'https://example.com/recording2.m4a',
        duration: '02:49.00',
        createdAt: DateTime(2024, 12, 30, 13, 50),
        fileName: 'recording_1735567800001.m4a',
        name: 'Random melody',
      ),
      Recording(
        recordingId: 'rec3',
        userId: session.users[2].id,
        fileUrl: 'https://example.com/recording3.m4a',
        duration: '02:15.00',
        createdAt: DateTime(2024, 12, 30, 13, 50),
        fileName: 'recording_1735567800002.m4a',
        name: 'Lyrics To Chorus',
      ),
    ];
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  List<Recording> get sortedRecordings {
    final sorted = List<Recording>.from(recordings);
    sorted.sort((a, b) => isDescendingOrder.value
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  void toggleSortOrder() {
    isDescendingOrder.value = !isDescendingOrder.value;
  }

  // Remove the old loadRecordingsFromFirestore method since we now use streams

  Future<void> deleteRecording(String recordingId) async {
    final sessionId = session.id;
    final recordingsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('recordings');
    await recordingsRef.doc(recordingId).delete();
    await refreshRecordings(); // Refresh after delete
  }

  Future<void> updateSessionName(String newName) async {
    sessionName.value = newName;
    final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(session.id);
    await sessionRef.update({'name': newName});
    update();
  }
} 