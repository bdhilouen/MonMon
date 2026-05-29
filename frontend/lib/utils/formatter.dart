import 'package:intl/intl.dart';

String formatRupiah(num amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
}

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('dd MMM yyyy HH:mm').format(date);
}
