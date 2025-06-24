// lib/utils/string_util.dart
String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
String trimAll(String s) => s.replaceAll(' ', ''); 