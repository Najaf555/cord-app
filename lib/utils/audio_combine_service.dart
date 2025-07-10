import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AudioCombineService {
  /// Test method to verify service integration
  static Future<bool> testIntegration() async {
    try {
      print('AudioCombineService: Testing service integration...');
      
      // Test if we can access the documents directory
      final directory = await getApplicationDocumentsDirectory();
      print('AudioCombineService: Documents directory accessible: ${directory.path}');
      
      return true;
    } catch (e) {
      print('AudioCombineService: Integration test failed: $e');
      return false;
    }
  }

  /// Validates that all input files exist and are audio files
  static Future<bool> validateInputFiles(List<String> filePaths) async {
    try {
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (!await file.exists()) {
          print('AudioCombineService: File does not exist: $filePath');
          return false;
        }
        
        final extension = path.extension(filePath).toLowerCase();
        if (!['.m4a', '.mp3', '.wav', '.aac'].contains(extension)) {
          print('AudioCombineService: Unsupported file format: $extension');
          return false;
        }
        
        final fileSize = await file.length();
        if (fileSize == 0) {
          print('AudioCombineService: File is empty: $filePath');
          return false;
        }
        
        print('AudioCombineService: Validated file: $filePath (${fileSize} bytes)');
      }
      
      return true;
    } catch (e) {
      print('AudioCombineService: Error validating input files: $e');
      return false;
    }
  }

  /// Gets the primary recording file (first segment) for upload
  /// This approach uploads the first segment as the main recording
  /// and stores additional segments as metadata
  static Future<String?> getPrimaryRecordingFile(List<String> filePaths) async {
    try {
      if (filePaths.isEmpty) {
        print('AudioCombineService: No files to process');
        return null;
      }

      // Use the first segment as the primary recording
      final primaryFile = filePaths.first;
      final file = File(primaryFile);
      
      if (await file.exists()) {
        print('AudioCombineService: Using primary file: $primaryFile');
        return primaryFile;
      } else {
        print('AudioCombineService: Primary file does not exist: $primaryFile');
        return null;
      }
    } catch (e) {
      print('AudioCombineService: Error getting primary recording file: $e');
      return null;
    }
  }

  /// Gets metadata about all recording segments
  static Future<Map<String, dynamic>> getRecordingMetadata(List<String> filePaths) async {
    try {
      final metadata = <String, dynamic>{
        'totalSegments': filePaths.length,
        'segments': <Map<String, dynamic>>[],
        'totalDuration': 0.0,
      };

      for (int i = 0; i < filePaths.length; i++) {
        final filePath = filePaths[i];
        final file = File(filePath);
        
        if (await file.exists()) {
          final fileSize = await file.length();
          final fileName = path.basename(filePath);
          
          metadata['segments'].add({
            'index': i,
            'fileName': fileName,
            'filePath': filePath,
            'fileSize': fileSize,
            'segmentId': 'segment_$i',
          });
        }
      }

      print('AudioCombineService: Generated metadata for ${filePaths.length} segments');
      return metadata;
    } catch (e) {
      print('AudioCombineService: Error generating metadata: $e');
      return {
        'totalSegments': 0,
        'segments': <Map<String, dynamic>>[],
        'totalDuration': 0.0,
      };
    }
  }

  /// Cleans up temporary files after processing
  static Future<void> cleanupTempFiles(List<String> filePaths) async {
    try {
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          // Only delete if it's a temporary segment file
          if (path.basename(filePath).startsWith('segment_')) {
            await file.delete();
            print('AudioCombineService: Deleted temp file: $filePath');
          }
        }
      }
    } catch (e) {
      print('AudioCombineService: Error cleaning up temp files: $e');
    }
  }

  /// Creates a combined filename for the recording
  static String generateCombinedFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'recording_$timestamp';
  }

  /// Calculates total file size of all segments
  static Future<int> getTotalFileSize(List<String> filePaths) async {
    try {
      int totalSize = 0;
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('AudioCombineService: Error calculating total file size: $e');
      return 0;
    }
  }

  /// Checks if all segments are valid and ready for upload
  static Future<bool> areSegmentsReadyForUpload(List<String> filePaths) async {
    try {
      if (filePaths.isEmpty) {
        print('AudioCombineService: No segments to check');
        return false;
      }

      for (final filePath in filePaths) {
        final file = File(filePath);
        if (!await file.exists()) {
          print('AudioCombineService: Segment missing: $filePath');
          return false;
        }

        final fileSize = await file.length();
        if (fileSize < 100) { // Minimum size check (100 bytes)
          print('AudioCombineService: Segment too small: $filePath (${fileSize} bytes)');
          return false;
        }
      }

      print('AudioCombineService: All segments ready for upload');
      return true;
    } catch (e) {
      print('AudioCombineService: Error checking segments: $e');
      return false;
    }
  }
} 