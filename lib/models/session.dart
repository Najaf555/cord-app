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

  Session copyWith({
    String? id,
    String? name,
    DateTime? dateTime,
    DateTime? createdDate,
    List<User>? users,
    int? recordingsCount,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      dateTime: dateTime ?? this.dateTime,
      createdDate: createdDate ?? this.createdDate,
      users: users ?? this.users,
      recordingsCount: recordingsCount ?? this.recordingsCount,
    );
  }
} 