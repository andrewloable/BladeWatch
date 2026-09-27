import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';

/// Formatting shared by the screens. Distances arrive in km; the car's `distance_unit` says
/// whether the owner reads miles.
abstract final class Fmt {
  static const _kmPerMile = 1.609344;

  /// Between a number and its unit: a no-break space, so "202.1 MB" never splits over two lines
  /// in a narrow subtitle (BladeWatch-rdtj.57; seen on the Android phone's recordings list).
  static const nbsp = '\u00A0';

  static String distance(double km, {String unit = 'km'}) =>
      unit == 'mi' ? '${(km / _kmPerMile).toStringAsFixed(1)}${nbsp}mi' : '${km.toStringAsFixed(1)}${nbsp}km';

  static String duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  static String dateTime(Int64 epochMs, [String? locale]) => epochMs <= 0
      ? '—'
      : DateFormat.yMMMd(locale).add_jm().format(DateTime.fromMillisecondsSinceEpoch(epochMs.toInt()));

  static String time(Int64 epochMs, [String? locale]) =>
      epochMs <= 0 ? '—' : DateFormat.jm(locale).format(DateTime.fromMillisecondsSinceEpoch(epochMs.toInt()));

  /// A clock time to the second, for things that change every second (the live still).
  static String clock(DateTime at, [String? locale]) => DateFormat.jms(locale).format(at);

  static String bytes(num b) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var v = b.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(i == 0 ? 0 : 1)}$nbsp${units[i]}';
  }

  static String percent(double p) => '${p.toStringAsFixed(0)}%';
}
