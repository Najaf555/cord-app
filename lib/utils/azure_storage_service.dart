import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class AzureStorageService {
  // Azure Blob Storage configuration
  static const String _accountName = 'cordappsendemailgrob252';
  static const String _containerName = 'cord-app';
  static const String _sasToken = 'sp=racwdli&st=2025-07-05T15:57:50Z&se=2050-07-05T23:57:50Z&spr=https&sv=2024-11-04&sr=c&sig=cO9VjUD7%2F88iXtz%2BJ0ynKSWxc8bE6dBNrzB3aKn7x%2BQ%3D';
  static const String _baseUrl = 'https://cordappsendemailgrob252.blob.core.windows.net/cord-app';

  /// Upload a file to Azure Blob Storage
  static Future<String> uploadFile(File file, String blobName) async {
    try {
      print('Azure Storage: Starting upload for blob: $blobName');
      print('Azure Storage: File path: ${file.path}');
      
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }
      
      // Read file bytes
      final bytes = await file.readAsBytes();
      print('Azure Storage: File size: ${bytes.length} bytes');
      
      // Create the full URL with SAS token
      final url = '$_baseUrl/$blobName?$_sasToken';
      print('Azure Storage: Upload URL: $url');
      
      // Prepare headers
      final headers = {
        'x-ms-blob-type': 'BlockBlob',
        'Content-Type': _getContentType(file.path),
        'Content-Length': bytes.length.toString(),
      };
      
      print('Azure Storage: Headers: $headers');
      
      // Upload the file
      print('Azure Storage: Sending PUT request...');
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: bytes,
      );
      
      print('Azure Storage: Response status: ${response.statusCode}');
      print('Azure Storage: Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        // Return the public URL of the uploaded blob
        final publicUrl = '$_baseUrl/$blobName?$_sasToken';
        print('Azure Storage: Upload successful! Public URL: $publicUrl');
        return publicUrl;
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      print('Azure Storage: Upload error: $e');
      throw Exception('Error uploading file to Azure Blob Storage: $e');
    }
  }

  /// Delete a blob from Azure Blob Storage
  static Future<bool> deleteBlob(String blobUrl) async {
    try {
      // Extract blob name from URL
      final uri = Uri.parse(blobUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 2) {
        throw Exception('Invalid blob URL format');
      }
      
      final blobName = pathSegments.last;
      final deleteUrl = '$_baseUrl/$blobName?$_sasToken';
      
      final response = await http.delete(Uri.parse(deleteUrl));
      
      return response.statusCode == 202 || response.statusCode == 404;
    } catch (e) {
      print('Error deleting blob: $e');
      return false;
    }
  }

  /// Generate a unique blob name for profile images
  static String generateProfileImageBlobName(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'profile_images/$userId/profile_$timestamp.jpg';
  }

  /// Get content type based on file extension
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.m4a':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      default:
        return 'application/octet-stream';
    }
  }

  /// Check if a blob exists
  static Future<bool> blobExists(String blobUrl) async {
    try {
      final response = await http.head(Uri.parse(blobUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get blob metadata
  static Future<Map<String, String>?> getBlobMetadata(String blobUrl) async {
    try {
      final response = await http.head(Uri.parse(blobUrl));
      if (response.statusCode == 200) {
        return response.headers;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
} 