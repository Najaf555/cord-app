import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMNotificationService {
  static const String _serverKey = 'AIzaSyCOtG1MFxUxoAMdyKoBmG-NtJqQkQtm-3U'; // Replace with your actual FCM server key
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  /// Send FCM notification to a specific user by their email
  static Future<bool> sendNotificationToUserByEmail({
    required String userEmail,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Find the user document by email
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('User not found with email: $userEmail');
        return false;
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final fcmTokens = List<String>.from(userData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) {
        print('No FCM tokens found for user: $userEmail');
        return false;
      }

      // Send notification to all tokens for this user
      bool allSent = true;
      for (final token in fcmTokens) {
        final success = await _sendFCMNotification(
          token: token,
          title: title,
          body: body,
          data: data,
        );
        if (!success) {
          allSent = false;
        }
      }

      return allSent;
    } catch (e) {
      print('Error sending FCM notification to user $userEmail: $e');
      return false;
    }
  }

  /// Send FCM notification to a specific user by their UID
  static Future<bool> sendNotificationToUserByUID({
    required String userUID,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUID)
          .get();

      if (!userDoc.exists) {
        print('User not found with UID: $userUID');
        return false;
      }

      final userData = userDoc.data()!;
      final fcmTokens = List<String>.from(userData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) {
        print('No FCM tokens found for user: $userUID');
        return false;
      }

      // Send notification to all tokens for this user
      bool allSent = true;
      for (final token in fcmTokens) {
        final success = await _sendFCMNotification(
          token: token,
          title: title,
          body: body,
          data: data,
        );
        if (!success) {
          allSent = false;
        }
      }

      return allSent;
    } catch (e) {
      print('Error sending FCM notification to user $userUID: $e');
      return false;
    }
  }

  /// Send session invitation notification
  static Future<bool> sendSessionInvitationNotification({
    required String inviteeEmail,
    required String inviterEmail,
    required String sessionId,
    required String sessionName,
  }) async {
    try {
      // Get inviter's display name
      String inviterName = inviterEmail;
      final inviterQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: inviterEmail)
          .limit(1)
          .get();

      if (inviterQuery.docs.isNotEmpty) {
        final inviterData = inviterQuery.docs.first.data();
        final firstName = inviterData['firstName'] ?? '';
        final lastName = inviterData['lastName'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          inviterName = '$firstName $lastName'.trim();
        }
      }

      final title = 'Session Invitation';
      final body = '$inviterName invited you to join "$sessionName"';
      
      final data = {
        'type': 'session_invitation',
        'sessionId': sessionId,
        'sessionName': sessionName,
        'inviterEmail': inviterEmail,
        'inviterName': inviterName,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      return await sendNotificationToUserByEmail(
        userEmail: inviteeEmail,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      print('Error sending session invitation notification: $e');
      return false;
    }
  }

  /// Send invitation accepted notification to the inviter
  static Future<bool> sendInvitationAcceptedNotification({
    required String inviterEmail,
    required String inviteeEmail,
    required String sessionId,
    required String sessionName,
  }) async {
    try {
      // Get invitee's display name
      String inviteeName = inviteeEmail;
      final inviteeQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: inviteeEmail)
          .limit(1)
          .get();

      if (inviteeQuery.docs.isNotEmpty) {
        final inviteeData = inviteeQuery.docs.first.data();
        final firstName = inviteeData['firstName'] ?? '';
        final lastName = inviteeData['lastName'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          inviteeName = '$firstName $lastName'.trim();
        }
      }

      final title = 'Invitation Accepted';
      final body = '$inviteeName accepted your invitation to "$sessionName"';
      
      final data = {
        'type': 'invitation_accepted',
        'sessionId': sessionId,
        'sessionName': sessionName,
        'inviteeEmail': inviteeEmail,
        'inviteeName': inviteeName,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      return await sendNotificationToUserByEmail(
        userEmail: inviterEmail,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      print('Error sending invitation accepted notification: $e');
      return false;
    }
  }

  /// Send invitation rejected notification to the inviter
  static Future<bool> sendInvitationRejectedNotification({
    required String inviterEmail,
    required String inviteeEmail,
    required String sessionId,
    required String sessionName,
  }) async {
    try {
      // Get invitee's display name
      String inviteeName = inviteeEmail;
      final inviteeQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: inviteeEmail)
          .limit(1)
          .get();

      if (inviteeQuery.docs.isNotEmpty) {
        final inviteeData = inviteeQuery.docs.first.data();
        final firstName = inviteeData['firstName'] ?? '';
        final lastName = inviteeData['lastName'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          inviteeName = '$firstName $lastName'.trim();
        }
      }

      final title = 'Invitation Declined';
      final body = '$inviteeName declined your invitation to "$sessionName"';
      
      final data = {
        'type': 'invitation_rejected',
        'sessionId': sessionId,
        'sessionName': sessionName,
        'inviteeEmail': inviteeEmail,
        'inviteeName': inviteeName,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      return await sendNotificationToUserByEmail(
        userEmail: inviterEmail,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      print('Error sending invitation rejected notification: $e');
      return false;
    }
  }

  /// Internal method to send FCM notification
  static Future<bool> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      };

      final payload = {
        'to': token,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data ?? {},
        'priority': 'high',
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'session_invitations',
            'priority': 'high',
            'default_sound': true,
            'default_vibrate_timings': true,
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'badge': 1,
              'category': 'session_invitation',
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == 1) {
          print('FCM notification sent successfully to token: $token');
          return true;
        } else {
          print('FCM notification failed for token: $token. Response: $responseData');
          return false;
        }
      } else {
        print('FCM notification failed with code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
      return false;
    }
  }

  /// Clean up invalid FCM tokens
  static Future<void> cleanupInvalidTokens(String userUID) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUID)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final fcmTokens = List<String>.from(userData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      final validTokens = <String>[];
      
      for (final token in fcmTokens) {
        // Test if token is still valid by sending a test notification
        final isValid = await _sendFCMNotification(
          token: token,
          title: 'Test',
          body: 'Test notification',
          data: {'type': 'test'},
        );
        
        if (isValid) {
          validTokens.add(token);
        }
      }

      // Update user document with only valid tokens
      if (validTokens.length != fcmTokens.length) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userUID)
            .update({
          'fcmTokens': validTokens,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('Cleaned up ${fcmTokens.length - validTokens.length} invalid FCM tokens for user: $userUID');
      }
    } catch (e) {
      print('Error cleaning up FCM tokens: $e');
    }
  }
} 