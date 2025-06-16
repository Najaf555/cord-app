import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sessionate/views/session_detail_view.dart';
import '../controllers/session_controller.dart';
import '../controllers/session_detail_controller.dart';
import '../controllers/navigation_controller.dart';

class SessionsView extends StatelessWidget {
  SessionsView({super.key});

  final SessionController controller = Get.put(SessionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Color(0xFF2F80ED), size: 30),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 10,
                        top: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(0xFFEB5757),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
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
                    hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.search, color: Color(0xFF222222)),
                    ),
                    suffixIconConstraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: () {
                      // Find the 'Free Falling v2' session from the controller's mock data
                      final freeFallingSession = controller.sessions.firstWhere(
                        (session) => session.name == 'Free Falling v2',
                        orElse: () => controller.sessions.first, // Fallback if not found
                      );
                      // Navigate to SessionDetailView by setting currentSession in NavigationController
                      Get.find<NavigationController>().showSessionDetails(freeFallingSession);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Create Session',
                      style: TextStyle(fontSize: 22, color: Color(0xFF222222), fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final sessions = controller.filteredSessions;
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${sessions.length} sessions',
                            style: const TextStyle(color: Color(0xFF959595), fontSize: 13, fontWeight: FontWeight.w400),
                          ),
                          const Spacer(),
                          const Icon(Icons.swap_vert, color: Color(0xFF000000), size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: sessions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Session name and date
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.name,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF222222)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${session.dateTime.day.toString().padLeft(2, '0')}/'
                                            '${session.dateTime.month.toString().padLeft(2, '0')}/'
                                            '${session.dateTime.year.toString().substring(2)} '
                                            '${session.dateTime.hour.toString().padLeft(2, '0')}:${session.dateTime.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF828282), fontWeight: FontWeight.w400),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Avatars and recordings
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: session.users.map((user) => Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                            child: CircleAvatar(
                                              radius: 18,
                                              backgroundImage: NetworkImage(user.avatarUrl),
                                              backgroundColor: Colors.white,
                                            ),
                                          )).toList(),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${session.recordingsCount} recordings',
                                          style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12, fontWeight: FontWeight.w400),
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
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
} 