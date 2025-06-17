import 'package:Cord/models/user.dart';

class Session {
  final String id;
  final String name;
  final DateTime dateTime;
  final DateTime createdDate;
  final List<User> users;
  final int recordingsCount;

  Session({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.createdDate,
    required this.users,
    required this.recordingsCount,
  });
} 