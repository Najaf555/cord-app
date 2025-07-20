import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_detail_controller.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/date_util.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';
import '../models/session.dart';
import 'session_detail_view.dart';
import 'new_recording.dart';
import 'sessions_view.dart';
import 'settings_view.dart';
import '../controllers/navigation_controller.dart';
import '../views/main_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'paused_recording.dart';
import '../utils/fcm_notification_service.dart';
import '../controllers/lyrics_controller.dart';
import '../models/lyric_line.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../utils/azure_openai_service.dart'; // Added for Azure OpenAI integration

class SessionDetailView extends StatefulWidget {
  final Session session;

  const SessionDetailView({super.key, required this.session});

  @override
  State<SessionDetailView> createState() => _SessionDetailViewState();
}

class _SessionDetailViewState extends State<SessionDetailView>
    with SingleTickerProviderStateMixin {
  late SessionDetailController controller;
  late TabController _tabController;
  final TextEditingController inviteEmailController = TextEditingController();
  final _previouslyInvitedUsers = <Map<String, dynamic>>[].obs;
  final _isLoadingInvitedUsers = false.obs;
  bool _isInvitingUser = false; // Loading state for invite user functionality
  String? inviteError;
  String currentUserEmail = '';
  String? _sessionHostId;
  bool _isCurrentUserHost = false;
  bool _loadingHost = true;
  late BuildContext _rootContext; // <-- Add this line

  @override
  void initState() {
    super.initState();
    controller = Get.put(SessionDetailController(session: widget.session));
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: controller.selectedTabIndex.value,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.changeTab(_tabController.index);
      }
    });
    final user = FirebaseAuth.instance.currentUser;
    currentUserEmail = user?.email ?? '';
    _fetchSessionHost();
    // Remove the loadRecordingsFromFirestore call since we now use streams
  }

  Future<void> _fetchSessionHost() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('sessions').doc(widget.session.id).get();
      final data = doc.data();
      final hostId = data != null ? data['hostId'] as String? : null;
      final currentUser = FirebaseAuth.instance.currentUser?.uid;
      setState(() {
        _sessionHostId = hostId;
        _isCurrentUserHost = (hostId != null && currentUser != null && hostId == currentUser);
        _loadingHost = false;
      });
    } catch (e) {
      setState(() {
        _loadingHost = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    inviteEmailController.dispose();
    super.dispose();
  }

  // Add this helper method to fix showDialog after await
  Future<void> _showMoveDialog(BuildContext parentContext, String sessionId, String recordingId) async {
    final doc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('recordings')
        .doc(recordingId)
        .get();
    if (!doc.exists) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Recording not found.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: parentContext,
      builder: (context) => MoveRecordingDialog(
        currentSessionId: sessionId,
        recordingId: recordingId,
        recordingData: doc.data()!,
        rootContext: _rootContext, // Pass root context
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _rootContext = context; // <-- Set the root context here
    return Scaffold(
      backgroundColor: Colors.white, // Make Scaffold transparent
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Gradient background for status bar and header
          // Container(
          //   height: MediaQuery.of(context).padding.top,
          //   decoration: const BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Color(0xFFFF833E), Color(0xFFFF0055)],
          //       begin: Alignment.topLeft,
          //       end: Alignment.topRight,
          //     ),
          //   ),
          // ),
          SafeArea(
        child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Obx(() => AutoSizeText(
                                  controller.sessionName.value,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF222222),
                                  ),
                                  maxLines: 2,
                                  minFontSize: 16,
                                  overflow: TextOverflow.ellipsis,
                                )),
                            ),
                            const SizedBox(width: 4),
                              if (_loadingHost)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else if (_isCurrentUserHost)
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.black,
                                size: 20,
                              ),
                              onPressed: () {
                                final nameController = TextEditingController(text: controller.sessionName.value);
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
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
                                              'New Session',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: nameController,
                                                  textCapitalization: TextCapitalization.sentences,
                                              decoration: InputDecoration(
                                                labelText: 'New Session',
                                                labelStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                hintText: 'New Session',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 16,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[400]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[400]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.zero,
                                                  borderSide: BorderSide(
                                                    color: Colors.grey[600]!,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 14,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 20),
                                            Center(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final newName = nameController.text.trim();
                                                  if (newName.isNotEmpty && newName != controller.sessionName.value) {
                                                    await controller.updateSessionName(newName);
                                                       // <-- update local observable
                                                          controller.sessionName.value = newName;
                                                  }
                                                      print('New session name: ${controller.sessionName.value}');
                                                  Navigator.of(context).pop();
                                                },
                                                child: Container(
                                                  width: 100,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.zero,
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFFFF9800), Color(0xFFE91E63)],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'Save',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
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
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),


                      ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.menu, color: Colors.blue, size: 24),
                          onPressed: () { /* ... */ },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                      'Created ${controller.session.createdDate.day.toString().padLeft(2, '0')}/${controller.session.createdDate.month.toString().padLeft(2, '0')}/${controller.session.createdDate.year.toString().substring(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF828282),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 24),

              // Participants List
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.participants.length + 1,
                  itemBuilder: (context, index) {
                    if (index < controller.participants.length) {
                      final user = controller.participants[index];
                      Color borderColor;
                      if (user.name == 'Mark') {
                        borderColor = const Color(
                          0xFF2F80ED,
                        ); // Specific blue for Mark
                      } else if (user.name == 'John') {
                        borderColor = const Color(
                          0xFFEB5757,
                        ); // Specific red for John
                      } else if (user.name == 'Steve') {
                        borderColor = const Color(
                          0xFF27AE60,
                        ); // Specific green for Steve
                      } else {
                        borderColor =
                            Colors
                                .transparent; // Default or no border for others
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(user.avatarUrl),
                              backgroundColor: Colors.white,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Invite button
                      return Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFBDBDBD),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: IconButton(
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                                onPressed: () {
                                  _fetchPreviouslyInvitedUsers();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Obx(() => ConstrainedBox(
                                              constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                                            maxWidth: MediaQuery.of(context).size.width * 0.9,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                    const Text(
                                                      'Invite users ',
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                        fontWeight: FontWeight.w400,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                    GestureDetector(
                                                      onTap: () => Navigator.pop(context),
                                                          child: const Text(
                                                            'Done',
                                                            style: TextStyle(
                                                          color: Color(0xFF1976D2),
                                                          fontWeight: FontWeight.w600,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                const SizedBox(height: 18),
                                                    TextField(
                                                  controller: inviteEmailController,
                                                      decoration: InputDecoration(
                                                    hintText: 'Email address',
                                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                                        border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                      borderSide: const BorderSide(color: Colors.black),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                      ),
                                                    ),
                                                const SizedBox(height: 24),
                                                Center(
                                                  child: GestureDetector(
                                                    onTap: _isInvitingUser ? null : () async {
                                                      final email = inviteEmailController.text.trim();
                                                      if (email.isEmpty) {
                                                        Get.snackbar('Error', 'Please enter an email address', 
                                                          snackPosition: SnackPosition.BOTTOM, 
                                                          backgroundColor: Colors.red, 
                                                          colorText: Colors.white);
                                                        return;
                                                      }
                                                      setState(() {
                                                        _isInvitingUser = true;
                                                      });
                                                      await _inviteUser(email);
                                                      setState(() {
                                                        _isInvitingUser = false;
                                                      });
                                                    },
                                                    child: SizedBox(
                                                      width: 180,
                                                      height: 48,
                                                      child: Stack(
                                                        children: [
                                                          // Gradient border layer
                                                          Positioned.fill(
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.zero,
                                                                gradient: const LinearGradient(
                                                                  colors: [Color(0xFFFF914D), Color(0xFFFF006A)],
                                                                  begin: Alignment.centerLeft,
                                                                  end: Alignment.centerRight,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          // White background with margin for border effect
                                                          Positioned.fill(
                                                            child: Container(
                                                              margin: const EdgeInsets.all(2),
                                                              decoration: BoxDecoration(
                                                                color: Colors.white,
                                                                borderRadius: BorderRadius.zero,
                                                              ),
                                                              alignment: Alignment.center,
                                                              child: _isInvitingUser
                                                                  ? const SizedBox(
                                                                      width: 20,
                                                                      height: 20,
                                                                      child: CircularProgressIndicator(
                                                                        strokeWidth: 2,
                                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                                      ),
                                                                    )
                                                                  : const Text(
                                                          'Invite',
                                                          style: TextStyle(
                                                                        fontSize: 18,
                                                                        fontWeight: FontWeight.w400,
                                                                        color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                        ],
                                                        ),
                                                      ),
                                                    ),
                                                ),
                                                const SizedBox(height: 28),
                                                const Text(
                                                  'Previous users',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF828282),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Flexible(
                                                  child: _isLoadingInvitedUsers.value
                                                      ? const Center(child: CircularProgressIndicator())
                                                      : _previouslyInvitedUsers.isEmpty
                                                          ? const Center(
                                                              child: Padding(
                                                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                                                child: Text('No previous users', style: TextStyle(color: Colors.grey)),
                                                              ),
                                                            )
                                                          : ListView.separated(
                                                          shrinkWrap: true,
                                                              itemCount: _previouslyInvitedUsers.length,
                                                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                                                              itemBuilder: (context, index) {
                                                                final invite = _previouslyInvitedUsers[index];
                                                                final isPending = (invite['status'] ?? 'pending') == 'pending';
                                                                return Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                        invite['invitedEmail'] ?? '',
                                                                    style: const TextStyle(
                                                                          fontSize: 15,
                                                                          color: Colors.black,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                                    if (!isPending)
                                                                IconButton(
                                                                        icon: const Icon(Icons.add, color: Colors.black),
                                                                  onPressed: () {},
                                                                      ),
                                                                    if (isPending)
                                                            Row(
                                                              children: [
                                                                    Text(
                                                                      'Pending',
                                                                      style: TextStyle(
                                                                        fontSize: 13,
                                                                        color: Color(0xFF828282),
                                                                        fontWeight: FontWeight.w400,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 4),
                                                                    IconButton(
                                                                            icon: const Icon(Icons.close, color: Color(0xFFFF6B6B)),
                                                                            onPressed: () async {
                                                                              final currentUser = FirebaseAuth.instance.currentUser;
                                                                              if (currentUser == null || currentUser.email == null) {
                                                                                Get.snackbar('Error', 'User not authenticated', 
                                                                                  snackPosition: SnackPosition.BOTTOM, 
                                                                                  backgroundColor: Colors.red, 
                                                                                  colorText: Colors.white);
                                                                                return;
                                                                              }
                                                                              
                                                                              final invitationQuery = await FirebaseFirestore.instance
                                                                                  .collection('user_invitations')
                                                                                  .where('invitedEmail', isEqualTo: invite['invitedEmail'])
                                                                                  .where('sessionId', isEqualTo: controller.session.id)
                                                                                  .where('inviterEmail', isEqualTo: currentUser.email)
                                                                                  .get();
                                                                              if (invitationQuery.docs.isNotEmpty) {
                                                                                await invitationQuery.docs.first.reference.delete();
                                                                                _fetchPreviouslyInvitedUsers();
                                                                              }
                                                                            },
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                                );
                                                              },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        )),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invite',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Recordings / Lyrics Tabs
              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      onTap: controller.changeTab,
                      indicator: GradientUnderlineTabIndicator(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF914D), Color(0xFFFF006A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        thickness: 4,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: const Color(0xFF222222),
                      unselectedLabelColor: const Color(0xFFBDBDBD),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: 'Recordings'),
                        Tab(text: 'Lyrics'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Row with number of recordings (left) and sort button (right)
                    Obx(() => controller.selectedTabIndex.value == 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                          child: Row(
                        children: [
                          Obx(() {
                                final count = controller.recordings.length;
                                return Text(
                                  '$count recording${count == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF828282),
                                    fontWeight: FontWeight.w500,
                                      ),
                                );
                              }),
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
                        )
                      : const SizedBox.shrink()),
                                const SizedBox(height: 8),
                                Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Recordings tab
                          Obx(() {
                            if (controller.isRecordingsLoading.value) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final recordings = controller.recordings;
                            if (recordings.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.mic_off,
                                      size: 64,
                                      color: Color(0xFFBDBDBD),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No recordings yet',
                                      style: TextStyle(
                                        color: Color(0xFF959595),
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Start recording to see your audio here',
                                      style: TextStyle(
                                        color: Color(0xFFBDBDBD),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return RefreshIndicator(
                              color: Color(0xFFFF9800),
                              onRefresh: controller.refreshRecordings,
                                  child: ListView.separated(
                                    itemCount: recordings.length,
                                separatorBuilder: (_, __) => const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFF0F0F0),
                                        ),
                                    itemBuilder: (context, index) {
                                      final recording = recordings[index];
                                  final isRecording = recording.isRecording == true;
                                      return Slidable(
                                        key: ValueKey(recording.recordingId),
                                        endActionPane: ActionPane(
                                          motion: const DrawerMotion(),
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) {
                                            _showMoveDialog(_rootContext, widget.session.id, recording.recordingId);
                                              },
                                              backgroundColor: Colors.blueGrey[50]!,
                                              foregroundColor: Colors.blueGrey,
                                              icon: Icons.drive_file_move,
                                              label: 'Move',
                                            ),
                                            SlidableAction(
                                              onPressed: (context) async {
                                            final currentUser = FirebaseAuth.instance.currentUser;
                                            if (currentUser == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('You must be logged in to delete recordings.'), backgroundColor: Colors.red),
                                              );
                                              return;
                                            }
                                            if (recording.userId != null && recording.userId != currentUser.uid) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('You can only delete your own recordings.'), backgroundColor: Colors.red),
                                              );
                                              return;
                                            }
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                                    backgroundColor: Colors.white,
                                                    title: const Text('Delete Recording'),
                                                    content: const Text('Are you sure you want to delete this recording?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await controller.deleteRecording(recording.recordingId);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Recording deleted'), backgroundColor: Colors.red),
                                                  );
                                                }
                                              },
                                              backgroundColor: Colors.red[50]!,
                                              foregroundColor: Colors.red,
                                              icon: Icons.delete,
                                              label: 'Delete',
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                      onTap: () {
                                        print("recording.recordingId: "+recording.recordingId);
                                        print("recording.fileUrl: "+recording.fileUrl);
                                        // Show paused_recording screen as modal bottom sheet
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => SizedBox.expand(
                                            child: PausedRecording(
                                              recordingDocId: recording.recordingId,
                                              recordingFilePath: recording.fileUrl,
                                              recordingName: recording.name ?? recording.fileName,
                                              sessionName: widget.session.name,
                                              sessionId: widget.session.id,
                                            ),
                                          ),
                                        );
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
                                            // Left: Red dot if recording in progress
                                            if (isRecording)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8.0, top: 6.0),
                                                child: Image.asset(
                                                  'assets/images/ellipse.png',
                                                  width: 10,
                                                  height: 10,
                                                  color: const Color(0xFFEB5757),
                                                ),
                                              ),
                                            // Main content
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                      Flexible(
                                                        child: Text(
                                                            recording.name ?? recording.fileName,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                                  fontSize: 17,
                                                            color: Color(0xFF222222),
                                                                  ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${recording.createdAt.day.toString().padLeft(2, '0')}/${recording.createdAt.month.toString().padLeft(2, '0')}/${recording.createdAt.year.toString().substring(2)} ${recording.createdAt.hour.toString().padLeft(2, '0')}:${recording.createdAt.minute.toString().padLeft(2, '0')}',
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
                                                // User avatar and duration/status
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                // User avatar
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor: Colors.grey[200],
                                                  backgroundImage: (recording.userAvatarUrl.isNotEmpty)
                                                      ? NetworkImage(recording.userAvatarUrl)
                                                      : null,
                                                  child: (recording.userAvatarUrl.isEmpty)
                                                      ? Icon(
                                                        Icons.person,
                                                        size: 20,
                                                        color: Colors.grey[600],
                                                        )
                                                      : null,
                                                    ),
                                                    const SizedBox(height: 4),
                                                if (isRecording)
                                                    Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Image.asset(
                                                          'assets/images/recordingIcon.png',
                                                        width: 16,
                                                        height: 16,
                                                        color: const Color(0xFFEB5757),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Recording...',
                                                        style: TextStyle(
                                                          color: const Color(0xFFEB5757),
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Image.asset(
                                                        'assets/images/recordingIcon.png',
                                                          width: 14,
                                                          height: 14,
                                                        color: const Color(0xFFBDBDBD),
                                                        ),
                                                      const SizedBox(width: 4),
                                                        Text(
                                                          recording.duration,
                                                          style: TextStyle(
                                                          color: const Color(0xFFBDBDBD),
                                                            fontSize: 12,
                                                          fontWeight: FontWeight.w400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            );
                          }),
                          // Lyrics tab (unchanged)
                          const _LyricsTabImageExact(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ]),
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SizedBox.expand(child: NewRecordingScreen(sessionId: widget.session.id, sessionName: widget.session.name)),
            );
          },
          elevation: 0,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          child: Image.asset(
            'assets/images/centerButton.png',
            width: 64,
            height: 64,
            fit: BoxFit.contain,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Stack(
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
                currentIndex: 0, // Sessions tab is selected
                onTap: (index) {
          if (index == 0) {
                    // Navigate back to main navigation with sessions tab selected
                    Get.offAll(() => MainNavigation());
          } else if (index == 1) {
                    // Navigate back to main navigation with settings tab selected
                    final navController = Get.put(NavigationController(), permanent: true);
                    navController.changeTab(1);
                    Get.offAll(() => MainNavigation());
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
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchPreviouslyInvitedUsers() async {
    _isLoadingInvitedUsers.value = true;
    
    try {
      if (controller.session.id.isEmpty) {
        throw Exception('Invalid session ID');
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('User not authenticated');
      }

      final QuerySnapshot<Map<String, dynamic>> query = await FirebaseFirestore.instance
          .collection('user_invitations')
          .where('sessionId', isEqualTo: controller.session.id)
          .where('inviterEmail', isEqualTo: currentUser.email)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Failed to fetch invitations'),
          );

      if (!mounted) return;

      _previouslyInvitedUsers.value = query.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((data) =>
            data['invitedEmail'] != null &&
            data['status'] != null
          )
          .toList();
      _isLoadingInvitedUsers.value = false;
    } catch (e) {
      if (!mounted) return;

      _isLoadingInvitedUsers.value = false;
      _previouslyInvitedUsers.value = [];

      String errorMessage = 'Failed to load invited users';
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e is FirebaseException) {
        errorMessage = 'Database error: ${e.message}';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        isDismissible: true,
      );
    }
  }

  Future<void> _inviteUser(String inviteeEmail) async {
    try {
      final inviter = FirebaseAuth.instance.currentUser;
      if (inviter == null || inviteeEmail.isEmpty) {
        throw Exception('Invalid inviter or invitee email');
      }
      if (inviteeEmail == inviter.email) {
        Get.snackbar('Invalid Email', 'You cannot invite your own email address', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      
      // Check if user exists in Firestore users collection
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: inviteeEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        Get.snackbar('User Not Found', 'No registered user with this email.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }
      
      // Check if user has already been invited to this session by the current user
      final existingInvitationQuery = await FirebaseFirestore.instance
          .collection('user_invitations')
          .where('invitedEmail', isEqualTo: inviteeEmail)
          .where('sessionId', isEqualTo: controller.session.id)
          .where('inviterEmail', isEqualTo: inviter.email)
          .limit(1)
          .get();
      
      if (existingInvitationQuery.docs.isNotEmpty) {
        final existingInvitation = existingInvitationQuery.docs.first.data();
        final status = existingInvitation['status'] ?? 'pending';
        
        if (status == 'pending') {
          Get.snackbar('Already Invited', 'This user has already been invited to this session.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white);
        } else if (status == 'accepted') {
          Get.snackbar('Already Member', 'This user is already a member of this session.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue,
              colorText: Colors.white);
        } else {
          Get.snackbar('Already Invited', 'This user has already been invited to this session.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white);
        }
        return;
      }
      
      await FirebaseFirestore.instance.collection('user_invitations').add({
        'inviterEmail': inviter.email,
        'invitedEmail': inviteeEmail,
        'sessionId': controller.session.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Send FCM notification to the invited user
      try {
        await FCMNotificationService.sendSessionInvitationNotification(
          inviteeEmail: inviteeEmail,
          inviterEmail: inviter.email!,
          sessionId: controller.session.id,
          sessionName: controller.session.name,
        );
        print('FCM notification sent successfully for invitation to $inviteeEmail');
      } catch (e) {
        print('Failed to send FCM notification: $e');
        // Don't fail the invitation if FCM fails
      }
      
      inviteEmailController.clear();
      // Refresh the previously invited users list
      await _fetchPreviouslyInvitedUsers();
      Get.snackbar('Invitation Sent', 'User has been invited successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        inviteError = 'Failed to invite user. Please try again later.';
      });
      Get.snackbar(
        'Error',
        inviteError!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        isDismissible: true,
      );
    }
  }
}

class LyricsInputField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onSubmit;
  final VoidCallback? onAIGenerate;
  final Widget? leading;
  const LyricsInputField({required this.controller, required this.onSubmit, this.onAIGenerate, this.leading, super.key});

  @override
  State<LyricsInputField> createState() => _LyricsInputFieldState();
}

class _LyricsInputFieldState extends State<LyricsInputField> {
  bool _isAIGenerated = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Only mark as not AI-generated if the user types (not during AI animation)
    if (!_isTyping && _isAIGenerated && widget.controller.text.isNotEmpty) {
      setState(() {
        _isAIGenerated = false;
      });
    } else {
      setState(() {});
    }
  }

  // Call this when you set AI text with typewriter effect
  Future<void> setAIGeneratedText(String text) async {
    if (!mounted) return;
    
    setState(() {
      _isAIGenerated = true;
      _isTyping = true;
    });
    
    // Clear the text first
    widget.controller.text = '';
    
    // Typewriter effect
    for (int i = 0; i < text.length; i++) {
      if (!mounted) return;
      
      await Future.delayed(const Duration(milliseconds: 50)); // Adjust speed here
      widget.controller.text = text.substring(0, i + 1);
      
      // Move cursor to end
      widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
    }
    
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
        children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: const InputDecoration(
                  hintText: 'Write a new lyric...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
            style: TextStyle(
              fontSize: 15,
              color: _isAIGenerated ? Colors.grey[400] : Colors.black,
              // Add a subtle animation effect during typing
              decoration: _isTyping ? TextDecoration.underline : TextDecoration.none,
              decorationColor: _isTyping ? Colors.blue : Colors.transparent,
          ),
                minLines: 1,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                contextMenuBuilder: (context, editableTextState) {
                  final defaultItems = editableTextState.contextMenuButtonItems;
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: [
                      ContextMenuButtonItem(
                        onPressed: () async {

                          final selection = widget.controller.selection;
                          print("Rhyme button pressed $selection");
                          if (!selection.isValid || selection.isCollapsed) return;
                          final selectedWord = widget.controller.text.substring(selection.start, selection.end).trim();
                          Navigator.of(context).maybePop();
                          if (selectedWord.isNotEmpty) {
                            final rhyme = await showRhymeDialog(context, selectedWord);
                            if (rhyme != null) {
                              print('Using rhyme in input field: $rhyme');
                              print('Original text: ${widget.controller.text}');
                              // Replace the selected word with the rhyme
                              final text = widget.controller.text;
                              final newText = text.replaceRange(selection.start, selection.end, rhyme);
                              print('New text after replacement: $newText');
                              widget.controller.text = newText;
                              widget.controller.selection = TextSelection.collapsed(offset: selection.start + rhyme.length);
                            }
                          }
                        },
                        label: 'Rhyme',
                      ),
                      ...defaultItems,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        if (widget.controller.text.trim().isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.blue, size: 26),
                tooltip: 'Cancel',
                onPressed: () {
                  widget.controller.clear();
                },
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.blue, size: 26),
                tooltip: 'Done',
                onPressed: () {
                  final value = widget.controller.text.trim();
                  if (value.isNotEmpty) {
                    widget.onSubmit(value);
                    widget.controller.clear();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue, size: 26),
                tooltip: 'Refresh',
                onPressed: () {
                  if (widget.onAIGenerate != null) {
                    widget.onAIGenerate!();
                  }
                },
              ),
            ],
          ),
      ],
    );
  }
}

class _LyricsTabImageExact extends StatefulWidget {
  const _LyricsTabImageExact();
  @override
  State<_LyricsTabImageExact> createState() => _LyricsTabImageExactState();
}

class _LyricsTabImageExactState extends State<_LyricsTabImageExact> {
  final TextEditingController _verseController = TextEditingController();
  final TextEditingController _preChorusController = TextEditingController();
  final TextEditingController _chorusController = TextEditingController();
  final TextEditingController _bridgeController = TextEditingController();
  final LyricsController _lyricsController = LyricsController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<_LyricsInputFieldState> _verseKey = GlobalKey();
  final GlobalKey<_LyricsInputFieldState> _preChorusKey = GlobalKey();
  final GlobalKey<_LyricsInputFieldState> _chorusKey = GlobalKey();
  final GlobalKey<_LyricsInputFieldState> _bridgeKey = GlobalKey();

  @override
  void dispose() {
    _verseController.dispose();
    _preChorusController.dispose();
    _chorusController.dispose();
    _bridgeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get sessionId => (context.findAncestorWidgetOfExactType<SessionDetailView>()?.session.id ?? '');
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // Helper to get previous lyrics text for a section
  Future<String> _getPreviousLyricsText(String section) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('lyrics')
        .where('section', isEqualTo: section)
        .orderBy('createdAt')
        .get();
    final lines = snapshot.docs.map((doc) => doc['text'] as String).toList();
    return lines.join('\n');
  }

  // Handler to call OpenAI and set the suggestion in the controller
  Future<void> _suggestNextLine(BuildContext context, String section, TextEditingController controller, GlobalKey<_LyricsInputFieldState> key) async {
    final previousLyrics = await _getPreviousLyricsText(section);
    
    // Get current AI-generated text to avoid repetition
    final currentText = controller.text.trim();
    String avoidText = '';
    if (key.currentState?._isAIGenerated == true && currentText.isNotEmpty) {
      avoidText = '\n\nIMPORTANT: Do NOT repeat this exact line: "$currentText". Generate a completely different lyric line.';
    }
    
    final prompt =
        "Given the following $section lyrics of a song:\n$previousLyrics\nWrite ONLY the next lyric line that matches the tone and context. Do not include any explanation or preamble. Only output the lyric line.$avoidText";
    
    await key.currentState?.setAIGeneratedText('...'); // Show loading
    final suggestion = await AzureOpenAIService.instance.getChatCompletion(prompt: prompt);
    
    if (suggestion != null && suggestion.trim().isNotEmpty) {
      final newSuggestion = suggestion.trim();
      
      // Check if the new suggestion is too similar to the current text
      if (currentText.isNotEmpty && _isTextTooSimilar(currentText, newSuggestion)) {
        // If too similar, try one more time with stronger instruction
        final retryPrompt = 
            "Given the following $section lyrics of a song:\n$previousLyrics\nWrite ONLY the next lyric line that matches the tone and context. CRITICAL: The new line must be completely different from: '$currentText'. Generate something entirely new and unique. Only output the lyric line.";
        
        final retrySuggestion = await AzureOpenAIService.instance.getChatCompletion(prompt: retryPrompt);
        if (retrySuggestion != null && retrySuggestion.trim().isNotEmpty) {
          await key.currentState?.setAIGeneratedText(retrySuggestion.trim());
        } else {
          await key.currentState?.setAIGeneratedText(newSuggestion);
        }
      } else {
        await key.currentState?.setAIGeneratedText(newSuggestion);
      }
    } else {
      controller.text = '';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No suggestion from AI.'), backgroundColor: Colors.red),
      );
    }
  }

  // Helper method to check if two texts are too similar
  bool _isTextTooSimilar(String text1, String text2) {
    final words1 = text1.toLowerCase().split(' ');
    final words2 = text2.toLowerCase().split(' ');
    
    // Count common words
    int commonWords = 0;
    for (final word in words1) {
      if (words2.contains(word)) {
        commonWords++;
      }
    }
    
    // Calculate similarity percentage
    final similarity = commonWords / words1.length;
    
    // Consider too similar if more than 60% of words are the same
    return similarity > 0.6;
  }

  Widget _buildLyricsSection(String section, TextEditingController controller, GlobalKey<_LyricsInputFieldState> key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
          section,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
        StreamBuilder<List<LyricLine>>(
          stream: _lyricsController.streamLyrics(sessionId, section),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final lyrics = snapshot.data ?? [];
            return Column(
              children: [
                for (final lyric in lyrics)
          _SelectableLyricsLine(
                    text: lyric.text,
                    play: lyric.recordings.isNotEmpty,
                    recordings: lyric.recordings,
                    lyricId: lyric.id,
                    userId: lyric.userId, // <-- add this line
                    leading: GestureDetector(
                      onTap: () async {
                        await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SizedBox.expand(
                            child: NewRecordingScreen(
                              sessionId: sessionId,
                              sessionName: null,
                              lyricsDocId: lyric.id,
                            ),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/centerButton.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: LyricsInputField(
                    key: key,
                    controller: controller,
                    onSubmit: (value) async {
                      if (value.isNotEmpty && userId != null) {
                        await _lyricsController.addLyric(sessionId, section, value, userId!);
                      }
                    },
                    onAIGenerate: () => _suggestNextLine(context, section, controller, key),
                    leading: _PenPopupMenu(
                      onNextLine: () => _suggestNextLine(context, section, controller, key),
                      controller: controller,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLyricsSection('VERSE', _verseController, _verseKey),
          _buildLyricsSection('PRE CHORUS', _preChorusController, _preChorusKey),
          _buildLyricsSection('CHORUS', _chorusController, _chorusKey),
          _buildLyricsSection('BRIDGE', _bridgeController, _bridgeKey),
        ],
      ),
    );
  }
}

class _SelectableLyricsLine extends StatelessWidget {
  final String text;
  final bool play;
  final List<String> recordings;
  final bool removePadding;
  final Widget? leading;
  final Widget? nameTag;
  final TextEditingController? controller;
  final String? lyricId;
  final String userId;
  const _SelectableLyricsLine({
    required this.text,
    required this.play,
    required this.recordings,
    this.leading,
    this.nameTag,
    this.removePadding = false,
    this.controller,
    this.lyricId,
    required this.userId,
  });
  @override
  Widget build(BuildContext context) {
    final sessionWidget = context.findAncestorWidgetOfExactType<SessionDetailView>();
    final sessionId = sessionWidget?.session.id;
    final sessionName = sessionWidget?.session.name;
    return Padding(
      padding:
          removePadding
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical centering
        children: [
          // Record icon (leading)
          leading ?? GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => SizedBox.expand(
                  child: NewRecordingScreen(
                    sessionId: sessionId,
                    sessionName: null,
                  ),
                ),
              );
            },
            child: Image.asset(
              'assets/images/centerButton.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          if (play)
            GestureDetector(
              onTap: () async {
                if (recordings.length == 1) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => SizedBox.expand(
                      child: PausedRecording(
                        recordingDocId: recordings.first,
                        sessionId: sessionId,
                        sessionName: sessionName,
                      ),
                    ),
                  );
                } else if (recordings.length > 1) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: _PlayPopupMenu(
                        recordings: recordings,
                        sessionId: sessionId,
                        onRecordingSelected: (recordingId) {
                          Navigator.of(context).pop();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SizedBox.expand(
                              child: PausedRecording(
                                recordingDocId: recordingId,
                                sessionId: sessionId,
                                sessionName: sessionName,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
              child: Icon(Icons.play_arrow, size: 18, color: Colors.black),
            ),
          if (play) const SizedBox(width: 4),
          // Lyrics and author tag
          Expanded(
            child: LyricsWithAuthorTag(
              text: text,
              userId: userId,
              textStyle: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class LyricsWithAuthorTag extends StatelessWidget {
  final String text;
  final String userId;
  final TextStyle? textStyle;

  const LyricsWithAuthorTag({
    required this.text,
    required this.userId,
    this.textStyle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getFirstName(userId),
      builder: (context, snapshot) {
        final displayName = snapshot.data ?? 'Unknown';
        final tagColor = _getColor(displayName);
        return RichText(
          text: TextSpan(
            style: textStyle ?? DefaultTextStyle.of(context).style,
            children: [
              TextSpan(text: text),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 15), // Move tag up
                  child: _AuthorTagDisplay(
                    displayName: displayName,
                    tagColor: tagColor,
                  ),
                ),
              ),
          ],
          ),
        );
      },
    );
  }

  Future<String?> _getFirstName(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data()?['firstName'] as String?;
  }

  Color _getColor(String? name) {
    if (name == null) return Colors.red;
    if (name.toLowerCase() == 'mark') return Color(0xFF0076FF);
    if (name.toLowerCase() == 'steve') return Color(0xFF22C55E);
    return Color(0xFF0076FF);
  }
}

class _AuthorTagDisplay extends StatelessWidget {
  final String displayName;
  final Color tagColor;
  const _AuthorTagDisplay({required this.displayName, required this.tagColor, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The vertical bar
        Positioned(
          left: 0,
          bottom: -7,
          child: Container(
            width: 2,
            height: 20,
            color: tagColor,
          ),
        ),
        // The tag
        Container(
          margin: const EdgeInsets.only(left: 0),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
            color: tagColor,
            borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
            displayName,
        style: const TextStyle(
          color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 10,
        ),
      ),
        ),
      ],
    );
  }
}

class _TagPointerPainter extends CustomPainter {
  final Color color;
  _TagPointerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PenPopupMenu extends StatefulWidget {
  final VoidCallback? onNextLine;
  final TextEditingController? controller;
  const _PenPopupMenu({this.onNextLine, this.controller});
  @override
  State<_PenPopupMenu> createState() => _PenPopupMenuState();
}

class _PenPopupMenuState extends State<_PenPopupMenu> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to show/hide Rhyme button
  }

  void _showMenu() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final text = widget.controller?.text.trim() ?? '';
    final hasWord = text.isNotEmpty;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
            left: offset.dx,
              top: offset.dy - 120, // Place popup just below the button
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        'Generate...',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                          Navigator.of(context).pop();
                          widget.onNextLine?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          'Next line',
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        ),
                      ),
                    ),
                      if (hasWord)
                    InkWell(
                          onTap: () async {
                            Navigator.of(context).pop();
                            // Select the last word in the text field
                            final text = widget.controller?.text ?? '';
                            if (text.isNotEmpty) {
                              final words = text.split(' ');
                              final lastWord = words.isNotEmpty ? words.last : text;
                              final start = text.length - lastWord.length;
                              final end = text.length;
                              widget.controller?.selection = TextSelection(baseOffset: start, extentOffset: end);
                              final rhyme = await showRhymeDialog(context, lastWord);
                              if (rhyme != null && rhyme.isNotEmpty) {
                                final selection = widget.controller?.selection;
                                if (selection != null && selection.isValid && !selection.isCollapsed) {
                                  final newText = text.replaceRange(selection.start, selection.end, rhyme);
                                  widget.controller?.text = newText;
                                  widget.controller?.selection = TextSelection.collapsed(offset: selection.start + rhyme.length);
                                }
                              }
                            }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          'Rhyme',
                          style: TextStyle(fontSize: 15, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: _showMenu,
      child: Image.asset(
        'assets/images/pencil-ai-line.png',
        width: 28,
        height: 28,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PlayPopupMenu extends StatefulWidget {
  final List<String> recordings;
  final String? sessionId;
  final void Function(String recordingId)? onRecordingSelected;
  const _PlayPopupMenu({Key? key, required this.recordings, required this.sessionId, this.onRecordingSelected}) : super(key: key);
  @override
  State<_PlayPopupMenu> createState() => _PlayPopupMenuState();
}

class _PlayPopupMenuState extends State<_PlayPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
      child: ListView(
        shrinkWrap: true,
                  children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Select a recording to play', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ),
          for (final recordingId in widget.recordings)
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('sessions')
                  .doc(widget.sessionId)
                  .collection('recordings')
                  .doc(recordingId)
                  .get(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final name = data?['name'] ?? data?['fileName'] ?? 'Recording';
                return ListTile(
                  title: Text(name, style: const TextStyle(fontSize: 15)),
                  trailing: const Icon(Icons.play_arrow, color: Colors.black),
                      onTap: () {
                    if (widget.onRecordingSelected != null) {
                      widget.onRecordingSelected!(recordingId);
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RecordingOptionsSheet extends StatelessWidget {
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const _RecordingOptionsSheet({required this.onMove, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.drive_file_move, color: Colors.blueGrey),
            title: Text('Move'),
            onTap: onMove,
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete'),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

Future<void> saveDeviceToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;

  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

  // Add the token to the array (creates the array if it doesn't exist)
  await userDoc.set({
    'fcmTokens': FieldValue.arrayUnion([token])
  }, SetOptions(merge: true));
}

Future<void> sendNotificationToUser(String userId, Map<String, dynamic> notificationData) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);

  for (final token in tokens) {
    // Replace this with your actual notification sending logic (e.g., call a Cloud Function or FCM API)
    await sendFcmToToken(token, notificationData);
  }
}

// Example stub for sending FCM (replace with your actual implementation)
Future<void> sendFcmToToken(String token, Map<String, dynamic> data) async {
  // Use your backend or a Cloud Function to send the notification to this token
}

class GradientUnderlineTabIndicator extends Decoration {
  final double thickness;
  final Gradient gradient;

  const GradientUnderlineTabIndicator({required this.gradient, this.thickness = 4});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GradientUnderlinePainter(this, onChanged);
  }
}

class _GradientUnderlinePainter extends BoxPainter {
  final GradientUnderlineTabIndicator decoration;

  _GradientUnderlinePainter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = Offset(
      offset.dx,
      (configuration.size!.height - decoration.thickness) + offset.dy,
    ) &
        Size(configuration.size!.width, decoration.thickness);

    final Paint paint = Paint()
      ..shader = decoration.gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);
  }
}

class MoveRecordingDialog extends StatelessWidget {
  final String currentSessionId;
  final String recordingId;
  final Map<String, dynamic> recordingData;
  final BuildContext rootContext;
  const MoveRecordingDialog({required this.currentSessionId, required this.recordingId, required this.recordingData, required this.rootContext, super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AlertDialog(
        title: Text('Error'),
        content: Text('You must be logged in.'),
      );
    }
    return AlertDialog(
      backgroundColor: Colors.white, // Match invite dialog
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match invite dialog if rounded
      ),
      title: const Text('Move Recording to Session',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
      content: SizedBox(
        width: 300,
        child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('sessions')
              .where('hostId', isEqualTo: user.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No sessions found.');
            }
            final sessions = snapshot.data!.docs.where((doc) => doc.id != currentSessionId).toList();
            if (sessions.isEmpty) {
              return const Text('No other sessions available.');
            }
            // Sort sessions by createdAt descending
            final sortedSessions = List.from(sessions)
              ..sort((a, b) {
                final aDate = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                final bDate = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                return bDate.compareTo(aDate); // Descending
              });
            return SizedBox(
              height: 300,
              width: 350,
              child: ListView.separated(
                itemCount: sortedSessions.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF0F0F0),
                ),
                itemBuilder: (context, index) {
                  final session = sortedSessions[index];
                  final data = session.data();
                  final name = data['name'] ?? 'Untitled';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final users = (data['users'] as List?) ?? [];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await moveRecordingToSession(
                        context: rootContext,
                        fromSessionId: currentSessionId,
                        toSessionId: session.id,
                        recordingId: recordingId,
                        recordingData: recordingData,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Session info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                                if (createdAt != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${createdAt.day.toString().padLeft(2, '0')}/'
                                    '${createdAt.month.toString().padLeft(2, '0')}/'
                                    '${createdAt.year.toString().substring(2)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF828282),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Avatars and recordings count
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var user in users.take(3))
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundImage: user['avatarUrl'] != null
                                            ? NetworkImage(user['avatarUrl'])
                                            : null,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('sessions')
                                    .doc(session.id)
                                    .collection('recordings')
                                    .get(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.docs.length ?? 0;
                                  return Text(
                                    '$count recordings',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<void> moveRecordingToSession({
  required BuildContext context,
  required String fromSessionId,
  required String toSessionId,
  required String recordingId,
  required Map<String, dynamic> recordingData,
}) async {
  try {
    final fromRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(fromSessionId)
        .collection('recordings')
        .doc(recordingId);
    final toRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(toSessionId)
        .collection('recordings')
        .doc(); // new doc ID

    // Remove the old recordingId from the data, set the new one
    final newData = Map<String, dynamic>.from(recordingData);
    newData['recordingId'] = toRef.id;
    newData['createdAt'] = FieldValue.serverTimestamp(); // Optionally update timestamp

    await toRef.set(newData);
    await fromRef.delete();

    // Remove the old recordingId from all lyrics in the old session
    final lyricsQuery = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(fromSessionId)
        .collection('lyrics')
        .where('recordings', arrayContains: recordingId)
        .get();
    for (final lyricDoc in lyricsQuery.docs) {
      final lyricRef = lyricDoc.reference;
      final lyricData = lyricDoc.data();
      // Remove old recordingId, add new one
      await lyricRef.update({
        'recordings': FieldValue.arrayRemove([recordingId])
      });
      await lyricRef.update({
        'recordings': FieldValue.arrayUnion([toRef.id])
      });
      // Copy lyric to new session's lyrics subcollection
      final newLyricData = Map<String, dynamic>.from(lyricData);
      List recordingsList = List.from(newLyricData['recordings'] ?? []);
      // Remove old, add new recordingId
      recordingsList.remove(recordingId);
      if (!recordingsList.contains(toRef.id)) {
        recordingsList.add(toRef.id);
      }
      newLyricData['recordings'] = recordingsList;
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(toSessionId)
          .collection('lyrics')
          .add(newLyricData);
      // Delete lyric from old session
      await lyricRef.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording moved successfully.'), backgroundColor: Colors.green),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to move recording: $e'), backgroundColor: Colors.red),
    );
  }
}

// Add the rhyme dialog
Future<String?> showRhymeDialog(BuildContext context, String word) async {
  int selectedSyllables = 1;
  List<String> rhymes = [];
  bool loading = true;
  bool initialized = false;
  String? selectedRhyme;
  final refreshRhymes = (void Function(void Function()) setState) async {
    setState(() => loading = true);
    final prompt =
        'List 10 English words that rhyme with "$word" and have $selectedSyllables syllable${selectedSyllables > 1 ? 's' : ''}. Only output the words, separated by newlines.';
    final response = await AzureOpenAIService.instance.getChatCompletion(prompt: prompt);
    rhymes = response?.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
    setState(() => loading = false);
  };
  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (!initialized) {
            initialized = true;
            refreshRhymes(setState);
          }
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Done', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Rhymes with "$word"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFE0E0E0), width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Number of syllables:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: selectedSyllables,
                          items: [1, 2, 3, 4].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              selectedSyllables = val;
                              refreshRhymes(setState);
                            }
                          },
                          underline: SizedBox(),
                          elevation: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  loading
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                      : rhymes.isEmpty
                          ? const Text('No rhymes found.', style: TextStyle(color: Colors.grey))
                          : SizedBox(
                              height: 200,
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: ListView(
                                  children: rhymes.map((r) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: GestureDetector(
                                      onTap: () {
                                        selectedRhyme = r;
                                        print('Selected rhyme: $selectedRhyme');
                                        print('Original word: $word');
                                        print('Selected rhyme from dialog: $r');
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(r, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  )).toList(),
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
  return selectedRhyme;
}

