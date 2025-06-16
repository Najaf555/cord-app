import 'package:get/get.dart';
import '../models/session.dart';
import '../models/user.dart';

class SessionController extends GetxController {
  var sessions = <Session>[].obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMockSessions();
  }

  void loadMockSessions() {
    final users = [
      User(id: '1', name: 'User1', avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg'),
      User(id: '2', name: 'User2', avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg'),
      User(id: '3', name: 'User3', avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg'),
      User(id: '4', name: 'User4', avatarUrl: 'https://randomuser.me/api/portraits/men/4.jpg'),
      User(id: '5', name: 'User5', avatarUrl: 'https://randomuser.me/api/portraits/men/5.jpg'),
    ];
    sessions.value = [
      Session(
        id: '1',
        name: 'Spellbound',
        dateTime: DateTime(2024, 10, 19, 13, 50),
        createdDate: DateTime(2024, 10, 15),
        users: users,
        recordingsCount: 14,
      ),
      Session(
        id: '2',
        name: 'Remedy',
        dateTime: DateTime(2024, 10, 16, 18, 25),
        createdDate: DateTime(2024, 10, 10),
        users: [users[1], users[2], users[3]],
        recordingsCount: 7,
      ),
      Session(
        id: '3',
        name: 'Lighthouse',
        dateTime: DateTime(2024, 9, 9, 11, 44),
        createdDate: DateTime(2024, 9, 5),
        users: [users[2], users[4]],
        recordingsCount: 9,
      ),
      Session(
        id: '4',
        name: 'Free Falling v2',
        dateTime: DateTime(2024, 12, 30, 13, 50),
        createdDate: DateTime(2024, 12, 30),
        users: [users[0], users[1], users[2]],
        recordingsCount: 3,
      ),
    ];
  }

  List<Session> get filteredSessions {
    if (searchQuery.value.isEmpty) {
      return sessions;
    }
    return sessions
        .where((s) => s.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
} 