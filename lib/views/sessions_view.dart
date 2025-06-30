import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_controller.dart';
import '../controllers/navigation_controller.dart';
import '../utils/date_util.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';
import '../views/new_recording.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_detail_view.dart';
import '../controllers/session_detail_controller.dart';


class SessionsView extends StatefulWidget {
  const SessionsView({super.key});

  @override
  State<SessionsView> createState() => _SessionsViewState();
}

class _SessionsViewState extends State<SessionsView> {
  final SessionController controller = Get.put(SessionController());
  final NavigationController navigationController = Get.put(
    NavigationController(),
  );

  bool _showNotifications = false;
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'invite_accepted',
      'email': 'theo@email.com',
    },
    {
      'type': 'invite_accepted',
      'email': 'ian@email.com',
    },
    {
      'type': 'session_invite',
      'email': 'andrew@email.com',
      'session': 'Free Falling v2',
    },
  ];

  final TextEditingController _sessionNameController = TextEditingController();
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoadingInvitations = false;
  List<Map<String, dynamic>> _userInvitations = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingInvites();
  }

  Future<void> _fetchPendingInvites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final query = await FirebaseFirestore.instance
        .collection('user_invitations')
        .where('invitedEmail', isEqualTo: user.email)
        .where('status', isEqualTo: 'pending')
        .get();
    setState(() {
      _pendingInvites = query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  Future<void> _respondToInvite(String docId, String status, String? sessionId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'You must be logged in to respond.');
      return;
    }

    try {
      // 1. Update the invitation status
      await FirebaseFirestore.instance.collection('user_invitations').doc(docId).update({'status': status});

      // 2. If accepted, add user to the session's participants
      if (status == 'accepted') {
        if (sessionId == null || sessionId.isEmpty) {
          Get.snackbar('Error', 'Cannot join session: Session ID is missing.');
          // Optionally, you might want to set the status back to 'pending' or handle this case differently
          await FirebaseFirestore.instance.collection('user_invitations').doc(docId).update({'status': 'failed'});
          return;
        }
        await FirebaseFirestore.instance.collection('sessions').doc(sessionId).update({
          'participantIds': FieldValue.arrayUnion([currentUser.uid])
        });
        Get.snackbar('Invitation Accepted', 'You have been added to the session!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Invitation Rejected', 'You have rejected the invitation.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred. Please try again.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      print('Error responding to invite: $e');
    }
  }

  Future<void> _fetchUserInvitations() async {
    setState(() => _isLoadingInvitations = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) {
        throw Exception('User not logged in');
      }

      final QuerySnapshot<Map<String, dynamic>> query = await FirebaseFirestore.instance
          .collection('user_invitations')
          .where('invitedEmail', isEqualTo: currentUser!.email)
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted) return;

      setState(() {
        _userInvitations = query.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoadingInvitations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInvitations = false;
        _userInvitations = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sessions',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF222222),
                        ),
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications,
                                  color: Color(0xFF2F80ED),
                                  size: 30,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showNotifications = !_showNotifications;
                                  });
                                },
                              ),
                              Positioned(
                                right: 10,
                                top: 12,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEB5757),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      onChanged: controller.setSearchQuery,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'search...',
                        hintStyle: const TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 15,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFBDBDBD),
                          ),
                        ),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.search, color: Color(0xFF222222)),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 220,
                      child: OutlinedButton(
                        onPressed: () async {
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
                                        controller: _sessionNameController,
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
                                                    final sessionName = _sessionNameController.text.trim();
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
                                                    _sessionNameController.clear();
                                                    Navigator.of(context).pop();
                                                    Get.snackbar('Success', 'Session created!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                                                    controller.refreshSessions();
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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: Color(0xFFFF6B6B),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Create Session',
                          style: TextStyle(
                            fontSize: 22,
                            color: Color(0xFF000000),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading sessions...',
                                style: TextStyle(
                                  color: Color(0xFF959595),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final sessions = controller.filteredSessions;
                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${sessions.length} sessions',
                                style: const TextStyle(
                                  color: Color(0xFF959595),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Obx(() => Text(
                                ' (${controller.isAuthenticated.value ? '' : 'dummy'})',
                                style: TextStyle(
                                  color: controller.isAuthenticated.value ? Colors.green : Colors.red,
                                  fontSize: 10,
                                ),
                              )),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  controller.toggleSortOrder();
                                },
                                child: Tooltip(
                                  message: controller.isDescendingOrder.value 
                                    ? 'Newest first (click to change to oldest first)' 
                                    : 'Oldest first (click to change to newest first)',
                                  child: Obx(() => Icon(
                                    Icons.swap_vert,
                                    color: controller.isDescendingOrder.value 
                                      ? const Color(0xFF2F80ED) 
                                      : const Color(0xFF000000),
                                    size: 20,
                                  )),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                await controller.refreshSessions();
                              },
                              color: Color(0xFFFF9800),
                              child: sessions.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.folder_open,
                                            size: 64,
                                            color: Color(0xFFBDBDBD),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No sessions yet',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF959595),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Create your first session to get started',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFBDBDBD),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: sessions.length,
                                      separatorBuilder:
                                          (_, __) => const Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Color(0xFFF0F0F0),
                                          ),
                                      itemBuilder: (context, index) {
                                        final session = sessions[index];
                                        return InkWell(
                                          onTap: () {
                                            Get.put(SessionDetailController(session: session));
                                            Get.to(() => SessionDetailView());
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        session.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 17,
                                                          color: Color(0xFF222222),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${session.dateTime.day.toString().padLeft(2, '0')}/'
                                                        '${session.dateTime.month.toString().padLeft(2, '0')}/'
                                                        '${session.dateTime.year.toString().substring(2)} '
                                                        '${session.dateTime.hour.toString().padLeft(2, '0')}:${session.dateTime.minute.toString().padLeft(2, '0')}',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Color(0xFF828282),
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children:
                                                          session.users
                                                              .map(
                                                                (user) => Padding(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal: 2.0,
                                                                      ),
                                                                  child: CircleAvatar(
                                                                    radius: 18,
                                                                    backgroundImage:
                                                                        NetworkImage(
                                                                          (user)
                                                                              .avatarUrl,
                                                                        ),

                                                                    backgroundColor:
                                                                        Colors.white,
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${session.recordingsCount} recordings',
                                                      style: const TextStyle(
                                                        color: Color(0xFFBDBDBD),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 70,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: child,
                  ),
                );
              },
              child: _showNotifications
                  ? _buildNotificationPanel()
                  : Container(key: const ValueKey('empty-panel')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPanel() {
    return Material(
      key: const ValueKey('notification-panel'),
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 320,
        height: MediaQuery.of(context).size.height - 90,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _showNotifications = false);
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getAllUserNotificationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading invitations'));
                  }
                  final notifications = snapshot.data ?? [];
                  if (notifications.isEmpty) {
                    return const Center(child: Text('No invitations'));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = notifications[index];
                      final type = data['type'] ?? '';
                      final email = data['email'] ?? 'Unknown';
                      if (type == 'invite_accepted') {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement clear notification logic
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 24),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerRight,
                              ),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else if (type == 'session_invite') {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _respondToInvite(data['id'], 'accepted', null),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 24),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    alignment: Alignment.centerRight,
                                  ),
                                  child: const Text(
                                    'Accept',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _respondToInvite(data['id'], 'rejected', null),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 24),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    alignment: Alignment.centerRight,
                                  ),
                                  child: const Text(
                                    'Reject',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> getAllUserNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('user_invitations')
        .where('invitedEmail', isEqualTo: user.email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data() as Map);
              data['id'] = doc.id;
              return <String, dynamic>{
                'type': 'session_invite',
                'email': data['inviterEmail'],
                'id': doc.id,
              };
            }).toList());
  }
}

Future<void> sendInvitation(String inviteeEmail, String sessionId) async {
  final inviter = FirebaseAuth.instance.currentUser;
  if (inviter == null) return;
  await FirebaseFirestore.instance.collection('user_invitations').add({
    'invitedEmail': inviteeEmail,
    'inviterEmail': inviter.email,
    'sessionId': sessionId,
    'status': 'pending',
    'createdAt': DateTime.now(),
    'serverCreatedAt': FieldValue.serverTimestamp(),
  });
}

Future<List<Map<String, dynamic>>> fetchPendingInvites() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  final query = await FirebaseFirestore.instance
      .collection('user_invitations')
      .where('invitedEmail', isEqualTo: user.email)
      .where('status', isEqualTo: 'pending')
      .get();
  return query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
}

Widget buildInvites(List<Map<String, dynamic>> invites) {
  return Column(
    children: invites.map((invite) {
      return ListTile(
        title: Text('${invite['fromEmail']} invited you'),
        subtitle: Text('Session: ${invite['sessionId']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => respondToInvite(invite['id'], 'accepted'),
              child: Text('Accept'),
            ),
            TextButton(
              onPressed: () => respondToInvite(invite['id'], 'rejected'),
              child: Text('Reject'),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

Future<void> respondToInvite(String inviteId, String status) async {
  await FirebaseFirestore.instance
      .collection('user_invitations')
      .doc(inviteId)
      .update({'status': status});
}

Stream<List<Map<String, dynamic>>> inviteStream(String email) {
  return FirebaseFirestore.instance
      .collection('user_invitations')
      .where('invitedEmail', isEqualTo: email)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
}
