// lib/utils/validators.dart
bool isValidEmail(String email) =>
    RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
bool isValidPassword(String password) => password.length >= 6;
