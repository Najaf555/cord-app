import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_detail_controller.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/date_util.dart';
import '../utils/validators.dart';
import '../utils/responsive.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                            const Text(
                              'New Session',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF222222),
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
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Edit Session Name',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              TextField(
                                                decoration: InputDecoration(
                                                  hintText: 'Session Name',
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 14,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          0,
                                                        ),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              0,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color:
                                                              Colors.grey[300]!,
                                                          width: 1,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              0,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color:
                                                                  Colors.black,
                                                              width: 1,
                                                            ),
                                                      ),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 14,
                                                      ),
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.white,
                                                    foregroundColor:
                                                        Colors.black,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            0,
                                                          ),
                                                      side: const BorderSide(
                                                        color: Color(
                                                          0xFFFF6B6B,
                                                        ),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Save',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Invite users by email',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text(
                                                        'Done',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF2F80ED,
                                                          ),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),
                                                TextField(
                                                  decoration: InputDecoration(
                                                    hintText: 'Email Address',
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 14,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            0,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color:
                                                                Colors
                                                                    .grey[300]!,
                                                            width: 1,
                                                          ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                0,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color:
                                                                    Colors
                                                                        .black,
                                                                width: 1,
                                                              ),
                                                        ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 14,
                                                        ),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 48,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      // Handle invite action
                                                      Navigator.pop(context);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.white,
                                                      foregroundColor:
                                                          Colors.black,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              0,
                                                            ),
                                                        side: const BorderSide(
                                                          color: Color(
                                                            0xFFFF6B6B,
                                                          ),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Invite',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    'Preview Users',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF222222),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxHeight:
                                                          180, // or whatever max height you want
                                                    ),
                                                    child: ListView(
                                                      shrinkWrap: true,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'mark@example.com',
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                    0xFF000000,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons.add,
                                                                color: Color(
                                                                  0xFF000000,
                                                                ),
                                                                size: 20,
                                                              ),
                                                              onPressed: () {},
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'john@example.com',
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                    0xFF000000,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons.add,
                                                                color: Color(
                                                                  0xFF000000,
                                                                ),
                                                                size: 20,
                                                              ),
                                                              onPressed: () {},
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'steve@example.com',
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                    0xFF000000,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Text(
                                                                  'pending',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        Color.fromARGB(
                                                                          255,
                                                                          138,
                                                                          123,
                                                                          123,
                                                                        ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(
                                                                    Icons.close,
                                                                    color: Color(
                                                                      0xFFEB5757,
                                                                    ),
                                                                    size: 20,
                                                                  ),
                                                                  onPressed:
                                                                      () {},
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  constraints:
                                                                      const BoxConstraints(),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
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
                              fontWeight: FontWeight.w500,
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
                            final recordings = controller.recordings;
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
                                    const Icon(
                                      Icons.swap_vert,
                                      color: Color(0xFF222222),
                                      size: 20,
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
                                        key: ValueKey(recording.id ?? index),
                                        endActionPane: ActionPane(
                                          motion: const DrawerMotion(),
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) {
                                                // Move action
                                              },
                                              backgroundColor:
                                                  Colors.blueGrey[50]!,
                                              foregroundColor: Colors.blueGrey,
                                              icon: Icons.drive_file_move,
                                              label: 'Move',
                                            ),
                                            SlidableAction(
                                              onPressed: (context) {
                                                // Delete action
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                                          if (recording
                                                                  .status ==
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
                                                          if (recording
                                                                  .status ==
                                                              'Recording...')
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
                                                            recording.name,
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
                                                        '${recording.dateTime.day.toString().padLeft(2, '0')}/${recording.dateTime.month.toString().padLeft(2, '0')}/${recording.dateTime.year.toString().substring(2)} ${recording.dateTime.hour.toString().padLeft(2, '0')}:${recording.dateTime.minute.toString().padLeft(2, '0')}',
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
                                                    if (recording.user != null)
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundImage:
                                                            NetworkImage(
                                                              recording
                                                                  .user!
                                                                  .avatarUrl,
                                                            ),
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  (recording.user!.name ==
                                                                          'Mark')
                                                                      ? const Color(
                                                                        0xFF2F80ED,
                                                                      )
                                                                      : (recording
                                                                              .user!
                                                                              .name ==
                                                                          'John')
                                                                      ? const Color(
                                                                        0xFFEB5757,
                                                                      )
                                                                      : (recording
                                                                              .user!
                                                                              .name ==
                                                                          'Steve')
                                                                      ? const Color(
                                                                        0xFF27AE60,
                                                                      )
                                                                      : Colors
                                                                          .transparent,
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (recording.status ==
                                                            'Recording...')
                                                          Image.asset(
                                                            'assets/images/recordingIcon.png',
                                                            width: 14,
                                                            height: 14,
                                                            color: const Color(
                                                              0xFFEB5757,
                                                            ),
                                                          ),
                                                        if (recording.status ==
                                                            'Recording...')
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                        if (recording.status ==
                                                            'completed')
                                                          Image.asset(
                                                            'assets/images/recordingIcon.png',
                                                            width: 14,
                                                            height: 14,
                                                            color: const Color(
                                                              0xFFBDBDBD,
                                                            ),
                                                          ),
                                                        if (recording.status ==
                                                            'completed')
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                        Text(
                                                          recording.status ==
                                                                  'Recording...'
                                                              ? 'Recording...'
                                                              : recording
                                                                  .duration!,
                                                          style: TextStyle(
                                                            color:
                                                                recording.status ==
                                                                        'Recording...'
                                                                    ? const Color(
                                                                      0xFFEB5757,
                                                                    )
                                                                    : const Color(
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
    );
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
  final bool removePadding;
  const _SelectableLyricsLine({
    required this.text,
    this.play = false,
    this.removePadding = false,
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
