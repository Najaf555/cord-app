import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RecordingAuthor extends StatefulWidget {
  final String? userId;

  const RecordingAuthor({super.key, required this.userId});

  @override
  State<RecordingAuthor> createState() => _RecordingAuthorState();
}

class _RecordingAuthorState extends State<RecordingAuthor> {
  String? _creatorName;
  String? _creatorProfilePictureUrl;
  bool _loadingCreatorDetails = true;

  @override
  void initState() {
    super.initState();
    _fetchCreatorDetails();
  }

  @override
  void didUpdateWidget(covariant RecordingAuthor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _fetchCreatorDetails();
    }
  }

  Future<void> _fetchCreatorDetails() async {
    if (widget.userId == null) {
      setState(() {
        _creatorName = 'John';
        _creatorProfilePictureUrl = null;
        _loadingCreatorDetails = false;
      });
      return;
    }

    setState(() {
      _loadingCreatorDetails = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            _creatorName = data?['name'] ?? 'John';
            _creatorProfilePictureUrl = data?['avatarUrl'];
            _loadingCreatorDetails = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _creatorName = 'John';
            _creatorProfilePictureUrl = null;
            _loadingCreatorDetails = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creatorName = 'Error';
          _creatorProfilePictureUrl = null;
          _loadingCreatorDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCreatorDetails) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[400],
          backgroundImage: _creatorProfilePictureUrl != null &&
                  _creatorProfilePictureUrl!.isNotEmpty
              ? NetworkImage(_creatorProfilePictureUrl!)
              : null,
          child:
              _creatorProfilePictureUrl == null || _creatorProfilePictureUrl!.isEmpty
                  ? Text(
                      _creatorName != null && _creatorName!.isNotEmpty
                          ? _creatorName![0].toUpperCase()
                          : 'J',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    )
                  : null,
        ),
        const SizedBox(height: 8),
        Text(
          _creatorName ?? 'John',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
