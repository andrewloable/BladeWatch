/// The currency SYMBOLS the trip settings offer (BladeWatch-gzbo), in picker order.
///
/// Both apps pick from this list instead of typing or choosing an ISO 4217 code: the owner
/// wants `$`, `€`, `₱`, never `USD`. Curated from the "Currency Symbol" column of
/// https://www.newbridgefx.com/currency-codes-symbols/ (retrieved 2026-09-30); the rules and the
/// source data are in `docs/design/currency-symbols.json`:
///
/// * values that are not symbols were dropped, and so were 3-ASCII-letter values (`Lek`, `CHF`,
///   ...): they are indistinguishable from an ISO code, and the daemon upper-cases anything
///   code-shaped (`TripConfig.setCurrency`);
/// * duplicates were removed after NFKC normalisation, case folding and dropping a trailing dot
///   (`kr` / `kr.` / `Kr` are one entry; U+20A8 is compatibility-equivalent to `Rs`, so only `Rs`
///   stays);
/// * U+20B9 was added for INR (the source lists the obsolete U+20A8).
///
/// `codes` exist ONLY to map a currency already stored as an ISO code (a config from before the
/// symbol picker) to its symbol; they are never shown, and each code appears under exactly one
/// symbol. `$` is first: it is the default.
abstract final class CurrencySymbols {
  CurrencySymbols._();

  static const String defaultSymbol = '\$';

  static const List<({String symbol, List<String> codes})> all = [
    (symbol: '\$', codes: ['ARS', 'AUD', 'BBD', 'BES', 'BMD', 'BND', 'BSD', 'BZD', 'CAD', 'CLP', 'COP', 'CVE', 'DOP', 'FJD', 'GYD', 'HKD', 'JMD', 'KYD', 'LRD', 'MXN', 'NAD', 'NZD', 'SBD', 'SGD', 'SRD', 'TTD', 'USD', 'UYU', 'WST', 'XCD', 'ZWL']),
    (symbol: '€', codes: ['EUR']),
    (symbol: '£', codes: ['EGP', 'FKP', 'GBP', 'GIP', 'SDG', 'SHP', 'SYP']),
    (symbol: '¥', codes: ['CNY', 'JPY']),
    (symbol: '₹', codes: ['INR']),
    (symbol: '₱', codes: ['CUP', 'PHP']),
    (symbol: '₩', codes: ['KPW', 'KRW']),
    (symbol: '₽', codes: ['RUB']),
    (symbol: '฿', codes: ['THB']),
    (symbol: '₫', codes: ['VND']),
    (symbol: '₦', codes: ['NGN']),
    (symbol: '₪', codes: ['ILS']),
    (symbol: 'R\$', codes: ['BRL']),
    (symbol: '₴', codes: ['UAH']),
    (symbol: 'zł', codes: ['PLN']),
    (symbol: 'kr', codes: ['DKK', 'ISK', 'NOK', 'SEK']),
    (symbol: 'Kč', codes: ['CZK']),
    (symbol: 'Ft', codes: ['HUF']),
    (symbol: '؋', codes: ['AFN']),
    (symbol: 'د.ج', codes: ['DZD']),
    (symbol: 'Դ', codes: ['AMD']),
    (symbol: 'ƒ', codes: ['ANG', 'AWG']),
    (symbol: '₼', codes: ['AZN']),
    (symbol: 'ب.د', codes: ['BHD']),
    (symbol: '৳', codes: ['BDT']),
    (symbol: 'Nu', codes: ['BTN']),
    (symbol: 'Bs.', codes: ['BOB', 'VEF']),
    (symbol: 'КМ', codes: ['BAM']),
    (symbol: 'лв', codes: ['BGN', 'KGS', 'UZS']),
    (symbol: '₣', codes: ['BIF', 'CDF', 'CHF', 'DJF', 'GNF', 'RWF', 'XAF', 'XPF']),
    (symbol: '៛', codes: ['KHR']),
    (symbol: 'FC', codes: ['KMF']),
    (symbol: '₡', codes: ['CRC']),
    (symbol: 'Kn', codes: ['HRK']),
    (symbol: 'FCFA', codes: []),
    (symbol: 'Br', codes: ['ETB']),
    (symbol: 'D', codes: ['GMD']),
    (symbol: 'ლ', codes: ['GEL']),
    (symbol: '₵', codes: ['GHS']),
    (symbol: 'Q', codes: ['GTQ']),
    (symbol: 'G', codes: ['HTG']),
    (symbol: 'L', codes: ['HNL', 'LSL', 'MDL', 'RON', 'SZL']),
    (symbol: 'Rp', codes: ['IDR']),
    (symbol: '﷼', codes: ['IRR', 'OMR', 'YER']),
    (symbol: 'ع.د', codes: ['IQD']),
    (symbol: 'د.ا', codes: ['JOD']),
    (symbol: '〒', codes: ['KZT']),
    (symbol: 'Sh', codes: ['KES', 'SOS', 'TZS', 'UGX']),
    (symbol: 'د.ك', codes: ['KWD']),
    (symbol: '₭', codes: ['LAK']),
    (symbol: 'ل.ل', codes: ['LBP']),
    (symbol: 'R', codes: ['ZAR']),
    (symbol: 'ل.د', codes: ['LYD']),
    (symbol: 'MK', codes: ['MGA', 'MWK']),
    (symbol: 'RM', codes: ['MYR']),
    (symbol: 'ރ', codes: ['MVR']),
    (symbol: 'UM', codes: ['MRU']),
    (symbol: '₮', codes: ['MNT']),
    (symbol: 'د.م.', codes: ['AED', 'MAD']),
    (symbol: 'C\$', codes: ['NIO']),
    (symbol: 'B/.', codes: ['PAB']),
    (symbol: 'K', codes: ['PGK']),
    (symbol: '₲', codes: ['PYG']),
    (symbol: 'S/.', codes: ['PEN']),
    (symbol: 'ر.ق', codes: ['QAR']),
    (symbol: 'ден', codes: ['MKD']),
    (symbol: 'Db', codes: ['STN']),
    (symbol: 'ر.س', codes: ['SAR']),
    (symbol: 'Rs', codes: ['LKR', 'MUR', 'NPR', 'PKR', 'SCR']),
    (symbol: 'Le', codes: ['SLL']),
    (symbol: 'SS£', codes: ['SSP']),
    (symbol: 'NT\$', codes: ['TWD']),
    (symbol: 'ЅМ', codes: ['TJS']),
    (symbol: 'T\$', codes: ['TOP']),
    (symbol: 'د.ت', codes: ['TND']),
    (symbol: 'TL', codes: ['TRY']),
    (symbol: 'm', codes: ['TMT']),
    (symbol: 'Vt', codes: ['VUV']),
    (symbol: 'ZK', codes: ['ZMW']),
    (symbol: 'P', codes: ['BWP', 'BYN', 'MOP']),
  ];

  /// The symbols alone, in picker order.
  static List<String> get symbols => [for (final e in all) e.symbol];

  /// The symbol a stored currency stands for: the value itself when it is a listed symbol, else the
  /// symbol whose codes include it (`PHP`, `php` -> the peso sign), else null (unknown legacy text).
  static String? forStored(String stored) {
    final value = stored.trim();
    if (value.isEmpty) return null;
    for (final e in all) {
      if (e.symbol == value) return e.symbol;
    }
    final code = value.toUpperCase();
    for (final e in all) {
      if (e.codes.contains(code)) return e.symbol;
    }
    return null;
  }

  /// Whether [value] is shaped like an ISO 4217 code: exactly three ASCII letters. The same test as
  /// the daemon's `TripConfig.setCurrency` and the in-car `Currency.isIsoCodeShaped`.
  static bool isIsoCodeShaped(String value) {
    if (value.length != 3) return false;
    for (final unit in value.codeUnits) {
      final upper = unit >= 0x41 && unit <= 0x5A;
      final lower = unit >= 0x61 && unit <= 0x7A;
      if (!upper && !lower) return false;
    }
    return true;
  }

  /// [amount] to two decimals with its currency, as the companion writes money. An ISO-shaped
  /// [currency] stays after the amount (`128.47 PHP`, as it always was); anything else is a symbol
  /// and goes first (`₱ 128.47`), the same as the in-car app renders a bare symbol.
  static String money(double amount, String currency) {
    final text = amount.toStringAsFixed(2);
    final value = currency.trim();
    if (value.isEmpty) return text;
    return isIsoCodeShaped(value) ? '$text $value' : '$value $text';
  }
}
