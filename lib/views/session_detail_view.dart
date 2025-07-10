import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_detail_controller.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'new_recording.dart';
import '../controllers/navigation_controller.dart';
import '../views/main_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class SessionDetailView extends StatefulWidget {
  const SessionDetailView({super.key});

  @override
  State<SessionDetailView> createState() => _SessionDetailViewState();
}

class _SessionDetailViewState extends State<SessionDetailView>
    with SingleTickerProviderStateMixin {
  final SessionDetailController controller =
      Get.find<SessionDetailController>();
  late TabController _tabController;
  final TextEditingController inviteEmailController = TextEditingController();
  final _previouslyInvitedUsers = <Map<String, dynamic>>[].obs;
  final _isLoadingInvitedUsers = false.obs;
  bool _isInvitingUser = false; // Loading state for invite user functionality
  String? inviteError;
  String currentUserEmail = '';

  @override
  void initState() {
    super.initState();
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
    // Fetch recordings for the hardcoded session on view open
    controller.loadRecordingsFromFirestore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    inviteEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF222222), size: 24),
                  //   onPressed: () {
                  //     Get.find<NavigationController>().showSessionsList();
                  //   },
                  // ),
                  // const SizedBox(height: 100),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Obx(() => 
                              // Use a flexible widget to prevent overflow and auto-resize font
                              Flexible(
                                child: Text(
                                  controller.sessionName.value,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF222222),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
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
                                                  }
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
                                                  child: Container(
                                                    margin: const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.zero,
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'Save',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w400,
                                                          color: Colors.black,
                                                        ),
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${controller.session.createdDate.day.toString().padLeft(2, '0')}/'
                          '${controller.session.createdDate.month.toString().padLeft(2, '0')}/'
                          '${controller.session.createdDate.year.toString().substring(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF828282),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(
                      0.0,
                      0.0,
                    ), // Adjust this value to move the icon up/down
                    child: IconButton(
                      icon: Image.asset(
                        'assets/images/menuIcon.png',
                        width: 30,
                        height: 30,
                        color: const Color(0xFF2F80ED),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
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
                      indicatorColor: const Color(0xFFFF6B6B),
                      indicatorSize: TabBarIndicatorSize.label,
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
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Recordings Tab Content
                          Obx(() {
                            final recordings = controller.sortedRecordings;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${recordings.length} recordings',
                                      style: const TextStyle(
                                        color: Color(0xFF959595),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: controller.toggleSortOrder,
                                      child: Obx(() => Icon(
                                      Icons.swap_vert,
                                        color: controller.isDescendingOrder.value
                                            ? const Color(0xFF2F80ED)
                                            : const Color(0xFF222222),
                                      size: 20,
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: recordings.length,
                                    separatorBuilder:
                                        (_, __) => const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Color(0xFFF0F0F0),
                                        ),
                                    itemBuilder: (context, index) {
                                      final recording = recordings[index];
                                      return Slidable(
                                        key: ValueKey(recording.recordingId),
                                        endActionPane: ActionPane(
                                          motion: const DrawerMotion(),
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) {
                                                // Move action (implement as needed)
                                              },
                                              backgroundColor: Colors.blueGrey[50]!,
                                              foregroundColor: Colors.blueGrey,
                                              icon: Icons.drive_file_move,
                                              label: 'Move',
                                            ),
                                            SlidableAction(
                                              onPressed: (context) async {
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
                                          onTap: () {},
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Recording name and date
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          if (recording.name ==
                                                              'New Recording')
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    right: 6.0,
                                                                  ),
                                                              child: Image.asset(
                                                                'assets/images/ellipse.png',
                                                                width: 8,
                                                                height: 8,
                                                                color:
                                                                    const Color(
                                                                      0xFFEB5757,
                                                                    ),
                                                              ),
                                                            ),
                                                          if (recording.duration == '00:00.00')
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    right: 4.0,
                                                                  ),
                                                              child: Image.asset(
                                                                'assets/images/ellipse.png',
                                                                width: 8,
                                                                height: 8,
                                                                color:
                                                                    const Color(
                                                                      0xFFEB5757,
                                                                    ),
                                                              ),
                                                            ),
                                                          Text(
                                                            recording.name ?? recording.fileName,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 17,
                                                                  color: Color(
                                                                    0xFF222222,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${recording.createdAt.day.toString().padLeft(2, '0')}/${recording.createdAt.month.toString().padLeft(2, '0')}/${recording.createdAt.year.toString().substring(2)} ${recording.createdAt.hour.toString().padLeft(2, '0')}:${recording.createdAt.minute.toString().padLeft(2, '0')}',
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Color(
                                                            0xFF828282,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w400,
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
                                                    // User avatar placeholder - can be enhanced to fetch user info from userId
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor: Colors.grey[200],
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 20,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // Show completed recording icon
                                                        Image.asset(
                                                          'assets/images/recordingIcon.png',
                                                          width: 14,
                                                          height: 14,
                                                          color: const Color(
                                                            0xFFBDBDBD,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          recording.duration,
                                                          style: TextStyle(
                                                            color: const Color(
                                                              0xFFBDBDBD,
                                                            ),
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w400,
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
                                ),
                              ],
                            );
                          }),
                          // Lyrics Tab Content (custom, matches image)
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
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SizedBox.expand(child: NewRecordingScreen(sessionId: controller.session.id)),
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

class _LyricsTabImageExact extends StatelessWidget {
  const _LyricsTabImageExact();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VERSE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          _SelectableLyricsLine(text: 'Heaven only knows', play: true),
          _SelectableLyricsLine(text: 'Where my body goes'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: _SelectableLyricsLine(text: 'Floating when you hold me'),
              ),
              const SizedBox(width: 8),
              _NameTag(label: 'Mark', color: Color(0xFF1976D2)),
            ],
          ),
          const SizedBox(height: 8),
          _SelectableLyricsLine(text: 'More than physical', play: true),
          _SelectableLyricsLine(text: "It's deeper in my soul"),
          _SelectableLyricsLine(text: 'The Taste of you is golden'),
          const SizedBox(height: 24),
          Text(
            'PRE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          _SelectableLyricsLine(
            text: "When it feels like I'm running out of time",
          ),
          _SelectableLyricsLine(
            text: "I know that you'll breath me back again",
          ),
          _SelectableLyricsLine(text: "When I'm in danger you're my saviour"),
          const SizedBox(height: 24),
          Row(children: [_PenPopupMenu()]),
        ],
      ),
    );
  }
}

class _SelectableLyricsLine extends StatelessWidget {
  final String text;
  final bool play;
   final bool removePadding = false;
  const _SelectableLyricsLine({
    required this.text,
    this.play = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          removePadding
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (play) ...[_PlayPopupMenu(), const SizedBox(width: 4)],
          Flexible(child: _CustomSelectableText(text: text)),
        ],
      ),
    );
  }
}

class _CustomSelectableText extends StatelessWidget {
  final String text;
  const _CustomSelectableText({required this.text});
  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: const TextStyle(fontSize: 16),
      contextMenuBuilder: (context, selectableTextState) {
        final defaultItems = selectableTextState.contextMenuButtonItems;
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableTextState.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              label: 'Rhyme',
            ),
            ...defaultItems,
          ],
        );
      },
    );
  }
}

class _NameTag extends StatelessWidget {
  final String label;
  final Color color;
  const _NameTag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _PenPopupMenu extends StatefulWidget {
  @override
  State<_PenPopupMenu> createState() => _PenPopupMenuState();
}

class _PenPopupMenuState extends State<_PenPopupMenu> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showMenu() {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx,
            top: offset.dy - 70,
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
                        _removeMenu();
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
                    InkWell(
                      onTap: () {
                        _removeMenu();
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
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: () {
        if (_overlayEntry == null) {
          _showMenu();
        } else {
          _removeMenu();
        }
      },
      child: Icon(Icons.edit, color: Colors.blue, size: 28),
    );
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }
}

class _PlayPopupMenu extends StatefulWidget {
  @override
  State<_PlayPopupMenu> createState() => _PlayPopupMenuState();
}

class _PlayPopupMenuState extends State<_PlayPopupMenu> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showMenu() {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx,
            top: offset.dy + 28,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 170,
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
                        'Play from...',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _removeMenu();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Melody idea',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.play_arrow, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _removeMenu();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Harmony',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.play_arrow, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: () {
        if (_overlayEntry == null) {
          _showMenu();
        } else {
          _removeMenu();
        }
      },
      child: Icon(Icons.play_arrow, size: 18, color: Colors.black),
    );
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
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

class _GradientBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFFFF914D), Color(0xFFFF006A)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(1), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
