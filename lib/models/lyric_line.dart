// LyricLine model for Firestore lyrics documents
import 'package:cloud_firestore/cloud_firestore.dart';

class LyricLine {
  final String id;
  final String section;
  final String text;
  final DateTime createdAt;
  final DateTime? createdAtLocal;
  final String userId;
  final List<String> recordings;

  LyricLine({
    required this.id,
    required this.section,
    required this.text,
    required this.createdAt,
    this.createdAtLocal,
    required this.userId,
    required this.recordings,
  });

  factory LyricLine.fromFirestore(Map<String, dynamic> data, String documentId) {
    DateTime? createdAtLocal;
    final localRaw = data['createdAtLocal'];
    if (localRaw is Timestamp) {
      createdAtLocal = localRaw.toDate();
    } else if (localRaw is DateTime) {
      createdAtLocal = localRaw;
    } else {
      createdAtLocal = null;
    }
    return LyricLine(
      id: documentId,
      section: data['section'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAtLocal: createdAtLocal,
      userId: data['userId'] ?? '',
      recordings: List<String>.from(data['recordings'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'section': section,
      'text': text,
      'createdAt': createdAt,
      'userId': userId,
      'recordings': recordings,
    };
    if (createdAtLocal != null) {
      map['createdAtLocal'] = Timestamp.fromDate(createdAtLocal!);
    }
    return map;
  }
} 