import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_detail_controller.dart';
import '../views/new_recording.dart';

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
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF2F80ED),
                                size: 24,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
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
                                                      BorderRadius.circular(0),
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
                                                            color: Colors.black,
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
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          0,
                                                        ),
                                                    side: const BorderSide(
                                                      color: Color(0xFFFF6B6B),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Save',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
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
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
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
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  'Preview Users',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF222222),
                                                    fontWeight: FontWeight.w500,
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
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'mark@example.com',
                                                            style:
                                                                const TextStyle(
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
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'john@example.com',
                                                            style:
                                                                const TextStyle(
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
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              const BoxConstraints(),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'steve@example.com',
                                                            style:
                                                                const TextStyle(
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
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Text(
                                                              'pending',
                                                              style: TextStyle(
                                                                fontSize: 12,
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
                                                              onPressed: () {},
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
                                            ],
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
                                      return InkWell(
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        if (recording.status ==
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
                                                        if (recording.status ==
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
                                                      '${recording.dateTime.day.toString().padLeft(2, '0')}/'
                                                      '${recording.dateTime.month.toString().padLeft(2, '0')}/'
                                                      '${recording.dateTime.year.toString().substring(2)} '
                                                      '${recording.dateTime.hour.toString().padLeft(2, '0')}:${recording.dateTime.minute.toString().padLeft(2, '0')}',
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
                                                mainAxisSize: MainAxisSize.min,
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
                                                                (recording
                                                                            .user!
                                                                            .name ==
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
                                                          ), // Apply red color to the image
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
                                                          ), // Apply red color to the image
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
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                          // Lyrics Tab Content (Placeholder)
                          const Center(child: Text('Lyrics Tab Content')),
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
