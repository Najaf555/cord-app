import 'package:get/get.dart';
import '../models/session.dart';

class NavigationController extends GetxController {
  var selectedIndex = 0.obs;
  var currentSession = Rx<Session?>(null); // Null means showing sessions list

  void changeTab(int index) {
    currentSession.value = null; // Clear session details when changing tabs
    selectedIndex.value = index;
  }

  void showSessionDetails(Session session) {
    currentSession.value = session;
  }

  void showSessionsList() {
    currentSession.value = null;
  }
} 