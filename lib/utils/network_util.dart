import 'package:http/http.dart' as http;

Future<bool> hasNetwork() async {
  try {
    final result = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 3));
    return result.statusCode == 200;
  } catch (_) {
    return false;
  }
} 