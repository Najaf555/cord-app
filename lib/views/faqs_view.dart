import 'package:Cord/views/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import '../utils/responsive.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? expandedIndex;
  TextEditingController searchController = TextEditingController();
  final NavigationController navController = Get.put(NavigationController());

  final List<Map<String, String>> faqData = [
    {
      'question': 'FAQ Question',
      'answer':
          'Lorem ipsum dolor sit amet consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.'
    },
    {'question': 'FAQ Question', 'answer': 'Answer for FAQ question 2'},
    {'question': 'FAQ Question', 'answer': 'Answer for FAQ question 3'},
    {'question': 'FAQ Question', 'answer': 'Answer for FAQ question 4'},
    {'question': 'FAQ Question', 'answer': 'Answer for FAQ question 5'},
    {'question': 'FAQ Question', 'answer': 'Answer for FAQ question 6'},
    {'question': 'FAQ Question', 'answer': 'Answer for FAQ question 7'},
  ];

  void _onTabSelected(int index) {
    navController.changeTab(index);
    Get.offAll(() => MainNavigation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FAQs',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // FAQ List
          Expanded(
            child: ListView.builder(
              itemCount: faqData.length,
              itemBuilder: (context, index) {
                bool isExpanded = expandedIndex == index;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: isExpanded ? Colors.grey[100] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      faqData[index]['question']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: Colors.grey[600],
                    ),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        expandedIndex = expanded ? index : null;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faqData[index]['answer']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Stack(
        children: [
          // Top border line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, color: const Color(0xFFE0E0E0)),
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
              child: Obx(
                () => BottomNavigationBar(
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
                  currentIndex: navController.selectedIndex.value,
                  onTap: _onTabSelected,
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}