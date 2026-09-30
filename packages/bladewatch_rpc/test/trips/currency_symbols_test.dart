import 'package:bladewatch_rpc/trips/currency_symbols.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-gzbo: the list both apps pick a currency SYMBOL from. Each test here can fail: change
/// the list (add a duplicate, an ISO-shaped value, the obsolete rupee sign) and one of them breaks.
void main() {
  final symbols = CurrencySymbols.symbols;

  String key(String s) => (s.toLowerCase().endsWith('.') ? s.substring(0, s.length - 1) : s).toLowerCase();

  group('the list', () {
    test('has the 80 curated symbols, dollar first (the default)', () {
      expect(symbols, hasLength(80));
      expect(symbols.first, r'$');
      expect(CurrencySymbols.defaultSymbol, symbols.first);
    });

    test('has no exact duplicates', () {
      expect(symbols.toSet(), hasLength(symbols.length));
    });

    test('has no duplicates ignoring case and a trailing dot (kr / kr. / Kr, P / p.)', () {
      final seen = <String, String>{};
      for (final s in symbols) {
        final other = seen[key(s)];
        expect(other, isNull, reason: '"$s" duplicates "$other"');
        seen[key(s)] = s;
      }
    });

    test('has no compatibility duplicates: U+20A8 is "Rs", so only "Rs" stays', () {
      expect(symbols, contains('Rs'));
      expect(symbols, isNot(contains('₨')));
      expect(symbols, contains('₹'), reason: 'the modern rupee sign is added for INR');
    });

    test('every symbol is safe to store: non-empty, trimmed, at most 8 characters, no angle brackets', () {
      for (final s in symbols) {
        expect(s, isNotEmpty);
        expect(s, s.trim(), reason: '"$s" has surrounding whitespace');
        expect(s.length, lessThanOrEqualTo(8), reason: '"$s" would not fit the daemon\'s VARCHAR(8)');
        expect(s.contains('<') || s.contains('>'), isFalse, reason: '"$s" would be rejected by the daemon');
      }
    });

    test('no symbol is shaped like an ISO code (the daemon would upper-case it)', () {
      for (final s in symbols) {
        expect(CurrencySymbols.isIsoCodeShaped(s), isFalse, reason: '"$s" is three ASCII letters');
      }
      for (final dropped in ['Lek', 'CHF', 'Nfk', 'din', 'MTn']) {
        expect(symbols, isNot(contains(dropped)));
      }
    });

    test('none of the source\'s junk values made it in', () {
      for (final junk in ['is', 'Franc', 'Mvdol', 'CFA Franc BEAC', 'Myanmar is K', '-']) {
        expect(symbols, isNot(contains(junk)));
      }
    });

    test('every ISO code is 3 upper-case ASCII letters and belongs to exactly one symbol', () {
      final owner = <String, String>{};
      for (final e in CurrencySymbols.all) {
        for (final code in e.codes) {
          expect(RegExp(r'^[A-Z]{3}$').hasMatch(code), isTrue, reason: code);
          expect(owner[code], isNull, reason: '$code is under both "${owner[code]}" and "${e.symbol}"');
          owner[code] = e.symbol;
        }
      }
      expect(owner.length, 149);
    });
  });

  group('forStored', () {
    test('a listed symbol is itself', () {
      for (final s in symbols) {
        expect(CurrencySymbols.forStored(s), s);
      }
    });

    test('a code maps to its symbol, whatever its case', () {
      expect(CurrencySymbols.forStored('PHP'), '₱');
      expect(CurrencySymbols.forStored('php'), '₱');
      expect(CurrencySymbols.forStored(' USD '), r'$');
      expect(CurrencySymbols.forStored('EUR'), '€');
      expect(CurrencySymbols.forStored('INR'), '₹');
      expect(CurrencySymbols.forStored('LKR'), 'Rs');
    });

    test('unknown legacy text and empty input map to nothing', () {
      expect(CurrencySymbols.forStored('Rs.'), isNull);
      expect(CurrencySymbols.forStored('XYZ'), isNull);
      expect(CurrencySymbols.forStored(''), isNull);
      expect(CurrencySymbols.forStored('   '), isNull);
    });
  });

  group('isIsoCodeShaped', () {
    test('three ASCII letters, either case', () {
      expect(CurrencySymbols.isIsoCodeShaped('USD'), isTrue);
      expect(CurrencySymbols.isIsoCodeShaped('php'), isTrue);
    });

    test('anything else is not', () {
      for (final v in ['', r'$', 'kr', 'USDX', 'US1', 'US ', '€', 'Rés']) {
        expect(CurrencySymbols.isIsoCodeShaped(v), isFalse, reason: '"$v"');
      }
    });
  });

  group('money', () {
    test('an ISO code stays after the amount, as it always did', () {
      expect(CurrencySymbols.money(128.4, 'PHP'), '128.40 PHP');
    });

    test('a symbol goes first', () {
      expect(CurrencySymbols.money(128.47, '₱'), '₱ 128.47');
      expect(CurrencySymbols.money(5, 'kr'), 'kr 5.00');
    });

    test('no currency: just the amount', () {
      expect(CurrencySymbols.money(1.5, ''), '1.50');
      expect(CurrencySymbols.money(1.5, '  '), '1.50');
    });
  });
}
