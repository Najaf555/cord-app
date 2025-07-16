import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lyric_line.dart';

class LyricsController {
  // Stream all lyrics for a session and section, ordered by createdAt
  Stream<List<LyricLine>> streamLyrics(String sessionId, String section) {
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('lyrics')
        .where('section', isEqualTo: section)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LyricLine.fromFirestore(doc.data(), doc.id))
            .toList()
            ..sort((a, b) {
              final aTime = a.createdAt ?? a.createdAtLocal;
              final bTime = b.createdAt ?? b.createdAtLocal;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return aTime.compareTo(bTime);
            })
        );
  }

  // Add a new lyric line
  Future<void> addLyric(String sessionId, String section, String text, String userId) async {
    final lyricsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('lyrics');
    await lyricsRef.add({
      'section': section,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtLocal': DateTime.now(),
      'userId': userId,
      'recordings': [],
    });
  }

  // Add a recordingId to the recordings array of a lyric line
  Future<void> addRecordingToLyric(String sessionId, String lyricId, String recordingId) async {
    final lyricRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('lyrics')
        .doc(lyricId);
    await lyricRef.update({
      'recordings': FieldValue.arrayUnion([recordingId])
    });
  }
} 