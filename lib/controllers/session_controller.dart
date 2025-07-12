import 'package:get/get.dart' hide Rx;
import '../models/session.dart';
import '../models/user.dart' as app_user;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

class SessionController extends GetxController {
  var sessions = <Session>[].obs;
  var searchQuery = ''.obs;
  var isLoading = false.obs;
  var isAuthenticated = false.obs;
  var isDescendingOrder = true.obs; // true = newest first, false = oldest first
  StreamSubscription? _sessionsSubscription;

  @override
  void onInit() {
    super.onInit();
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      isAuthenticated.value = user != null;
      if (user != null) {
        print('User authenticated: ${user.uid}');
        _listenToSessions();
      } else {
        print('User signed out');
        sessions.clear();
        _sessionsSubscription?.cancel();
      }
    });
    // Check if user is already authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      isAuthenticated.value = true;
      print('User already authenticated: ${currentUser.uid}');
      _listenToSessions();
    } else {
      print('No user authenticated initially');
      // Load mock data initially
      // loadMockSessions();
    }
    ever(isDescendingOrder, (_) => _listenToSessions());
  }

  void _listenToSessions() {
    _sessionsSubscription?.cancel();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final sessionsRef = FirebaseFirestore.instance.collection('sessions');
    _sessionsSubscription = sessionsRef.snapshots().listen((snapshot) async {
      // Filter sessions where user is host or participant
      final List<Session> sessionsList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Check if user is host or participant
        final hostId = data['hostId'];
        final participantIds = (data['participantIds'] != null && data['participantIds'] is List)
            ? List<String>.from(data['participantIds'])
            : <String>[];
        if (hostId == currentUser.uid || participantIds.contains(currentUser.uid)) {
          // Fetch real users from participantIds and hostId
          List<String> allParticipantIds = List<String>.from(participantIds);
          if (hostId != null && !allParticipantIds.contains(hostId)) {
            allParticipantIds.insert(0, hostId);
          }
          List<app_user.User> realUsers = [];
          if (allParticipantIds.isNotEmpty) {
            final userDocs = await Future.wait(allParticipantIds.map((uid) async {
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              return userDoc.exists ? userDoc : null;
            }));
            for (var userDoc in userDocs) {
              if (userDoc != null) {
                final userData = userDoc.data() as Map<String, dynamic>;
                realUsers.add(app_user.User(
                  id: userDoc.id,
                  name: "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}",
                  email: userData['email'] ?? '',
                  avatarUrl: userData['imageUrl'] ?? '',
                ));
              }
            }
          }
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
            dateTime: updatedAt,
            createdDate: createdAt,
            users: realUsers,
            recordingsCount: 0,
          );
          sessionsList.add(session);
        }
      }
      // Sort sessions by createdAt based on current sort order
      if (isDescendingOrder.value) {
        sessionsList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      } else {
        sessionsList.sort((a, b) => a.createdDate.compareTo(b.createdDate));
      }
      sessions.value = sessionsList;
    });
  }

  @override
  void onClose() {
    _sessionsSubscription?.cancel();
    super.onClose();
  }

  Future<void> loadSessionsFromFirestore() async {
    try {
      isLoading.value = true;
      
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user found - falling back to mock data');
        // loadMockSessions();
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
      final hostSessions = await FirebaseFirestore.instance
          .collection('sessions')
          .where('hostId', isEqualTo: currentUser.uid)
          .get();

      final participantSessions = await FirebaseFirestore.instance
          .collection('sessions')
          .where('participantIds', arrayContains: currentUser.uid)
          .get();

      var sessionsSnapshot = {
        for (var doc in [...hostSessions.docs, ...participantSessions.docs]) doc.id: doc
      }.values.toList();

      // Now try to fetch sessions for the current user
      // final sessionsSnapshot = await FirebaseFirestore.instance
      //     .collection('sessions')
      //     .where('hostId', isEqualTo: currentUser.uid) // Temporarily commented out to see all sessions
      //     // .orderBy('createdAt', descending: true) // Temporarily commented out until index is created
      //     .get();

      print('Found ${sessionsSnapshot.length} sessions for current user');

      final List<Session> sessionsList = [];

      for (var doc in sessionsSnapshot) {
        final data = doc.data();
        print('Processing session document: ${doc.id}');
        print('Session data: $data');
        
        // Fetch real users from participantIds and hostId
        List<String> participantIds = [];
        if (data['participantIds'] != null && data['participantIds'] is List) {
          participantIds = List<String>.from(data['participantIds']);
        }
        // Add hostId if not already in participantIds
        String? hostId = data['hostId'];
        if (hostId != null && !participantIds.contains(hostId)) {
          participantIds.insert(0, hostId); // Optionally, add host at the start
        }
        List<app_user.User> realUsers = [];
        if (participantIds.isNotEmpty) {
          // Fetch all user docs in parallel
          final userDocs = await Future.wait(participantIds.map((uid) async {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
            return userDoc.exists ? userDoc : null;
          }));
          for (var userDoc in userDocs) {
            if (userDoc != null) {
              final userData = userDoc.data() as Map<String, dynamic>;
              realUsers.add(app_user.User(
                id: userDoc.id,
                name: "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}",
                email: userData['email'] ?? '',
                avatarUrl: userData['imageUrl'] ?? '',
              ));
            }
          }
        }

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
          users: realUsers, // Use real users
          recordingsCount: 0, // Using 0 as dummy recording count for now
        );

        sessionsList.add(session);
        print('Added session: ${session.name}');
      }

      if (sessionsList.isEmpty) {
        print('No sessions found for current user - falling back to mock data');
        // loadMockSessions();
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
      // loadMockSessions();
    } finally {
      isLoading.value = false;
    }
  }

  // void loadMockSessions() {
  //   final users = [
  //     app_user.User(id: '1', name: 'User1', email: 'user1@example.com', avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg'),
  //     app_user.User(id: '2', name: 'User2', email: 'user2@example.com', avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg'),
  //     app_user.User(id: '3', name: 'User3', email: 'user3@example.com', avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg'),
  //     app_user.User(id: '4', name: 'User4', email: 'user4@example.com', avatarUrl: 'https://randomuser.me/api/portraits/men/4.jpg'),
  //     app_user.User(id: '5', name: 'User5', email: 'user5@example.com', avatarUrl: 'https://randomuser.me/api/portraits/men/5.jpg'),
  //   ];
  //   sessions.value = [
  //     Session(
  //       id: '1',
  //       name: 'Spellbound',
  //       dateTime: DateTime(2024, 10, 19, 13, 50),
  //       createdDate: DateTime(2024, 10, 15),
  //       users: users,
  //       recordingsCount: 14,
  //     ),
  //     Session(
  //       id: '2',
  //       name: 'Remedy',
  //       dateTime: DateTime(2024, 10, 16, 18, 25),
  //       createdDate: DateTime(2024, 10, 10),
  //       users: [users[1], users[2], users[3]],
  //       recordingsCount: 7,
  //     ),
  //     Session(
  //       id: '3',
  //       name: 'Lighthouse',
  //       dateTime: DateTime(2024, 9, 9, 11, 44),
  //       createdDate: DateTime(2024, 9, 5),
  //       users: [users[2], users[4]],
  //       recordingsCount: 9,
  //     ),
  //     Session(
  //       id: '4',
  //       name: 'Free Falling v2',
  //       dateTime: DateTime(2024, 12, 30, 13, 50),
  //       createdDate: DateTime(2024, 12, 30),
  //       users: [users[0], users[1], users[2]],
  //       recordingsCount: 3,
  //     ),
  //   ];
  // }

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
  // Future<void> loadAllSessionsFromFirestore() async {
  //   try {
  //     isLoading.value = true;
  //
  //     print('Loading ALL sessions from Firestore (for testing)');
  //
  //     // Fetch all sessions from Firestore
  //     final sessionsSnapshot = await FirebaseFirestore.instance
  //         .collection('sessions')
  //         .orderBy('createdAt', descending: true)
  //         .get();
  //
  //     print('Found ${sessionsSnapshot.docs.length} total sessions in Firestore');
  //
  //     final List<Session> sessionsList = [];
  //
  //     for (var doc in sessionsSnapshot.docs) {
  //       final data = doc.data();
  //       print('Processing session document: ${doc.id}');
  //       print('Session data: $data');
  //
  //       // Create dummy users for now (as requested)
  //       final dummyUsers = [
  //         app_user.User(
  //           id: '1',
  //           name: 'User1',
  //           avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg'
  //         ),
  //         app_user.User(
  //           id: '2',
  //           name: 'User2',
  //           avatarUrl: 'https://randomuser.me/api/portraits/men/2.jpg'
  //         ),
  //         app_user.User(
  //           id: '3',
  //           name: 'User3',
  //           avatarUrl: 'https://randomuser.me/api/portraits/men/3.jpg'
  //         ),
  //       ];
  //
  //       // Parse timestamps
  //       DateTime createdAt = DateTime.now();
  //       DateTime updatedAt = DateTime.now();
  //
  //       if (data['createdAt'] != null) {
  //         createdAt = (data['createdAt'] as Timestamp).toDate();
  //       }
  //       if (data['updatedAt'] != null) {
  //         updatedAt = (data['updatedAt'] as Timestamp).toDate();
  //       }
  //
  //       // Create session object
  //       final session = Session(
  //         id: doc.id,
  //         name: data['name'] ?? 'Untitled Session',
  //         dateTime: updatedAt, // Using updatedAt as the session date
  //         createdDate: createdAt,
  //         users: dummyUsers, // Using dummy users for now
  //         recordingsCount: 0, // Using 0 as dummy recording count for now
  //       );
  //
  //       sessionsList.add(session);
  //       print('Added session: ${session.name}');
  //     }
  //
  //     if (sessionsList.isEmpty) {
  //       print('No sessions found in Firestore - falling back to mock data');
  //       // loadMockSessions();
  //       return;
  //     }
  //
  //     sessions.value = sessionsList;
  //     print('Successfully loaded ${sessionsList.length} sessions from Firestore');
  //
  //   } catch (e) {
  //     print('Error loading all sessions from Firestore: $e');
  //     print('Stack trace: ${StackTrace.current}');
  //     // Fallback to mock data if Firestore fails
  //     // loadMockSessions();
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  /// Stream of sessions where the user is host or participant (live updates)
  Stream<List<Session>> get userSessionsStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    final uid = user.uid;
    final sessionsRef = FirebaseFirestore.instance.collection('sessions');
    // Stream for sessions where user is a participant
    final participantStream = sessionsRef.where('participantIds', arrayContains: uid).snapshots();
    // Stream for sessions where user is the host
    final hostStream = sessionsRef.where('hostId', isEqualTo: uid).snapshots();
    // Convert isDescendingOrder observable to stream
    final sortOrderStream = isDescendingOrder.stream;
    
    return Rx.combineLatest3<QuerySnapshot, QuerySnapshot, bool, List<Session>>(
      participantStream,
      hostStream,
      sortOrderStream,
      (participantSnap, hostSnap, isDescending) {
        final allDocs = <String, QueryDocumentSnapshot>{};
        for (var doc in participantSnap.docs) {
          allDocs[doc.id] = doc;
        }
        for (var doc in hostSnap.docs) {
          allDocs[doc.id] = doc;
        }
        final sessionsList = allDocs.values.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Fetch real users from participantIds
          List<String> participantIds = [];
          if (data['participantIds'] != null && data['participantIds'] is List) {
            participantIds = List<String>.from(data['participantIds']);
          }
          List<app_user.User> realUsers = [];
          if (participantIds.isNotEmpty) {
            // Fetch all user docs in parallel
            final userDocs = Future.wait(participantIds.map((uid) async {
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              return userDoc.exists ? userDoc : null;
            }));
            // for (var userDoc in userDocs) {
            //   if (userDoc != null) {
            //     final userData = userDoc.data() as Map<String, dynamic>;
            //     realUsers.add(app_user.User(
            //       id: userDoc.id,
            //       name: userData['name'] ?? '',
            //       avatarUrl: userData['avatarUrl'] ?? '',
            //     ));
            //   }
            // }
          }
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
            users: realUsers,
            recordingsCount: 0,
          );
        }).toList();
        // Sort by createdAt (descending or ascending)
        sessionsList.sort((a, b) => isDescending
            ? b.createdDate.compareTo(a.createdDate)
            : a.createdDate.compareTo(b.createdDate));
        return sessionsList;
      },
    );
  }
} 