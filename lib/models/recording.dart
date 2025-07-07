import 'package:Cord/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Recording model representing an audio recording document in Firestore
/// 
/// Document structure:
/// - userId: String (Firebase Auth UID)
/// - fileUrl: String (Azure Blob Storage HTTPS URL)
/// - duration: String (formatted as MM:SS.ms)
/// - createdAt: DateTime (server timestamp)
/// - recordingId: String (Firestore document ID)
/// - fileName: String (e.g., "recording_1234567890.m4a")
/// - name: String? (optional name field for backward compatibility)
class Recording {
  final String recordingId;
  final String userId;
  final String fileUrl;
  final String duration;
  final DateTime createdAt;
  final String fileName;
  final String? name; // Optional name field for backward compatibility

  Recording({
    required this.recordingId,
    required this.userId,
    required this.fileUrl,
    required this.duration,
    required this.createdAt,
    required this.fileName,
    this.name,
  });

  // Factory constructor to create Recording from Firestore document
  factory Recording.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Recording(
      recordingId: data['recordingId'] ?? documentId, // Use recordingId from data if available, fallback to documentId
      userId: data['userId'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      duration: data['duration'] ?? '00:00.00',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileName: data['fileName'] ?? '',
      name: data['name'],
    );
  }

  // Convert Recording to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fileUrl': fileUrl,
      'duration': duration,
      'createdAt': createdAt,
      'recordingId': recordingId,
      'fileName': fileName,
      if (name != null) 'name': name,
    };
  }
} 