import 'package:Cord/models/user.dart';

class Recording {
  final String id;
  final String name;
  final DateTime dateTime;
  final User? user;
  final String status;
  final String? duration;

  Recording({
    required this.id,
    required this.name,
    required this.dateTime,
    this.user,
    required this.status,
    this.duration,
  });
} 