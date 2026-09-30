import 'package:bladewatch_rpc/trips/currency_symbols.dart';
import 'package:intl/intl.dart';

/// Currency display, and the options of the currency picker.
///
/// **No symbol table is shipped.** Symbols, their placement, the spacing around them and the
/// number of decimal digits all vary by currency and by locale — JPY has no minor unit, many
/// European locales put the symbol after the amount. `intl` already carries ICU's rules for
/// all of it, so this delegates rather than reimplementing a subset badly.
///
/// The picker offers currency SYMBOLS (`$`, `€`, `₱`), not ISO codes (BladeWatch-gzbo): the list is
/// [CurrencySymbols], shared with the companion. Trips priced BEFORE that hold an ISO code, which
/// is still formatted through ICU below, so history does not change appearance.
class Currency {
  Currency._();

  /// Whether [value] has the shape of an ISO 4217 code: exactly three ASCII letters.
  ///
  /// This is the same structural rule the daemon applies in `TripConfig.setCurrency`, and it
  /// is deliberately a SHAPE test rather than a catalogue lookup: formatting must be
  /// synchronous and must not depend on the asset having loaded. A well-formed code that ICU
  /// does not recognise still formats sensibly — `intl` falls back to showing the code itself.
  static bool isIsoCodeShaped(String value) {
    if (value.length != 3) return false;
    for (final unit in value.codeUnits) {
      final isUpper = unit >= 0x41 && unit <= 0x5A;
      final isLower = unit >= 0x61 && unit <= 0x7A;
      if (!isUpper && !isLower) return false;
    }
    return true;
  }

  /// Format [amount] in [currency] for display.
  ///
  /// An ISO-shaped code is formatted through ICU, so a JPY amount shows no decimals and a
  /// EUR amount follows the active locale's placement.
  ///
  /// Anything else — a bare symbol like `$` or a label like `kr` from a config predating the
  /// currency picker — renders exactly as it always did: the stored string, a space, then the
  /// amount to two decimals. Historical trips must not change appearance just because the
  /// settings screen grew a picker.
  ///
  /// Returns an empty string when there is nothing to show, so callers can test one condition
  /// rather than duplicating the empty/zero logic.
  static String format(double amount, String? currency, {String? locale}) {
    final code = currency?.trim() ?? '';
    if (code.isEmpty) return '';

    if (!isIsoCodeShaped(code)) {
      // Legacy free text — preserve the original rendering byte for byte.
      return '$code ${amount.toStringAsFixed(2)}';
    }

    try {
      return NumberFormat.simpleCurrency(
        locale: locale,
        name: code.toUpperCase(),
      ).format(amount);
    } catch (_) {
      // ICU refused the code for this locale. Degrade to the legacy shape rather than
      // showing the user nothing.
      return '${code.toUpperCase()} ${amount.toStringAsFixed(2)}';
    }
  }

  /// The options the picker must offer, given the currently selected [current] value.
  ///
  /// **The current value is ALWAYS present exactly once.** `DropdownButtonFormField` asserts that
  /// its value matches exactly one item, so a stored value missing from the list crashes the
  /// settings sheet outright. That is not hypothetical: a config predating the picker can hold free
  /// text like `Rs.`, which is not in the list, and the crash would land on precisely the owners
  /// whose settings most need changing.
  ///
  /// A value the list does not know is prepended, so it is visible without scrolling, and it
  /// disappears from the menu as soon as the owner picks a symbol.
  static List<String> optionsFor(String current) {
    final symbols = CurrencySymbols.symbols;
    final trimmed = current.trim();
    if (trimmed.isEmpty || symbols.contains(trimmed)) return symbols;
    return <String>[trimmed, ...symbols];
  }

  /// What the picker shows selected for a currency [stored] on the car: the symbol when the value
  /// is a listed symbol or an ISO code that maps to one (`PHP` shows the peso sign), the stored
  /// text itself when it is something else (kept until replaced), the default when nothing is stored.
  static String selectionFor(String stored) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty) return CurrencySymbols.defaultSymbol;
    return CurrencySymbols.forStored(trimmed) ?? trimmed;
  }
}
