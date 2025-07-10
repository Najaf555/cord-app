import 'package:get/get.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../models/recording.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionDetailController extends GetxController {
  final Session session;
  var selectedTabIndex = 0.obs;

  SessionDetailController({required this.session});

  var participants = <User>[].obs;
  var recordings = <Recording>[].obs;
  var isDescendingOrder = true.obs;
  var sessionName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    participants.assignAll(session.users);
    sessionName.value = session.name;
    // loadMockRecordings();
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

  Future<void> loadRecordingsFromFirestore() async {
    final sessionId = session.id;
    final recordingsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('recordings');
    final snapshot = await recordingsRef.orderBy('createdAt', descending: true).get();
    recordings.value = snapshot.docs.map((doc) {
      final data = doc.data();
      return Recording.fromFirestore(data, doc.id);
    }).toList();
  }

  Future<void> deleteRecording(String recordingId) async {
    final sessionId = session.id;
    final recordingsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('recordings');
    await recordingsRef.doc(recordingId).delete();
    recordings.removeWhere((rec) => rec.recordingId == recordingId);
    update();
  }

  Future<void> updateSessionName(String newName) async {
    sessionName.value = newName;
    final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(session.id);
    await sessionRef.update({'name': newName});
    update();
  }
} 