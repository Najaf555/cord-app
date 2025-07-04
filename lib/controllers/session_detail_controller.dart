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
        id: 'rec1',
        name: 'New Recording',
        dateTime: DateTime(2024, 12, 30, 13, 50),
        user: session.users.first,
        status: 'Recording...',
      ),
      Recording(
        id: 'rec2',
        name: 'Random melody',
        dateTime: DateTime(2024, 12, 30, 13, 50),
        user: session.users[1],
        status: 'completed',
        duration: '02:49',
      ),
      Recording(
        id: 'rec3',
        name: 'Lyrics To Chorus',
        dateTime: DateTime(2024, 12, 30, 13, 50),
        user: session.users[2],
        status: 'completed',
        duration: '02:15',
      ),
    ];
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  List<Recording> get sortedRecordings {
    final sorted = List<Recording>.from(recordings);
    sorted.sort((a, b) => isDescendingOrder.value
        ? b.dateTime.compareTo(a.dateTime)
        : a.dateTime.compareTo(b.dateTime));
    return sorted;
  }

  void toggleSortOrder() {
    isDescendingOrder.value = !isDescendingOrder.value;
  }

  Future<void> loadRecordingsFromFirestore() async {
    final sessionId = '6xfhQsVPQkTGCeFDfcIt';
    final recordingsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('recordings');
    final snapshot = await recordingsRef.orderBy('createdAt', descending: true).get();
    recordings.value = snapshot.docs.map((doc) {
      final data = doc.data();
      return Recording(
        id: doc.id,
        name: data['name'] ?? 'New Recording',
        dateTime: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        user: null, // You can enhance this to fetch user info if needed
        status: data['status'] ?? '',
        duration: data['duration']?.toString(),
      );
    }).toList();
  }

  Future<void> deleteRecording(String recordingId) async {
    final sessionId = session.id;
    final recordingsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('recordings');
    await recordingsRef.doc(recordingId).delete();
    recordings.removeWhere((rec) => rec.id == recordingId);
    update();
  }

  Future<void> updateSessionName(String newName) async {
    sessionName.value = newName;
    final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(session.id);
    await sessionRef.update({'name': newName});
    update();
  }
} 