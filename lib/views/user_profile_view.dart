import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import 'main_navigation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/azure_storage_service.dart';
import 'package:http/http.dart' as http;

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // ✅ Email Controller
  final NavigationController navController = Get.find<NavigationController>();
  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _cleanupLocalPaths(); // Clean up any existing local paths
  }

  Future<void> _loadUserProfile() async {
    print('Loading user profile data...');
    final userData = await _fetchAllUserData();
    
    if (userData != null) {
      setState(() {
        firstNameController.text = userData['firstName'] ?? '';
        lastNameController.text = userData['lastName'] ?? '';
        emailController.text = userData['email'] ?? '';
        _imageUrl = userData['imageUrl'] as String?;
      });
      
      // Debug: Print the loaded image URL
      print('Loaded image URL from Firestore: $_imageUrl');
      print('Image URL is valid HTTPS: ${_imageUrl?.startsWith('https://')}');
      
      // Ensure we're using a valid URL (Azure Blob Storage or other https URLs)
      if (_imageUrl != null && !_imageUrl!.startsWith('https://')) {
        // If it's a local path, clear it as it won't work in web browsers
        print('Warning: Found local path in Firestore: $_imageUrl');
        setState(() {
          _imageUrl = null;
        });
        print('Cleared local image path as it\'s not accessible via web');
      }
      
      print('User profile loaded successfully');
    } else {
      print('No user data found or error occurred');
    }
  }

  void _saveProfile() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDocRef.get();
        
        // Validate image URL - only save valid URLs
        String? validImageUrl = _imageUrl;
        if (_imageUrl != null && !_imageUrl!.startsWith('https://')) {
          print('Warning: Attempting to save local path as imageUrl: $_imageUrl');
          validImageUrl = null; // Don't save local paths
        }
        
        // Debug: Print current state
        print('Current _imageUrl: $_imageUrl');
        print('Valid image URL: $validImageUrl');
        
        final data = {
          'uid': user.uid,
          'email': user.email ?? '', // Handle nullable email
          'firstName': firstName,
          'lastName': lastName,
          'imageUrl': validImageUrl, // Use validated URL
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        print('Saving profile with imageUrl: $validImageUrl');
        
        if (docSnapshot.exists) {
          // Only update existing document
          await userDocRef.update(data);
        } else {
          // Create new document with createdAt
          data['createdAt'] = FieldValue.serverTimestamp();
          await userDocRef.set(data);
        }
        
        // Verify the save was successful
        final savedDoc = await userDocRef.get();
        if (savedDoc.exists) {
          final savedData = savedDoc.data();
          print('Profile saved successfully. Saved imageUrl: ${savedData?['imageUrl']}');
        }
        
        Get.snackbar(
          'Success',
          'Profile saved successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await Future.delayed(Duration(seconds: 1));
        Get.back();
      }
    } catch (e) {
      print('Error saving profile: $e');
      Get.snackbar(
        'Error',
        'Failed to save profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _onTabSelected(int index) {
    navController.changeTab(index);
    Get.offAll(() => MainNavigation());
  }

  // Method to refresh user profile data
  Future<void> _refreshUserProfile() async {
    print('Refreshing user profile data...');
    await _loadUserProfile();
    print('User profile refresh completed');
  }

  // Method to fetch all user profile data from Firebase
  Future<Map<String, dynamic>?> _fetchAllUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          print('Fetched all user data from Firebase: $data');
          return data;
        } else {
          print('No user document found in Firebase');
          return null;
        }
      } else {
        print('No authenticated user found');
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUploading = true;
        });
        
        print('Image picked: ${pickedFile.path}');
        
        // Upload to Azure Blob Storage
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Generate unique blob name for the profile image
          final blobName = AzureStorageService.generateProfileImageBlobName(user.uid);
          print('Generated blob name: $blobName');
          
          // Upload file to Azure Blob Storage
          print('Starting Azure upload...');
          final azureUrl = await AzureStorageService.uploadFile(_imageFile!, blobName);
          
          print('Azure Blob Storage URL: $azureUrl'); // Debug log
          
          // Validate the URL
          if (azureUrl.startsWith('https://')) {
            setState(() {
              _imageUrl = azureUrl; // Save the Azure Blob Storage URL
              _isUploading = false;
            });
            
            // Immediately save the URL to Firestore
            await _saveImageUrlToFirestore(azureUrl);
            
            Get.snackbar(
              'Success',
              'Profile image uploaded successfully!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            throw Exception('Invalid Azure URL returned: $azureUrl');
          }
        } else {
          throw Exception('No authenticated user found');
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      print('Error uploading image: $e');
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper method to save image URL to Firestore immediately after upload
  Future<void> _saveImageUrlToFirestore(String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDocRef.get();
        
        print('Saving image URL to Firestore: $imageUrl');
        
        final data = {
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        if (docSnapshot.exists) {
          // Update existing document with new image URL
          await userDocRef.update(data);
          print('Updated existing document with image URL');
        } else {
          // Create new document if it doesn't exist
          data['uid'] = user.uid;
          data['email'] = user.email ?? ''; // Handle nullable email
          data['createdAt'] = FieldValue.serverTimestamp();
          await userDocRef.set(data);
          print('Created new document with image URL');
        }
        
        // Verify the save was successful
        final savedDoc = await userDocRef.get();
        if (savedDoc.exists) {
          final savedData = savedDoc.data();
          final savedImageUrl = savedData?['imageUrl'];
          print('Image URL saved to Firestore successfully: $savedImageUrl');
          
          if (savedImageUrl != imageUrl) {
            print('Warning: Saved URL differs from original: $savedImageUrl vs $imageUrl');
          }
        }
      }
    } catch (e) {
      print('Error saving image URL to Firestore: $e');
      // Don't show error to user as the upload was successful
    }
  }

  Future<void> _removeImage() async {
    try {
      // Delete from Azure Blob Storage if URL exists
      if (_imageUrl != null && _imageUrl!.startsWith('https://')) {
        try {
          final deleted = await AzureStorageService.deleteBlob(_imageUrl!);
          if (deleted) {
            print('Successfully deleted blob from Azure Storage');
          } else {
            print('Failed to delete blob from Azure Storage');
          }
        } catch (e) {
          // If deletion fails, continue anyway
          print('Error deleting from Azure Storage: $e');
        }
      }
      
      setState(() {
        _imageFile = null;
        _imageUrl = null;
      });
      
      // Remove image URL from Firestore
      await _removeImageUrlFromFirestore();
      
      Get.snackbar(
        'Success',
        'Profile image removed!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper method to remove image URL from Firestore
  Future<void> _removeImageUrlFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDocRef.update({
          'imageUrl': FieldValue.delete(), // Remove the imageUrl field
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Successfully removed imageUrl from Firestore');
      }
    } catch (e) {
      print('Error removing image URL from Firestore: $e');
      // Don't show error to user as the removal was successful
    }
  }

  // Helper method to clean up any local paths in the database
  Future<void> _cleanupLocalPaths() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['imageUrl'] != null) {
            final imageUrl = data['imageUrl'] as String;
            if (!imageUrl.startsWith('https://')) {
              print('Found local path in database, cleaning up: $imageUrl');
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'imageUrl': FieldValue.delete(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('Cleaned up local path from database');
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up local paths: $e');
    }
  }

  // Debug method to check current image URL status
  void _debugImageStatus() {
    print('=== Image Status Debug ===');
    print('_imageFile: ${_imageFile?.path}');
    print('_imageUrl: $_imageUrl');
    print('_imageUrl starts with https: ${_imageUrl?.startsWith('https://')}');
    print('========================');
  }

  // Test method to verify Azure upload is working
  Future<void> _testAzureUpload() async {
    try {
      print('=== Testing Azure Upload ===');
      
      // Create a simple test file in a cross-platform way
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/test_image.txt');
      await testFile.writeAsString('This is a test file for Azure upload');
      
      print('Test file created at: ${testFile.path}');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final blobName = 'test_files/test_${DateTime.now().millisecondsSinceEpoch}.txt';
        print('Testing upload with blob name: $blobName');
        
        final azureUrl = await AzureStorageService.uploadFile(testFile, blobName);
        print('Test upload successful! URL: $azureUrl');
        
        // Test if the URL is accessible
        final response = await http.get(Uri.parse(azureUrl));
        print('URL accessibility test: ${response.statusCode}');
        
        Get.snackbar(
          'Test Success',
          'Azure upload test successful! URL: $azureUrl',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      } else {
        print('No authenticated user found');
        Get.snackbar(
          'Test Failed',
          'No authenticated user found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Azure upload test failed: $e');
      Get.snackbar(
        'Test Failed',
        'Azure upload test failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUserProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
            const SizedBox(height: 16),

            // Circle Profile Image
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              onLongPress: _imageFile != null ? _removeImage : null,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: ClipOval(
                      child: _imageFile != null
                          ? Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading file image: $error');
                                return Icon(Icons.camera_alt, size: 30, color: Colors.grey[600]);
                              },
                            )
                          : _imageUrl != null && _imageUrl!.startsWith('https://')
                              ? Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading network image: $error');
                                    setState(() {
                                      _imageUrl = null; // Clear invalid URL
                                    });
                                    return Icon(Icons.camera_alt, size: 30, color: Colors.grey[600]);
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                                      ),
                                    );
                                  },
                                )
                              : Icon(Icons.camera_alt, size: 30, color: Colors.grey[600]),
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title Text
            const Text(
              'User Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // First Name Field
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Last Name Field
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Email Field
            TextField(
              controller: emailController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),

            // Save Button
            Center(
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.red, width: 2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Square corners
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),


          ],
        ),
        ),
      ),
      bottomNavigationBar: Stack(
        children: [
          // Top border line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, color: Color(0xFFE0E0E0)),
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
              child: Obx(() => BottomNavigationBar(
                backgroundColor: Colors.white,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Color(0xFF222222),
                unselectedItemColor: Color(0xFFBDBDBD),
                selectedLabelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Poppins',
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
              )),
            ),
          ),
        ],
      ),
    );
  }
}
