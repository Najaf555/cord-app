import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';
import 'sessions_view.dart';
import 'settings_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/session_detail_controller.dart';

class SaveRecordingScreen extends StatefulWidget {
  const SaveRecordingScreen({super.key});

  @override
  State<SaveRecordingScreen> createState() => _SaveRecordingScreenState();
}

class _SaveRecordingScreenState extends State<SaveRecordingScreen> {
  String _searchQuery = '';
  final TextEditingController _newSessionNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24.0),
        topRight: Radius.circular(24.0),
      ),
      child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 8),
            Center(
              child: Column(
                children: const [
                  Text(
                    'New Session',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                    Row(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: const [
                  Text(
                    'New Recording',
      style: TextStyle(fontSize: 15, color: Colors.black54),
    ),
    SizedBox(width: 6),
    Icon(Icons.edit, size: 16, color: Colors.black54),
  ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '00:06.67',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
                title: const Text('Save to a new session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Create Session',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _newSessionNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Session Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 16),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF9800), Color(0xFFE91E63)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.5),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: TextButton(
                                          onPressed: () async {
                                            final sessionName = _newSessionNameController.text.trim();
                                            if (sessionName.isEmpty) return;
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user == null) return;
                                            final sessionsRef = FirebaseFirestore.instance.collection('sessions');
                                            final newDocRef = sessionsRef.doc();
                                            final sessionId = 'SESSION_${newDocRef.id.substring(0, 6).toUpperCase()}';
                                            await newDocRef.set({
                                              'sessionId': sessionId,
                                              'name': sessionName,
                                              'hostId': user.uid,
                                              'createdAt': DateTime.now(),
                                              'serverCreatedAt': FieldValue.serverTimestamp(),
                                              'updatedAt': FieldValue.serverTimestamp(),
                                            });
                                            _newSessionNameController.clear();
                                            Navigator.of(context).pop();
                                            Get.snackbar('Success', 'Session created!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                                            setState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                          ),
                                          child: const Text(
                                            'Create',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
              Center(
                child: Container(
                  width: 320,
                  height: 1,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'Add to existing session', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
      cursorColor: Colors.purple,
      cursorWidth: 2.0,
      cursorHeight: 16.0,
                decoration: InputDecoration(
                  hintText: 'search...',
        hintStyle: TextStyle(color: Color(0xFF828282), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10), // smaller height
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFBDBDBD)),
        ),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 8), // push icon to the edge
          child: Icon(Icons.search, color: Color(0xFF222222), size: 20),
        ),
        suffixIconConstraints: BoxConstraints(
          minWidth: 32,
          minHeight: 32,
                  ),
                  isDense: true,
                ),
      style: TextStyle(fontSize: 16),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _userSessionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No sessions found.'));
                    }
                    final sessions = snapshot.data!.docs;
                    final filteredSessions = _searchQuery.isEmpty
                        ? sessions
                        : sessions.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final sessionName = (data['name'] ?? '').toString().toLowerCase();
                            return sessionName.contains(_searchQuery);
                          }).toList();
                    return ListView.separated(
                      itemCount: filteredSessions.length,
                      separatorBuilder: (context, index) => Center(
                        child: Container(
                          width: 320,
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      ),
                    itemBuilder: (context, index) {
                        final data = filteredSessions[index].data() as Map<String, dynamic>;
                        final sessionName = data['name'] ?? 'Unnamed Session';
                        final createdAt = data['createdAt'] is Timestamp
                            ? (data['createdAt'] as Timestamp).toDate()
                            : null;
                        final sessionId = filteredSessions[index].id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.folder, color: Colors.blue),
                          title: Text(sessionName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: createdAt != null
                              ? Text('Created: ${createdAt.toString().substring(0, 16)}', style: const TextStyle(fontSize: 12, color: Colors.black38))
                              : null,
                          trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                          onTap: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            try {
                              final sessionId = '6xfhQsVPQkTGCeFDfcIt';
                              final recordingsRef = FirebaseFirestore.instance
                                  .collection('sessions')
                                  .doc(sessionId)
                                  .collection('recordings');
                              final docRef = await recordingsRef.add({
                                'recordingId': '', // will be updated below
                                'userId': user.uid,
                                'name': 'New Recording', // Placeholder, replace with actual name if available
                                'duration': '00:06.67', // Placeholder, replace with actual duration if available
                                'fileUrl': '', // Placeholder, replace with actual file URL if available
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              await recordingsRef.doc(docRef.id).update({
                                'recordingId': docRef.id,
                              });
                              // Refresh session detail recordings if controller is available
                              try {
                                final sessionDetailController = Get.isRegistered<SessionDetailController>()
                                    ? Get.find<SessionDetailController>()
                                    : null;
                                if (sessionDetailController != null) {
                                  await sessionDetailController.loadRecordingsFromFirestore();
                                }
                              } catch (_) {}
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Recording saved to session!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to save recording: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
        bottomNavigationBar: GetBuilder<NavigationController>(
          builder: (navController) => Stack(
            children: [
              // Top border line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(height: 2, color: Color(0xFFE0E0E0)),
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
                  child: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
                    selectedItemColor: Color(0xFF222222),
                    unselectedItemColor: Color(0xFFBDBDBD),
                    selectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
                    unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
                    currentIndex: navController.selectedIndex.value,
        onTap: (index) {
                      navController.changeTab(index);
                      Navigator.of(context).pop(); // Close the bottom sheet
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final String title;
  final String date;
  final List<String> avatars;
  final int recordings;
  const _SessionTile({required this.title, required this.date, required this.avatars, required this.recordings});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(date, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      leading: SizedBox(
        width: 80,
        child: Stack(
          children: [
            for (int i = 0; i < avatars.length && i < 3; i++)
              Positioned(
                left: i * 24,
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(avatars[i]),
                ),
              ),
            if (avatars.length > 3)
              Positioned(
                left: 3 * 24,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    '+${avatars.length - 3}',
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Icon(Icons.chevron_right, size: 24),
          Text('$recordings recordings', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
      onTap: () {},
    );
  }
}

Stream<QuerySnapshot> _userSessionsStream() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // Return an empty stream if not logged in
    return const Stream.empty();
  }
  final uid = user.uid;
  // Query sessions where hostId == uid OR participantIds contains uid
  return FirebaseFirestore.instance
      .collection('sessions')
      .where('participantIds', arrayContains: uid)
      .snapshots()
      .asyncMap((participantSnap) async {
        final participantSessions = participantSnap.docs;
        final hostSnap = await FirebaseFirestore.instance
            .collection('sessions')
            .where('hostId', isEqualTo: uid)
            .get();
        final hostSessions = hostSnap.docs;
        // Merge and deduplicate by document ID
        final allSessions = <String, QueryDocumentSnapshot>{};
        for (var doc in participantSessions) {
          allSessions[doc.id] = doc;
        }
        for (var doc in hostSessions) {
          allSessions[doc.id] = doc;
        }
        return QuerySnapshotFake(allSessions.values.toList());
      })
      .asyncExpand((snap) => Stream.value(snap));
}

// Helper class to fake a QuerySnapshot for the builder
class QuerySnapshotFake implements QuerySnapshot {
  @override
  final List<QueryDocumentSnapshot> docs;
  QuerySnapshotFake(this.docs);
  // The rest of the QuerySnapshot members are not used in this context
  @override
  // ignore: no_override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
