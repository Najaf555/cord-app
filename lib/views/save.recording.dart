import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';
import 'sessions_view.dart';
import 'settings_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaveRecordingScreen extends StatelessWidget {
  const SaveRecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find<NavigationController>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: const [
                  Text(
                    'New Session',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'New Recording',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '00:06.67',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            ListTile(
              title: const Text('Save to a new session', style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text('Add to existing session', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'search...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('recordings').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No recordings found.'));
                  }
                  final recordings = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: recordings.length,
                    itemBuilder: (context, index) {
                      final data = recordings[index].data() as Map<String, dynamic>;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: const Icon(Icons.audiotrack, color: Colors.blue),
                        title: Text(data['fileName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Duration: ${data['duration'] ?? '--:--'}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            if (data['createdAt'] != null)
                              Text(
                                'Created: ' + (data['createdAt'] is Timestamp
                                    ? (data['createdAt'] as Timestamp).toDate().toString().substring(0, 16)
                                    : data['createdAt'].toString()),
                                style: const TextStyle(fontSize: 12, color: Colors.black38),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
                        onTap: () {},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            if (!(context.widget is SessionsView)) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SessionsView()),
              );
            }
          } else if (index == 1) {
            if (!(context.widget is SettingsView)) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
            }
          }
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
