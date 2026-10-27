import 'package:intl/intl.dart';

final _gnf = NumberFormat.decimalPattern('fr');
final _date = DateFormat('dd/MM/yyyy', 'fr');
final _dateTime = DateFormat("dd/MM/yyyy 'à' HH:mm", 'fr');

/// 150000 → « 150 000 GNF »
String formatGnf(num amount) => '${_gnf.format(amount.round())} GNF';

String formatDate(DateTime date) => _date.format(date);

String formatDateTime(DateTime date) => _dateTime.format(date);
