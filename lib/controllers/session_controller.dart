import 'package:get/get.dart' hide Rx;
import '../models/session.dart';
import '../models/user.dart' as app_user;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class SessionController extends GetxController {
  var sessions = <Session>[].obs;
  var searchQuery = ''.obs;
  var isLoading = false.obs;
  var isAuthenticated = false.obs;
  var isDescendingOrder = true.obs; // true = newest first, false = oldest first

  @override
  void onInit() {
    super.onInit();
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      isAuthenticated.value = user != null;
      if (user != null) {
        print('User authenticated: ${user.uid}');
        loadSessionsFromFirestore();
      } else {
        print('User signed out');
        sessions.clear();
      }
    });
    
    // Check if user is already authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      isAuthenticated.value = true;
      print('User already authenticated: ${currentUser.uid}');
      loadSessionsFromFirestore();
    } else {
      print('No user authenticated initially');
      // Load mock data initially
      loadMockSessions();
    }
  }

  Future<void> loadSessionsFromFirestore() async {
    try {
      isLoading.value = true;
      
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user found - falling back to mock data');
        loadMockSessions();
        return;
      }

      print('Loading sessions for user: ${currentUser.uid}');

      // First, let's see what sessions exist in the database (for debugging)
      final allSessionsSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .get();
      
      print('Total sessions in database: ${allSessionsSnapshot.docs.length}');
      
      // Show all sessions for debugging
      for (var doc in allSessionsSnapshot.docs) {
        final data = doc.data();
        print('Session ${doc.id}: ${doc.data()}');
        print('  - hostId: ${data['hostId']}');
        print('  - current user UID: ${currentUser.uid}');
        print('  - hostId matches current user: ${data['hostId'] == currentUser.uid}');
      }

      // Now try to fetch sessions for the current user
      // Temporarily fetch ALL sessions to debug
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          // .where('hostId', isEqualTo: currentUser.uid) // Temporarily commented out to see all sessions
          // .orderBy('createdAt', descending: true) // Temporarily commented out until index is created
          .get();

      print('Found ${sessionsSnapshot.docs.length} sessions for current user');

      final List<Session> sessionsList = [];

      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        print('Processing session document: ${doc.id}');
        print('Session data: $data');
        
        // Create dummy users for now (as requested)
        final dummyUsers = [
          app_user.User(
            id: '1', 
            name: 'User1', 
            avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg'
          ),
          app_user.User(
            id: '2', 
            name: 'User2', 
            avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg'
          ),
          app_user.User(
            id: '3', 
            name: 'User3', 
            avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg'
          ),
        ];

        // Parse timestamps
        DateTime createdAt = DateTime.now();
        DateTime updatedAt = DateTime.now();
        
        if (data['createdAt'] != null) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['updatedAt'] != null) {
          updatedAt = (data['updatedAt'] as Timestamp).toDate();
        }

        // Create session object
        final session = Session(
          id: doc.id,
          name: data['name'] ?? 'Untitled Session',
          dateTime: updatedAt, // Using updatedAt as the session date
          createdDate: createdAt,
          users: dummyUsers, // Using dummy users for now
          recordingsCount: 0, // Using 0 as dummy recording count for now
        );

        sessionsList.add(session);
        print('Added session: ${session.name}');
      }

      if (sessionsList.isEmpty) {
        print('No sessions found for current user - falling back to mock data');
        loadMockSessions();
        return;
      }

      // Sort sessions by createdAt based on current sort order
      if (isDescendingOrder.value) {
        sessionsList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      } else {
        sessionsList.sort((a, b) => a.createdDate.compareTo(b.createdDate));
      }

      sessions.value = sessionsList;
      print('Successfully loaded ${sessionsList.length} sessions from Firestore');
      
    } catch (e) {
      print('Error loading sessions from Firestore: $e');
      print('Stack trace: ${StackTrace.current}');
      // Fallback to mock data if Firestore fails
      loadMockSessions();
    } finally {
      isLoading.value = false;
    }
  }

  void loadMockSessions() {
    final users = [
      app_user.User(id: '1', name: 'User1', avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg'),
      app_user.User(id: '2', name: 'User2', avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg'),
      app_user.User(id: '3', name: 'User3', avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg'),
      app_user.User(id: '4', name: 'User4', avatarUrl: 'https://randomuser.me/api/portraits/men/4.jpg'),
      app_user.User(id: '5', name: 'User5', avatarUrl: 'https://randomuser.me/api/portraits/men/5.jpg'),
    ];
    sessions.value = [
      Session(
        id: '1',
        name: 'Spellbound',
        dateTime: DateTime(2024, 10, 19, 13, 50),
        createdDate: DateTime(2024, 10, 15),
        users: users,
        recordingsCount: 14,
      ),
      Session(
        id: '2',
        name: 'Remedy',
        dateTime: DateTime(2024, 10, 16, 18, 25),
        createdDate: DateTime(2024, 10, 10),
        users: [users[1], users[2], users[3]],
        recordingsCount: 7,
      ),
      Session(
        id: '3',
        name: 'Lighthouse',
        dateTime: DateTime(2024, 9, 9, 11, 44),
        createdDate: DateTime(2024, 9, 5),
        users: [users[2], users[4]],
        recordingsCount: 9,
      ),
      Session(
        id: '4',
        name: 'Free Falling v2',
        dateTime: DateTime(2024, 12, 30, 13, 50),
        createdDate: DateTime(2024, 12, 30),
        users: [users[0], users[1], users[2]],
        recordingsCount: 3,
      ),
    ];
  }

  List<Session> get filteredSessions {
    if (searchQuery.value.isEmpty) {
      return sessions;
    }
    return sessions
        .where((s) => s.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Refresh sessions from Firestore
  Future<void> refreshSessions() async {
    await loadSessionsFromFirestore();
  }

  // Toggle sort order (newest first vs oldest first)
  void toggleSortOrder() {
    isDescendingOrder.value = !isDescendingOrder.value;
    print('Sort order changed to: ${isDescendingOrder.value ? "newest first" : "oldest first"}');
  }

  // Temporary method to load all sessions (for testing)
  Future<void> loadAllSessionsFromFirestore() async {
    try {
      isLoading.value = true;
      
      print('Loading ALL sessions from Firestore (for testing)');

      // Fetch all sessions from Firestore
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${sessionsSnapshot.docs.length} total sessions in Firestore');

      final List<Session> sessionsList = [];

      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        print('Processing session document: ${doc.id}');
        print('Session data: $data');
        
        // Create dummy users for now (as requested)
        final dummyUsers = [
          app_user.User(
            id: '1', 
            name: 'User1', 
            avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg'
          ),
          app_user.User(
            id: '2', 
            name: 'User2', 
            avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg'
          ),
          app_user.User(
            id: '3', 
            name: 'User3', 
            avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg'
          ),
        ];

        // Parse timestamps
        DateTime createdAt = DateTime.now();
        DateTime updatedAt = DateTime.now();
        
        if (data['createdAt'] != null) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }
        if (data['updatedAt'] != null) {
          updatedAt = (data['updatedAt'] as Timestamp).toDate();
        }

        // Create session object
        final session = Session(
          id: doc.id,
          name: data['name'] ?? 'Untitled Session',
          dateTime: updatedAt, // Using updatedAt as the session date
          createdDate: createdAt,
          users: dummyUsers, // Using dummy users for now
          recordingsCount: 0, // Using 0 as dummy recording count for now
        );

        sessionsList.add(session);
        print('Added session: ${session.name}');
      }

      if (sessionsList.isEmpty) {
        print('No sessions found in Firestore - falling back to mock data');
        loadMockSessions();
        return;
      }

      sessions.value = sessionsList;
      print('Successfully loaded ${sessionsList.length} sessions from Firestore');
      
    } catch (e) {
      print('Error loading all sessions from Firestore: $e');
      print('Stack trace: ${StackTrace.current}');
      // Fallback to mock data if Firestore fails
      loadMockSessions();
    } finally {
      isLoading.value = false;
    }
  }

  /// Stream of sessions where the user is host or participant (live updates)
  Stream<List<Session>> get userSessionsStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No authenticated user for userSessionsStream');
      return Stream.value([]);
    }
    
    print('Setting up userSessionsStream for user: ${user.uid}');
    final uid = user.uid;
    final sessionsRef = FirebaseFirestore.instance.collection('sessions');
    
    try {
    // Stream for sessions where user is a participant
      final participantStream = sessionsRef
          .where('participantIds', arrayContains: uid)
          .snapshots()
          .handleError((error) {
            print('Error in participant stream: $error');
            // Return an empty stream on error
            return;
          });
      
    // Stream for sessions where user is the host
      final hostStream = sessionsRef
          .where('hostId', isEqualTo: uid)
          .snapshots()
          .handleError((error) {
            print('Error in host stream: $error');
            // Return an empty stream on error
            return;
          });
      
    // Convert isDescendingOrder observable to stream
    final sortOrderStream = isDescendingOrder.stream;
    
    return Rx.combineLatest3<QuerySnapshot, QuerySnapshot, bool, List<Session>>(
      participantStream,
      hostStream,
      sortOrderStream,
      (participantSnap, hostSnap, isDescending) {
          print('Processing streams - participant docs: ${participantSnap.docs.length}, host docs: ${hostSnap.docs.length}');
          
        final allDocs = <String, QueryDocumentSnapshot>{};
          
          // Add participant sessions
        for (var doc in participantSnap.docs) {
          allDocs[doc.id] = doc;
            print('Added participant session: ${doc.id}');
        }
          
          // Add host sessions
        for (var doc in hostSnap.docs) {
          allDocs[doc.id] = doc;
            print('Added host session: ${doc.id}');
        }
          
        final sessionsList = allDocs.values.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
            print('Processing session document: ${doc.id} with data: $data');
            
          // Dummy users for now
          final dummyUsers = [
            app_user.User(id: '1', name: 'User1', avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg'),
            app_user.User(id: '2', name: 'User2', avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg'),
            app_user.User(id: '3', name: 'User3', avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg'),
          ];
            
          DateTime createdAt = DateTime.now();
          DateTime updatedAt = DateTime.now();
            
          if (data['createdAt'] != null) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          }
          if (data['updatedAt'] != null) {
            updatedAt = (data['updatedAt'] as Timestamp).toDate();
          }
            
          return Session(
            id: doc.id,
            name: data['name'] ?? 'Untitled Session',
            dateTime: updatedAt,
            createdDate: createdAt,
            users: dummyUsers,
            recordingsCount: 0,
          );
        }).toList();
          
        // Sort by createdAt (descending or ascending)
        sessionsList.sort((a, b) => isDescending
            ? b.createdDate.compareTo(a.createdDate)
            : a.createdDate.compareTo(b.createdDate));
          
          print('Returning ${sessionsList.length} sessions from stream');
        return sessionsList;
      },
      ).handleError((error) {
        print('Error in userSessionsStream: $error');
        return <Session>[];
      });
    } catch (e) {
      print('Exception in userSessionsStream setup: $e');
      return Stream.value(<Session>[]);
    }
  }
} 