import 'package:get/get.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../models/recording.dart';

class SessionDetailController extends GetxController {
  final Session session;
  var selectedTabIndex = 0.obs;

  SessionDetailController({required this.session});

  var participants = <User>[].obs;
  var recordings = <Recording>[].obs;

  @override
  void onInit() {
    super.onInit();
    participants.assignAll(session.users);
    loadMockRecordings();
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
} 