import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('d MMM yyyy').format(date);
}

String formatDateWithTime(DateTime date) {
  return DateFormat('d MMM yyyy HH:mm').format(date);
}

String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return 'Today';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return formatDate(date);
  }
}
