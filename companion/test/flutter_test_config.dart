import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// What main() does before the app runs: date formats for every locale.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
