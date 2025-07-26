import 'package:intl/intl.dart';
 
String formatSessionDate(DateTime dateTime) {
  return DateFormat('dd/MM/yy HH:mm').format(dateTime);
}

class DateUtil {
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yy HH:mm').format(dateTime);
  }
} 